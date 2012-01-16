package Pfamparser;

use strict;
use warnings;
use Carp;
use Data::Dumper;

sub new {
    my ($class, $file) = @_;

    my $self = {
        hit => 0,
    };

    bless $self, $class;
    $self->parse($file);
    return $self;
}

sub parse {
    my ($self, $file) = @_;

    open PFAM, $file or croak "Could not open pfam file: '$file'\n";
    my $cont = join("",<PFAM>);
    close PFAM;
    return if $cont=~/No hits detected that satisfy reporting thresholds/go;
    $self->{hit}=1;
    #split the hmm result file into the different models
    my @models = split(">> ",$cont);
    my $header=shift @models;

    #split each model into its domains
    foreach my $model (@models) {
        croak "Failed to parse Pfam: no model identifier in: $model" unless $model=~/^(.*?)\s+?/go;
        my $modelid=$1;
        $self->{$modelid}={};
        #print join("\n",keys %{$self->{model}})."\n\n";
        my @domains=split("== ",$model);
        my $domainheader=shift @domains;
        foreach my $domain (@domains) {
            croak "Failed to parse Pfam: no domain identifier in: $domain" unless $domain=~/^(domain\s+?\d+?)\s+?/go;
            my $domainid=$1;
            #print $modelid." -> ".$domainid."\n";
            my @alignment=split(/\n/,$domain);
            my $i=0;
            croak "Failed to parse Pfam: no E-value in: $alignment[0]" unless $alignment[0]=~/E-value:\s+(.*)$/o;
            my $evalue=$1;
            while ($alignment[$i]!~/$modelid/){
                chomp $alignment[$i];
                $i++;
                croak "Failed to parse Pfam: alignment is not of expected format:\n$modelid\n$domain" unless $alignment[$i];
            }
            #print "$evalue\n";
            my $fitline=$alignment[$i+1];
            $fitline=~s/^\s+//o;
            my @fit=split(//o,$fitline);
            $alignment[$i+2]=~s/^\s+|\s+$//o;
            my ($query,$from,$seq,$to)=split(/\s+/o,$alignment[$i+2]);
            my @sequence=split(//o,$seq);
            #print "from $from to $to\n";
            $alignment[$i+3]=~s/^\s+|\s+$//o;
            my ($postprob)=split(/\s+/o,$alignment[$i+3]);
            $postprob=~s/\s+$//o;
            my @probability=split(//o,$postprob);
            while (@fit < @probability){unshift @fit," "}
            #print join(",",@probability)."\n";
            croak "Failed to parse Pfam: alignment length not consistent:\n$fitline\n$seq\n$postprob\n" unless (scalar @probability == length($seq));
            $self->{$modelid}{$domainid}={
                            evalue=>$evalue,
                            from=>$from,
                            to=>$to,
                            cons=>\@fit,
                            seq=>\@sequence,
                            prob=>\@probability};
        }

    }
        

}
sub model{
    my ($self,$id) = @_;
    return $self->{$id};
}
sub domain{
    my ($self,$model,$domain) = @_;
    return $self->{$model}{$domain};
}
sub at_pos{
    my ($self,$pos)=@_;
    my $exp=0;
    my ($m,$d);
    return unless $self->{hit};
    foreach my $model (keys %$self){
        next if $model eq "hit";
        foreach my $domain (keys %{$self->model($model)}){
           if ($self->{$model}{$domain}{from}<=$pos && $pos<=$self->{$model}{$domain}{to}){
               next unless ($self->{$model}->{$domain}->{evalue}=~/\d+\.\d+e\-(\d+)/o);
               if ($1 > $exp){
                $m=$model;
                $d=$domain;
                $exp=$1;
               } 
           }
        }
    }
    return ($m,$d);
}
1;
