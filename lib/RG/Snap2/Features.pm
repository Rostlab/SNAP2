#!/usr/bin/perl
package RG::Snap2::Features;
use strict;
use warnings;
use Carp qw(cluck :DEFAULT);
use Cwd 'abs_path';
use Data::Dumper;
use DB_File;
use Getopt::Long;
use IO::File;
use List::Util qw (min max);
use RG::Snap2::Pfamparser;
use RG::Snap2::Profparser;
use RG::Snap2::Pssmparser;
use RG::Snap2::Psicparser;
use RG::Snap2::Mdparser;
use RG::Snap2::Disisparser;
use RG::Snap2::Isisparser;
use RG::Snap2::Profbvalparser;
use RG::Snap2::Snapparser;

my @amino_acids = qw(A R N D C Q E G H I L K M F P S T W Y V X);
my %index=(
    A => 0,
    R => 1,
    N => 2,
    D => 3,
    C => 4,
    Q => 5,
    E => 6,
    G => 7,
    H => 8,
    I => 9,
    L => 10, 
    K => 11, 
    M => 12, 
    F => 13, 
    P => 14, 
    S => 15, 
    T => 16, 
    W => 17, 
    Y => 18, 
    V => 19,
    X => 20,
);
#Normalized SIMK990101 Distance-dependent statistical potential (contacts within 0-5 Angstrooms) Simons, K.T., Ruczinski, I., Kooperberg, C., Fox, B.A., Bystroff, C. and Baker,D. Proteins 34, 82-95 (1999)
my @contact_potentials=(['0.656','0.857','0.813','0.842','0.802','0.815','0.815','0.704','0.839','0.622','0.651','0.868','0.724','0.742','0.724','0.752','0.692','0.789','0.761','0.603','0'],
['0.857','0.802','0.603','0.400','0.905','0.610','0.399','0.677','0.667','0.843','0.788','0.929','0.762','0.723','0.682','0.700','0.689','0.579','0.653','0.842','0'],
['0.813','0.603','0.467','0.544','0.839','0.607','0.639','0.563','0.708','0.862','0.850','0.682','0.722','0.816','0.630','0.596','0.597','0.823','0.760','0.898','0'],
['0.842','0.400','0.544','0.737','0.920','0.710','0.807','0.621','0.522','0.888','0.861','0.353','0.838','0.923','0.625','0.511','0.565','0.910','0.894','0.887','0'],
['0.802','0.905','0.839','0.920','0.000','0.810','0.973','0.791','0.807','0.760','0.753','1.000','0.728','0.748','0.692','0.755','0.819','0.747','0.775','0.749','0'],
['0.815','0.610','0.607','0.710','0.810','0.615','0.687','0.703','0.698','0.792','0.740','0.612','0.696','0.767','0.644','0.686','0.619','0.692','0.695','0.744','0'],
['0.815','0.399','0.639','0.807','0.973','0.687','0.913','0.769','0.668','0.797','0.789','0.344','0.770','0.810','0.654','0.570','0.595','0.774','0.785','0.800','0'],
['0.704','0.677','0.563','0.621','0.791','0.703','0.769','0.519','0.744','0.855','0.831','0.712','0.768','0.794','0.637','0.603','0.613','0.807','0.752','0.802','0'],
['0.839','0.667','0.708','0.522','0.807','0.698','0.668','0.744','0.618','0.752','0.755','0.712','0.716','0.726','0.600','0.665','0.609','0.642','0.721','0.773','0'],
['0.622','0.843','0.862','0.888','0.760','0.792','0.797','0.855','0.752','0.585','0.660','0.796','0.675','0.634','0.932','0.834','0.824','0.647','0.643','0.632','0'],
['0.651','0.788','0.850','0.861','0.753','0.740','0.789','0.831','0.755','0.660','0.631','0.794','0.659','0.620','0.850','0.818','0.833','0.643','0.628','0.668','0'],
['0.868','0.929','0.682','0.353','1.000','0.612','0.344','0.712','0.712','0.796','0.794','0.934','0.771','0.729','0.726','0.721','0.658','0.613','0.643','0.804','0'],
['0.724','0.762','0.722','0.838','0.728','0.696','0.770','0.768','0.716','0.675','0.659','0.771','0.655','0.618','0.755','0.788','0.829','0.670','0.619','0.713','0'],
['0.742','0.723','0.816','0.923','0.748','0.767','0.810','0.794','0.726','0.634','0.620','0.729','0.618','0.612','0.669','0.821','0.859','0.656','0.704','0.678','0'],
['0.724','0.682','0.630','0.625','0.692','0.644','0.654','0.637','0.600','0.932','0.850','0.726','0.755','0.669','0.694','0.667','0.721','0.489','0.545','0.868','0'],
['0.752','0.700','0.596','0.511','0.755','0.686','0.570','0.603','0.665','0.834','0.818','0.721','0.788','0.821','0.667','0.627','0.582','0.855','0.835','0.771','0'],
['0.692','0.689','0.597','0.565','0.819','0.619','0.595','0.613','0.609','0.824','0.833','0.658','0.829','0.859','0.721','0.582','0.633','0.843','0.855','0.769','0'],
['0.789','0.579','0.823','0.910','0.747','0.692','0.774','0.807','0.642','0.647','0.643','0.613','0.670','0.656','0.489','0.855','0.843','0.732','0.697','0.758','0'],
['0.761','0.653','0.760','0.894','0.775','0.695','0.785','0.752','0.721','0.643','0.628','0.643','0.619','0.704','0.545','0.835','0.855','0.697','0.703','0.718','0'],
['0.603','0.842','0.898','0.887','0.749','0.744','0.800','0.802','0.773','0.632','0.668','0.804','0.713','0.678','0.868','0.771','0.769','0.758','0.718','0.592','0'],
['0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0']);

my %abs_biochem_properties = (
		A => {mass=>71,       vol=>88.6,     hyd=>1.8,      cbeta=>0,  hbreaker=>0,       charge=>0},
		R => {mass=>156,      vol=>173.4,    hyd=>-4.5,     cbeta=>0,  hbreaker=>0,       charge=>1},
        N => {mass=>114,      vol=>114.1,    hyd=>-3.5,     cbeta=>0,  hbreaker=>0,       charge=>0},
        D => {mass=>115,      vol=>111.1,    hyd=>-3.5,     cbeta=>0,  hbreaker=>0,       charge=>-1},
        C => {mass=>103,      vol=>108.5,    hyd=>2.5,      cbeta=>0,  hbreaker=>0,       charge=>0},
        Q => {mass=>128,      vol=>143.8,    hyd=>-3.5,     cbeta=>0,  hbreaker=>0,       charge=>0},
        E => {mass=>129,      vol=>138.4,    hyd=>-3.5,     cbeta=>0,  hbreaker=>0,       charge=>-1},
        G => {mass=>57,       vol=>60.1,     hyd=>-0.4,     cbeta=>0,  hbreaker=>0,       charge=>0},
        H => {mass=>137,      vol=>153.2,    hyd=>-3.2,     cbeta=>0,  hbreaker=>0,       charge=>1},
        I => {mass=>113,      vol=>166.7,    hyd=>4.5,      cbeta=>1,  hbreaker=>0,       charge=>0},
        L => {mass=>113,      vol=>166.7,    hyd=>3.8,      cbeta=>0,  hbreaker=>0,       charge=>0},
        K => {mass=>128,      vol=>168.6,    hyd=>-3.9,     cbeta=>0,  hbreaker=>0,       charge=>1},
        M => {mass=>131,      vol=>162.9,    hyd=>1.9,      cbeta=>0,  hbreaker=>0,       charge=>0},
        F => {mass=>147,      vol=>189.9,    hyd=>2.8,      cbeta=>0,  hbreaker=>0,       charge=>0},
        P => {mass=>97,       vol=>112.7,    hyd=>-1.6,     cbeta=>0,  hbreaker=>1,       charge=>0},
        S => {mass=>87,       vol=>89.0,     hyd=>-0.8,     cbeta=>0,  hbreaker=>0,       charge=>0},
        T => {mass=>101,      vol=>116.1,    hyd=>-0.7,     cbeta=>1,  hbreaker=>0,       charge=>0},
        W => {mass=>186,      vol=>227.8,    hyd=>-0.9,     cbeta=>0,  hbreaker=>0,       charge=>0},
        Y => {mass=>163,      vol=>193.6,    hyd=>-1.3,     cbeta=>0,  hbreaker=>0,       charge=>0},
        V => {mass=>99,       vol=>140.0,    hyd=>4.2,      cbeta=>1,  hbreaker=>0,       charge=>0},
        X => {mass=>0,        vol=>0.0,      hyd=>0,        cbeta=>0,  hbreaker=>0,       charge=>0},);
                                        
#linear normalization of bio-chemical amino acid properties
    #VINM940103 Normalized flexibility parameters (B-values) for each residue surrounded by one rigid neighbour (Vihinen et al., 1994)
    #BLAM930101 Alpha helix propensity of position 44 in T4 lysozyme (Blaber et al., 1993)
    #SNEP660101 Relations between chemical structure and biological activity in peptides: Principal component I (Sneath, 1966)
    #RICJ880113 Relative preference value at C2 (Richardson-Richardson, 1988)
    #DAYM780201 A model of evolutionary change in proteins: Relative mutability (Dayhoff et al., 1978b)
    #QIAN880123 Weights for beta-sheet at the window position of 3 (Qian-Sejnowski, 1988)
    #KLEP840101 Prediction of protein function from sequence properties: Discriminant analysis of a data base: Net charge (Klein et al., 1984)
my %normalized_biochem_properties =	( 
		A => {mass=>0.109,    vol=>0.170,    hyd=>0.700,    cbeta=>0,      hbreaker=>0,   KLEP840101=>0.500,    QIAN880123=>0.133,    DAYM780201=>0.707,    RICJ880113=>0.632,    VINM940103=>0.508,    BLAM930101=>1.000,  SNEP660101=>0.653,  charge=>0.5},
        R => {mass=>0.767,    vol=>0.676,    hyd=>0.000,    cbeta=>0,      hbreaker=>0,   KLEP840101=>1.000,    QIAN880123=>0.429,    DAYM780201=>0.405,    RICJ880113=>1.000,    VINM940103=>0.780,    BLAM930101=>0.945,  SNEP660101=>0.421,  charge=>1},
        N => {mass=>0.442,    vol=>0.322,    hyd=>0.111,    cbeta=>0,      hbreaker=>0,   KLEP840101=>0.500,    QIAN880123=>0.600,    DAYM780201=>1.000,    RICJ880113=>0.368,    VINM940103=>0.746,    BLAM930101=>0.835,  SNEP660101=>0.736,  charge=>0.5},
     	D => {mass=>0.450,    vol=>0.304,    hyd=>0.111,    cbeta=>0,      hbreaker=>0,   KLEP840101=>0.000,    QIAN880123=>0.362,    DAYM780201=>0.759,    RICJ880113=>0.263,    VINM940103=>0.746,    BLAM930101=>0.844,  SNEP660101=>0.091,  charge=>0},
        C => {mass=>0.357,    vol=>0.289,    hyd=>0.778,    cbeta=>0,      hbreaker=>0,   KLEP840101=>0.500,    QIAN880123=>0.676,    DAYM780201=>0.017,    RICJ880113=>0.526,    VINM940103=>0.042,    BLAM930101=>0.844,  SNEP660101=>0.496,  charge=>0.5},
		Q => {mass=>0.550,    vol=>0.499,    hyd=>0.111,    cbeta=>0,      hbreaker=>0,   KLEP840101=>0.500,    QIAN880123=>0.000,    DAYM780201=>0.647,    RICJ880113=>0.737,    VINM940103=>0.907,    BLAM930101=>0.954,  SNEP660101=>0.826,  charge=>0.5},
		E => {mass=>0.558,    vol=>0.467,    hyd=>0.111,    cbeta=>0,      hbreaker=>0,   KLEP840101=>0.000,    QIAN880123=>0.286,    DAYM780201=>0.724,    RICJ880113=>0.789,    VINM940103=>1.000,    BLAM930101=>0.876,  SNEP660101=>0.223,  charge=>0},
        G => {mass=>0.000,    vol=>0.000,    hyd=>0.456,    cbeta=>0,      hbreaker=>0,   KLEP840101=>0.500,    QIAN880123=>0.629,    DAYM780201=>0.267,    RICJ880113=>0.000,    VINM940103=>0.712,    BLAM930101=>0.723,  SNEP660101=>0.000,  charge=>0.5},
        H => {mass=>0.620,    vol=>0.555,    hyd=>0.144,    cbeta=>0,      hbreaker=>0,   KLEP840101=>0.500,    QIAN880123=>0.638,    DAYM780201=>0.414,    RICJ880113=>0.842,    VINM940103=>0.280,    BLAM930101=>0.887,  SNEP660101=>0.372,  charge=>1},
        I => {mass=>0.434,    vol=>0.636,    hyd=>1.000,    cbeta=>1,      hbreaker=>0,   KLEP840101=>0.500,    QIAN880123=>0.514,    DAYM780201=>0.672,    RICJ880113=>0.105,    VINM940103=>0.364,    BLAM930101=>0.965,  SNEP660101=>0.934,  charge=>0.5},
        L => {mass=>0.434,    vol=>0.636,    hyd=>0.922,    cbeta=>0,      hbreaker=>0,   KLEP840101=>0.500,    QIAN880123=>0.438,    DAYM780201=>0.190,    RICJ880113=>0.316,    VINM940103=>0.407,    BLAM930101=>0.988,  SNEP660101=>1.000,  charge=>0.5},
        K => {mass=>0.550,    vol=>0.647,    hyd=>0.067,    cbeta=>0,      hbreaker=>0,   KLEP840101=>1.000,    QIAN880123=>0.238,    DAYM780201=>0.328,    RICJ880113=>0.895,    VINM940103=>0.805,    BLAM930101=>0.934,  SNEP660101=>0.562,  charge=>1},
        M => {mass=>0.574,    vol=>0.613,    hyd=>0.711,    cbeta=>0,      hbreaker=>0,   KLEP840101=>0.500,    QIAN880123=>0.352,    DAYM780201=>0.655,    RICJ880113=>0.579,    VINM940103=>0.246,    BLAM930101=>0.971,  SNEP660101=>0.769,  charge=>0.5},
        F => {mass=>0.698,    vol=>0.774,    hyd=>0.811,    cbeta=>0,      hbreaker=>0,   KLEP840101=>0.500,    QIAN880123=>0.429,    DAYM780201=>0.198,    RICJ880113=>0.053,    VINM940103=>0.000,    BLAM930101=>0.893,  SNEP660101=>0.612,  charge=>0.5},
        P => {mass=>0.310,    vol=>0.314,    hyd=>0.322,    cbeta=>0,      hbreaker=>1,   KLEP840101=>0.500,    QIAN880123=>0.095,    DAYM780201=>0.328,    RICJ880113=>0.000,    VINM940103=>0.983,    BLAM930101=>0.000,  SNEP660101=>0.041,  charge=>0.5},
        S => {mass=>0.233,    vol=>0.172,    hyd=>0.411,    cbeta=>0,      hbreaker=>0,   KLEP840101=>0.500,    QIAN880123=>0.810,    DAYM780201=>0.879,    RICJ880113=>0.737,    VINM940103=>0.771,    BLAM930101=>0.876,  SNEP660101=>0.628,  charge=>0.5},
        T => {mass=>0.341,    vol=>0.334,    hyd=>0.422,    cbeta=>1,      hbreaker=>0,   KLEP840101=>0.500,    QIAN880123=>1.000,    DAYM780201=>0.681,    RICJ880113=>0.368,    VINM940103=>0.542,    BLAM930101=>0.879,  SNEP660101=>0.438,  charge=>0.5},
        W => {mass=>1.000,    vol=>1.000,    hyd=>0.400,    cbeta=>0,      hbreaker=>0,   KLEP840101=>0.500,    QIAN880123=>0.343,    DAYM780201=>0.000,    RICJ880113=>0.105,    VINM940103=>0.034,    BLAM930101=>0.890,  SNEP660101=>0.190,  charge=>0.5},
        Y => {mass=>0.822,    vol=>0.796,    hyd=>0.356,    cbeta=>0,      hbreaker=>0,   KLEP840101=>0.500,    QIAN880123=>0.448,    DAYM780201=>0.198,    RICJ880113=>0.053,    VINM940103=>0.398,    BLAM930101=>0.931,  SNEP660101=>0.273,  charge=>0.5},
        V => {mass=>0.326,    vol=>0.476,    hyd=>0.967,    cbeta=>1,      hbreaker=>0,   KLEP840101=>0.500,    QIAN880123=>0.610,    DAYM780201=>0.483,    RICJ880113=>0.263,    VINM940103=>0.288,    BLAM930101=>0.905,  SNEP660101=>0.785,  charge=>0.5}, 
        X => {mass=>0.000,    vol=>0.000,    hyd=>0.000,    cbeta=>0,  	   hbreaker=>0,   KLEP840101=>0.000,    QIAN880123=>0.000,    DAYM780201=>0.000,    RICJ880113=>0.000,    VINM940103=>0.000,    BLAM930101=>0.000,  SNEP660101=>0.000,  charge=>0},);

#returns array with the normalized property values for the given amino acid
#requires amino acid (one of the 20 aa from above)
sub get_normalized_properties {
	my $aa=uc (shift);
	my @result;
	confess "\nError: unknown amino acid: $aa\n" if (!(exists $normalized_biochem_properties{$aa}));
	foreach my $property (qw(mass vol hyd cbeta hbreaker charge)) {
		push (@result,$normalized_biochem_properties{$aa}{$property});
	}
	return @result;
}

#returns the normalized value of the given property for the given amino acid
#requires amino acid (one of the 20 aa from above)
#requires property ( mass|vol|hyd|cbeta|hbreaker|charge )
sub get_normalized_property {
	my ($aa,$property) = @_;
	$aa=uc $aa;
	confess "\nError: unknown amino acid: $aa\n" if (!(exists $normalized_biochem_properties{$aa}));
	confess "\nError: unknown property: $property\nPlease only use:\n" . join "\n",(keys %{$normalized_biochem_properties{$aa}}) if (!(exists $normalized_biochem_properties{$aa}{$property}));
	return $normalized_biochem_properties{$aa}{$property};
}

sub contact_potentials{
    my ($aa,$debug)=@_;
    $aa=uc $aa;
    confess "\nError: unknown amino acid: $aa\n" unless defined $index{$aa};
    my @potentials=@{$contact_potentials[$index{$aa}]};
    cluck( Dumper (\@potentials)) if $debug;
    return @potentials;
}

sub pairwise_potential{
    my ($aa1,$aa2,$debug)=@_;
    $aa1=uc $aa1;
    $aa2=uc $aa2;
    confess "\nError: unknown amino acid: $aa1\n" unless defined $index{$aa1};
    confess "\nError: unknown amino acid: $aa2\n" unless defined $index{$aa2};
    my $pairwise_potential=$contact_potentials[$index{$aa1}][$index{$aa2}];
    cluck ( Dumper (\$pairwise_potential) ) if $debug;
    return $pairwise_potential;
}

sub potentials{
    my ($length,$pos,$seqarray,$win,$aa,$debug)=@_;
    confess ("Window size needs to be uneven (window: '$win')") if $win % 2 == 0;
    confess ("Window size needs to be > 0 (window: '$win')") if $win < 1;
    confess ("Position '$pos' is out of bounds: [1,$length]") if ($pos > $length || $pos < 1);
    confess ("Position '$pos' is out of bounds (max is: ".scalar(@$seqarray).")") if ($pos>scalar(@$seqarray));
    my $opos=$pos-1;
    $pos-=($win+1)/2;
    my @return;
    for (my $i = 0; $i < $win; $i++) {
       if ($pos<0 || $pos >= $length){
        push (@return,0);
       } 
       else {
           #skip the requested position itself -> only do the surrounding residues
        push @return,pairwise_potential($$seqarray[$pos],$aa) unless $pos==$opos;
       }
    $pos++;
    }
    cluck( Dumper (@return) ) if $debug;
    return @return;  
}
sub potentialDiff{
    my ($length,$pos,$seqarray,$win,$wt,$mut,$debug)=@_;
    my @return;
    my @wtpot=potentials($length,$pos,$seqarray,$win,$wt,$debug);
    my @mutpot=potentials($length,$pos,$seqarray,$win,$mut,$debug);
    foreach my $i (0..@wtpot-1) {
        my $diff=$wtpot[$i]-$mutpot[$i];
        my $sign=0;
        $sign=1 if $diff<0;
        push @return,abs($diff),$sign;
    }
    cluck( Dumper (\@return) ) if $debug;
    return @return;
}
sub potentialProfileDiff{
    my ($wt,$mut,$debug)=@_;
    my @wt_potentials=contact_potentials($wt,$debug);
    my @mut_potentials=contact_potentials($mut,$debug);
    my @return;
    foreach my $i (0..@wt_potentials-1) {
        my $diff=$wt_potentials[$i]-$mut_potentials[$i];
        my $sign=0;
        $sign = 1 if $diff<0;
        push @return,abs($diff),$sign;
    }
    cluck ( Dumper (\@return)) if $debug;
    return @return;
}

sub indices{
    my ($length,$pos,$seqarray,$win,$index,$debug)=@_;
    confess ("Window size needs to be uneven (window: '$win')") if $win % 2 == 0;
    confess ("Window size needs to be > 0 (window: '$win')") if $win < 1;
    confess ("Position '$pos' is out of bounds: [1,$length]") if ($pos > $length || $pos < 1);
    confess ("Position '$pos' is out of bounds (max is: ".scalar(@$seqarray).")") if ($pos>scalar(@$seqarray));
    $pos-=($win+1)/2;
    my @return;
    for (my $i = 0; $i < $win; $i++) {
       if ($pos<0 || $pos >= $length){
        push (@return,0);
       } 
       else {
        push @return,get_normalized_property($$seqarray[$pos],$index);
       }
    $pos++;
    }
    cluck( Dumper (@return) ) if $debug;
    return @return;  
}
sub indexDiff{
    my ($wt,$mut,$index,$debug)=@_;
    my $diff=get_normalized_property($wt,$index) - get_normalized_property($mut,$index);
    my $sign=0;
    $sign=1 if $diff<0;
    cluck (Dumper (abs($diff),$sign)) if $debug;
    return abs($diff),$sign;
}
#returns an array containing normalized difference of properties of wt and mutant: 10 values (difference and sign for every property)
#requires mutant in format: A38D
sub normalized_biochem_diff {
	my ($mut,$debug)=@_;
	my @mutation=wt_pos_mut($mut,$debug);
	my $seq_aa=$mutation[0];
	my $mut_aa=$mutation[2];
	confess "\nError: unknown amino acid in mutation: $mut\n" if (!(exists $normalized_biochem_properties{$seq_aa}) or !(exists $normalized_biochem_properties{$mut_aa}));
	my @data;
	foreach my $property (qw(mass vol hyd cbeta hbreaker charge)) {
		my $diff= $normalized_biochem_properties{$seq_aa}{$property} - $normalized_biochem_properties{$mut_aa}{$property};
		my $delta=abs($diff);
		my $sign=0;
		if ($diff<0){$sign=1 };
		push(@data,(sprintf("%.3f",$delta),"$sign"));
	}
	if ($debug) {cluck ("Mutation found to be: $mut\nResulting Data: ".Dumper(\@data)."\n");}
	return @data;
		
}

#returns an array containing difference of properties of wt and mutant: 12 values (difference and sign for every property)
#requires mutant in format: A38D
sub abs_biochem_diff {
	my ($mut,$debug)=@_;
	my @mutation=wt_pos_mut($mut,$debug);
	my $seq_aa=$mutation[0];
	my $mut_aa=$mutation[2];
	confess "\nError: unknown amino acid in mutation: $mut\n" if (!(exists $abs_biochem_properties{$seq_aa}) or !(exists $abs_biochem_properties{$mut_aa}));
	my @data;
	foreach my $property (qw(mass vol hyd cbeta hbreaker charge)) {
		my $diff= $abs_biochem_properties{$seq_aa}{$property} - $abs_biochem_properties{$mut_aa}{$property};
		my $delta=abs($diff);
		my $sign=0;
		if ($diff<0){$sign=1 };
		push(@data,(sprintf("%.3f",$delta),"$sign"));
	}
	if ($debug) {cluck ("Mutation found to be: $mut\nResulting Data: ".Dumper(\@data)."\n");}
	return @data;
}

#returns @result: array of with difference and sign for transition frequencies
#requires $mut: mutant in format: A38D
#requires $wt_seq: wildtype sequence as string
#requires $path: path to TransitionFrequency file
#This will generate the Transition frequency triplets for wildtype and mutant,
#and calculate the differences in frequency for each triplet pair.
#it will return 6 values: difference and sign for each triplet pair.
sub transition_frequency {
	my ($mut,$wt_seq,$path,$debug)=@_;
	my ($wt_aa,$pos,$mut_aa)=wt_pos_mut($mut,$debug);
	chomp($wt_seq);
	my @wt_seq=split(//o,$wt_seq);
	my @mut_seq=@wt_seq;
	#print (join("\n",@wt_seq));
	$pos--; #to account for arrays start at 0;
	$mut_seq[$pos]=$mut_aa;
	my @wt_triplets;
	my @mut_triplets;
	my @result;

	for (my $i=0; $i<3; $i++) { # for 3 triples
		my @tmp_wt_triplet=qw(X X X);
		my @tmp_mut_triplet=qw(X X X);
		if (($pos-2+$i)>=0 and ($pos-2+$i)<scalar(@wt_seq)) {$tmp_wt_triplet[0]=$wt_seq[$pos-2+$i]; $tmp_mut_triplet[0]=$mut_seq[$pos-2+$i];}
		if (($pos-1+$i)>=0 and ($pos-1+$i)<scalar(@wt_seq))	{$tmp_wt_triplet[1]=$wt_seq[$pos-1+$i]; $tmp_mut_triplet[1]=$mut_seq[$pos-1+$i];}
		if (($pos-0+$i)>=0 and ($pos-0+$i)<scalar(@wt_seq)) {$tmp_wt_triplet[2]=$wt_seq[$pos-0+$i]; $tmp_mut_triplet[2]=$mut_seq[$pos-0+$i];}
		$wt_triplets[$i]=join("",@tmp_wt_triplet);
		$mut_triplets[$i]=join("",@tmp_mut_triplet);
		chomp(my $wt_freq=`grep $wt_triplets[$i] $path`);
		chomp(my $mut_freq=`grep $mut_triplets[$i] $path`);
        #print "\n $wt_freq - $mut_freq\n";
        $wt_freq=~s/.*\s+//o;
        $mut_freq=~s/.*\s+//o;
        #print "\n $wt_freq - $mut_freq\n";
		my $dif = ($wt_freq * 1 - $mut_freq); # the ( * 1) makes sure we work on numeric values not on string values 
		if ($dif < 0){
			push (@result,"1");
		}
		else{
			push (@result,"0");
		}
		push (@result,sprintf("%.3f",abs($dif)));
	}
	cluck "Wildtype Triplets: ".Dumper(\@wt_triplets) if $debug;
	cluck "Mutant Triplets: ".Dumper(\@mut_triplets) if $debug;	
	cluck "Resulting Features: ".Dumper(\@result) if $debug;	
	return @result;
}
#returns @result: an array with the 21-node representation of a residue
#input $aa: an amino acid 
sub residue_representation {
	my ($aa,$debug) = @_;
	my @result;
	foreach my $current_aa (@amino_acids) {
		if ($aa eq $current_aa) {
			push(@result,"1");
		}
		else {
			push(@result,"0");
		}
	}
	cluck Dumper(\@result) if $debug;
	return @result;
}
sub sequenceprofile {
    my ($seqarray,$length,$pos,$win,$debug)=@_;
    confess ("Window size needs to be uneven (window: '$win')") if $win % 2 == 0;
    confess ("Window size needs to be > 0 (window: '$win')") if $win < 1;
    confess ("Position '$pos' is out of bounds: [1,$length]") if ($pos > $length || $pos < 1);
    $pos-=($win+1)/2;
    my @return;
    for (my $i = 0; $i < $win; $i++) {
       if ($pos<0 || $pos >= $length){
        push (@return,qw(0) x 21);
       } 
       else {
        push @return,residue_representation($$seqarray[$pos]);
       }
    $pos++;
    }
    cluck( Dumper (@return) ) if $debug;
    return @return;
}
#returns @features: array with 7 entrys representing the annotation that was found
#requires $swiss_dat_file: path to uniprot_sprot.dat
#requires $db_swiss: path to dbSwiss index
#requires $blastfile: path to swissprot blast result file
#requires $mutation: mutation in format A38D
#requires $phat_file: path to phat matrix file
#This method extracts the best hit from a blast output file,
#looks up the swissprot annotation for that protein (if available)
#and returns a binary representation of the keywords it found
#$features[i] will be set to 1 if the corresponding keywords were found for the mutant position
#$features[6] will be set to 1 if a swissprot entry was found
#if the 'TRANSMEM' keyword is found the transition frequency for the substitution will be looked up in the phat matrix
sub swiss{
    my ($wt,$pos,$mut,$swiss,$phat_file,$debug)=@_;
    my @features=qw(0 0 0 0 0 0 0);
    my %swiss_keywords=%{$$swiss->{keywords}};
    $features[6]=$swiss_keywords{0}; #$features[6] equals 1 if annotations were found, otherwise 0
    unless (defined $swiss_keywords{$pos}){
        cluck ("\nNo keywords found for position $pos\n") if ($debug);
        return @features;
    }
	my $keywords=$swiss_keywords{$pos};
	if ($keywords =~ /BINDING|ACT_SITE|SITE|LIPID|METAL|CARBOHYD|DNA_BIND|ZN_FING|CA_BIND|NP_BIND/){
		$features[0]=1;
	}	
	if ($keywords =~ /DISULFID|SE_CYS/){
		$features[1]=1;
	}
	if ($keywords =~ /MOD_RES|PROPEP|SIGNAL/){
		$features[2]=1;
	}
	if ($keywords =~ /TRANSMEM/){
		my %phat_matrix=getNormalizedPhatMatrix($phat_file,$debug);
		$features[3]=1;
		$features[4]=$phat_matrix{$wt}{$mut};
	}
	if ($keywords =~ /MUTAGEN|CONFLICT|VARIANT/){
		$features[5]=1;
	}
	cluck ("Found following keywords for position $pos: $keywords\n") if ($debug);
	cluck (Dumper(\@features)) if ($debug);
	return @features;
}

#returns $feature: distance to either protein end normalized between 0-1
#requires $mutant: mutant in format A38D
#requires $sequence: sequence as string
#this method translates the distance of the mutation to either proteinend into a numeric feature between 0 and 1
#it returns 1 if the mutation is at the very beginning or end of the protein
#for position 2-19 at beginning or end the value will be scaled in 0.05 steps
#it returns 0 if the mutation is more than 20 residues away from either end
sub mutantAtEnd {
	my ($mutant,$sequence,$debug) = @_;
	my ($wt,$pos,$mut)=wt_pos_mut($mutant,$debug);
	my $feature=0;
	if ($pos<=20){
		$feature=(20-$pos)/20;
	}
	elsif ($pos >=(length ($sequence) -20)){
		$feature=(20 - (length ($sequence) - $pos) )/20;
	}
	return $feature;
}
sub sec_raw{
    my ($length,$pos,$prof,$win,$debug)=@_;
    confess ("Window size needs to be uneven (window: '$win')") if $win % 2 == 0;
    confess ("Window size needs to be > 0 (window: '$win')") if $win < 1;
    confess ("Position '$pos' is out of bounds: [1,$length]") if ($pos > $length || $pos < 1);
    confess ("Prof prediction file ('".$$prof->getLength()."') is not of same length as sequence ('$length')") if $length != $$prof->getLength();
    $pos-=($win+1)/2;
    my @return;
    for (my $i = 0; $i < $win; $i++) {
       if ($pos<0 || $pos >= $length){
        push (@return,0,0,0,0);
       } 
       else {
        push @return,$$prof->getData($pos+1,'pH')/100,$$prof->getData($pos+1,'pE')/100,$$prof->getData($pos+1,'pL')/100,$$prof->getData($pos+1,'RI_S')/9,
       }

    $pos++;
    }
    cluck( Dumper (@return) ) if $debug;
    return @return;
}
sub sec_bin{
    my ($length,$pos,$prof,$win,$debug)=@_;
    confess ("Window size needs to be uneven (window: '$win')") if $win % 2 == 0;
    confess ("Window size needs to be > 0 (window: '$win')") if $win < 1;
    confess ("Position '$pos' is out of bounds: [1,$length]") if ($pos > $length || $pos < 1);
    confess ("Prof prediction file ('".$$prof->getLength()."') is not of same length as sequence ('$length')") if $length != $$prof->getLength();
    $pos-=($win+1)/2;
    my @return;
    for (my $i = 0; $i < $win; $i++) {
       if ($pos<0 || $pos >= $length){
        push (@return,0,0,0,0);
       } 
       else {
        my @ret=qw(0 0 0);
        my $struct=$$prof->getData($pos+1,'PHEL');
        if ($struct eq "H"){
            $ret[0]++;
        }
        elsif ($struct eq "E"){
            $ret[1]++;
        }
        elsif ($struct eq "L"){
            $ret[2]++;
        }
        push @return,@ret,$$prof->getData($pos+1,'RI_S')/9;
       }
    $pos++;
    }
    cluck( Dumper (@return) ) if $debug;
    return @return;

}
sub protein_length{
   my ($length,$debug)=@_;
   my @result;
   if ($length<60){
        push @result,$length/60,0,0,0,0,0;
   }
   elsif ($length<120){
        push @result,1,($length-60)/60,0,0,0,0;
   }
   elsif ($length<180){
        push @result,1,1,($length-120)/60,0,0,0;
   }
   elsif ($length<240) {
        push @result,1,1,1,($length-180)/60,0,0;
   }
   elsif ($length<300){
        push @result,1,1,1,1,($length-240)/60,0;
   }
   else{
        push @result,1,1,1,1,1,min(($length-300)/60,1);
   }
   cluck (Dumper (\@result)) if $debug;
   return @result;
}
sub acc_bin{
    my ($length,$pos,$prof,$win,$debug)=@_;
    confess ("Window size needs to be uneven (window: '$win')") if $win % 2 == 0;
    confess ("Window size needs to be > 0 (window: '$win')") if $win < 1;
    confess ("Position '$pos' is out of bounds: [1,$length]") if ($pos > $length || $pos < 1);
    confess ("Prof prediction file ('".$$prof->getLength()."') is not of same length as sequence ('$length')") if $length != $$prof->getLength();
    $pos-=($win+1)/2;
    my @return;
    for (my $i = 0; $i < $win; $i++) {
       if ($pos<0 || $pos >= $length){
        push (@return,0,0,0,0);
       } 
       else {
        my @ret=qw(0 0 0);
        my $acc=$$prof->getData($pos+1,'Pbie');
        if ($acc eq "b"){
            $ret[0]++;
        }
        elsif ($acc eq "i"){
            $ret[1]++;
        }
        elsif ($acc eq "e"){
            $ret[2]++;
        }
        push @return,@ret,$$prof->getData($pos+1,'RI_A')/9;
       }
    $pos++;
    }
    cluck( Dumper (@return) ) if $debug;
    return @return;

}
sub acc_rel{
    my ($length,$pos,$prof,$win,$debug)=@_;
    confess ("Window size needs to be uneven (window: '$win')") if $win % 2 == 0;
    confess ("Window size needs to be > 0 (window: '$win')") if $win < 1;
    confess ("Position '$pos' is out of bounds: [1,$length]") if ($pos > $length || $pos < 1);
    confess ("Prof prediction file ('".$$prof->getLength()."') is not of same length as sequence ('$length')") if $length != $$prof->getLength();
    $pos-=($win+1)/2;
    my @return;
    for (my $i = 0; $i < $win; $i++) {
       if ($pos<0 || $pos >= $length){
        push (@return,0,0);
       } 
       else {
        my $rel_acc=$$prof->getData($pos+1,'PREL');
        push @return,lin_normalize_0_1($rel_acc,100,0),$$prof->getData($pos+1,'RI_A')/9;
       }
    $pos++;
    }
    cluck( Dumper (@return) ) if $debug;
    return @return;

}

sub sec_comp{
   my ($length,$prof,$debug)=@_; 
   my %HEL=(H=>0,E=>0,L=>0);
   my @result;
   for (my $i=1; $i<=$length;$i++){
        my $sec=$$prof->getData($i,'PHEL');
       confess ("Unknown structure state (must be H,E,L): '$sec'") unless defined $HEL{$sec};
       $HEL{$$prof->getData($i,'PHEL')}++;
   }
   foreach my $sec (qw(H E L)) {
       my $prop=$HEL{$sec}/$length;
       print "Secondary structure composition:\n$sec $prop\n" if $debug;
       if ($prop<0.25){
            push @result,$prop/0.25,0,0,0;
       }
       elsif ($prop<0.50){
            push @result,1,($prop-0.25)/0.25,0,0;
       }
       elsif ($prop<0.75){
            push @result,1,1,($prop-0.50)/0.25,0;
       }
       else {
            push @result,1,1,1,($prop-0.75)/0.25;
       }
   }
   cluck (Dumper(\@result)) if $debug;
   return @result;
}
sub acc_comp{
   my ($length,$prof,$debug)=@_; 
   my %bie=(e=>0,b=>0,i=>0);
   my @result;
   for (my $i=1; $i<=$length;$i++){
        my $acc=$$prof->getData($i,'Pbie');
       confess ("Unknown accessibility state (must be b,i,e): '$acc'") unless defined $bie{$acc};
       $bie{$$prof->getData($i,'Pbie')}++;
   }
   foreach my $acc (qw(b i e)) {
       my $prop=$bie{$acc}/$length;
       print "Solvent accessibility composition:\n$acc $prop\n" if $debug;
       if ($prop<0.25){
            push @result,$prop/0.25,0,0,0;
       }
       elsif ($prop<0.50){
            push @result,1,($prop-0.25)/0.25,0,0;
       }
       elsif ($prop<0.75){
            push @result,1,1,($prop-0.50)/0.25,0;
       }
       else {
            push @result,1,1,1,($prop-0.75)/0.25;
       }
   }
   cluck (Dumper(\@result)) if $debug;
   return @result;
}
sub profDiff{
	my ($wt,$pos,$mut,$mutantprof_file,$wtprof,$debug)=@_;

	my $mutprof=RG::Snap2::Profparser->new($mutantprof_file);
	
	#difference and sign for PREl,RI_A,pH,pE,pL and RI_S
	my ($prel_sign,$oth_sign,$ote_sign,$otl_sign,$ss_change,$sa_change)=qw(0 0 0 0 0 0);
	my $preldif = $$wtprof->getData($pos,'PREL') - $mutprof->getData($pos,'PREL');
	$prel_sign = 1 if $preldif<0;
	my $avg_ri_a=($$wtprof->getData($pos,'RI_A') + $mutprof->getData($pos,'RI_A'))/2;
	my $othdif=$$wtprof->getData($pos,'pH') - $mutprof->getData($pos,'pH');
	$oth_sign=1 if $othdif<0;
	my $otedif=$$wtprof->getData($pos,'pE') - $mutprof->getData($pos,'pE');
	$ote_sign=1 if $otedif<0;
	my $otldif=$$wtprof->getData($pos,'pL') - $mutprof->getData($pos,'pL');
	$otl_sign=1 if $otldif<0;
	my $avg_ri_s=($$wtprof->getData($pos,'RI_S') + $mutprof->getData($pos,'RI_S'))/2;
    $ss_change=1 if ($$wtprof->getData($pos,'PHEL') ne $mutprof->getData($pos,'PHEL'));
    $sa_change=1 if ($$wtprof->getData($pos,'Pbie') ne $mutprof->getData($pos,'Pbie')); 

	#linear normalization of difference values 
	foreach my $value ($preldif,$othdif,$otedif,$otldif){
		$value=lin_normalize_0_1(abs($value),100,0);
	}
	#normalize change of reliability indices
    $avg_ri_a/=9;
    $avg_ri_s/=9;
	
	my @features=($preldif,$prel_sign,$avg_ri_a,$sa_change,$othdif,$oth_sign,$otedif,$ote_sign,$otldif,$otl_sign,$avg_ri_s,$ss_change);
	cluck (Dumper (@features)) if ($debug);
	return @features;
	
}

sub extractPfam{
    my ($wtpfam,$mutation,$mutpfam,$debug)=@_;
    my @features=qw(0 0 0 0);
    
    #if there is no pfam annotation for this position
    return @features unless $$wtpfam->{hit};
    
    #otherwise we have a pfam annotation for this protein
    $features[3]=1;
    my ($wt,$pos,$mut)=wt_pos_mut($mutation);
    my ($model,$domain)=$$wtpfam->at_pos($pos);
    return @features unless ($model && $domain);
    
    $mutpfam=RF::Snap2::Pfamparser->new($mutpfam);

    #if there is no significant hit in the mutation pfam
    return qw(0 0 0 1) unless $mutpfam->{hit};

    my ($m2,$d2)=$mutpfam->at_pos($pos);

    #if the mutant does not have a (significant) model or is not within the aligned region
    return qw(0 0 0 1) unless ($m2 && $d2);

    #cant extract difference feature if mutant and wildtype are mapped to different pfam domains
    #maybe neo-functionalization?
    $model=~/^(.*)\./o;
    my $modelid=$1;
    $m2=~/^(.*)\./o;
    return qw(0 0 0 1) if ($modelid ne $1);
    
    #now do the extraction itself:
    my $wtdomain=$$wtpfam->domain($model,$domain);
    my $mutdomain=$mutpfam->domain($m2,$d2);

    #normalized average evalue exponent
    my $wteval=$wtdomain->{evalue};
    my $muteval=$mutdomain->{evalue};
    $wteval=~s/^.*\..*e\-//;
    $muteval=~s/^.*\..*e\-//;
    $features[2]= min(1.0,(($wteval+$muteval)/200));

    #since the alignment may be gapped we first have to find the corresponding array position
    my $wtfrom=$wtdomain->{from};
    my $i=-1;
    while ( $wtfrom <= $pos){
        $i++;
        confess "Position $pos is not annotated in this domain ($wtdomain->{from} - $wtdomain->{to}" unless defined $wtdomain->{prob}[$i];
        next if ($wtdomain->{prob}[$i] eq ".");
        $wtfrom++;
    }
    confess "Inconsistent pfam annotation: Wildtype amino acid ($wt) at position '$pos' does not correspond to amino acid in pfam query sequence ($wtdomain->{seq}[$i])" unless $wtdomain->{seq}[$i]=~/$wt/i;
    
    #same thing for the mutant
    my $mutfrom=$mutdomain->{from};
    my $j=-1;
    while ($mutfrom <= $pos){
        $j++;
        confess "Position $pos is not annotated in this domain ($mutdomain->{from} - $mutdomain->{to}" unless defined $mutdomain->{prob}[$j];
        next if ($mutdomain->{prob}[$j] eq ".");
        $mutfrom++;
        
    }
    confess "Inconsistent pfam annotation: Mutant amino acid ($mut) at position '$pos' does not correspond to amino acid in pfam query sequence ($mutdomain->{seq}[$j])" unless $mutdomain->{seq}[$j]=~/$mut/i;
    cluck (Dumper($wtdomain,$mutdomain)) if $debug; 

    $wtdomain->{prob}[$i] = 10 if $wtdomain->{prob}[$i] eq "*";
    $mutdomain->{prob}[$j] = 10 if $mutdomain->{prob}[$j] eq "*";
    my $prob_diff=($wtdomain->{prob}[$i]-$mutdomain->{prob}[$j])/10;
    $features[0]=abs($prob_diff);
    $features[1]=1 if $prob_diff < 0;

    cluck (Dumper (@features)) if $debug;
    return @features;
}
sub blastPssm{
    my ($length,$pos,$pssm,$win,$debug)=@_;
    my @normalized=$$pssm->normalized();
    confess ("Window size needs to be uneven (window: '$win')") if $win % 2 == 0;
    confess ("Window size needs to be > 0 (window: '$win')") if $win < 1;
    confess ("Position '$pos' is out of bounds: [1,$length]") if ($pos > $length || $pos < 1);
    confess ("Position '$pos' is out of bounds (max is: ".scalar(@normalized).")") if ($pos>scalar(@normalized));
    $pos-=($win+1)/2;
    my @return;
    for (my $i = 0; $i < $win; $i++) {
       if ($pos<0 || $pos >= $length){
        push (@return,qw(0) x 20);
       } 
       else {
        push @return,@{$normalized[$pos]};
       }
    $pos++;
    }
    cluck( Dumper (@return) ) if $debug;
    return @return;
    
}
sub blastPerc{
    my ($length,$pos,$pssm,$win,$debug)=@_;
    my @percentage=$$pssm->percentage();
    confess ("Window size needs to be uneven (window: '$win')") if $win % 2 == 0;
    confess ("Window size needs to be > 0 (window: '$win')") if $win < 1;
    confess ("Position '$pos' is out of bounds: [1,$length]") if ($pos > $length || $pos < 1);
    confess ("Position '$pos' is out of bounds (max is: ".scalar(@percentage).")") if ($pos>scalar(@percentage));
    $pos-=($win+1)/2;
    my @return;
    for (my $i = 0; $i < $win; $i++) {
       if ($pos<0 || $pos >= $length){
        push (@return,qw(0) x 20);
       } 
       else {
        push @return,@{$percentage[$pos]};
       }
    $pos++;
    }
    cluck( Dumper (@return) ) if $debug;
    return @return;
    
}
sub pssmDiff{
    my ($wt,$pos,$mut,$pssm,$debug)=@_;
    my @normalized=$$pssm->normalized();
    confess ("Position '$pos' is out of bounds (max is: ".scalar(@normalized).")") if ($pos>scalar(@normalized));
    confess ("Invalid wildtype amino acid: '$wt'") unless defined $index{$wt};
    confess ("Invalid mutation amino acid: '$mut'") unless defined $index{$mut};    
    my $diff=($normalized[$pos-1][$index{$wt}])-($normalized[$pos-1][$index{$mut}]);
    cluck (Dumper ("$wt: ".($normalized[$pos-1][$index{$wt}]),"$mut: ".($normalized[$pos-1][$index{$mut}]))) if $debug;
    my $sign=0;
    if ($diff<0){$sign=1};
    cluck (Dumper (abs($diff),$sign)) if $debug;
    return (abs($diff),$sign);
}
sub percDiff{
my ($wt,$pos,$mut,$pssm,$debug)=@_;
    my @percent=$$pssm->percentage();
    confess ("Position '$pos' is out of bounds (max is: ".scalar(@percent).")") if ($pos>scalar(@percent));
    confess ("Invalid wildtype amino acid: '$wt'") unless defined $index{$wt};
    confess ("Invalid mutation amino acid: '$mut'") unless defined $index{$mut};    
    my $diff=($percent[$pos-1][$index{$wt}])-($percent[$pos-1][$index{$mut}]);
    cluck (Dumper ("$wt: ".($percent[$pos-1][$index{$wt}]),"$mut: ".($percent[$pos-1][$index{$mut}]))) if $debug;
    my $sign=0;
    if ($diff<0){$sign=1};
    cluck (Dumper (abs($diff),$sign)) if $debug;
    return (abs($diff),$sign);
}
sub psic{
    my ($length,$pos,$psic,$win,$debug)=@_;
    my @normalized=$$psic->normalized();
    confess ("Window size needs to be uneven (window: '$win')") if $win % 2 == 0;
    confess ("Window size needs to be > 0 (window: '$win')") if $win < 1;
    confess ("Position '$pos' is out of bounds: [1,$length]") if ($pos > $length || $pos < 1);
    confess ("Position '$pos' is out of bounds (max is: ".scalar(@normalized).")") if ($pos>scalar(@normalized));
    $pos-=($win+1)/2;
    my @return;
    for (my $i = 0; $i < $win; $i++) {
       if ($pos<0 || $pos >= $length){
        push (@return,qw(0) x 20);
       } 
       else {
        push @return,@{$normalized[$pos]};
       }
    $pos++;
    }
    cluck( Dumper (@return) ) if $debug;
    return @return;

}
sub psicDiff{
    my ($wt,$pos,$mut,$psic,$debug)=@_;
    my @normalized=$$psic->normalized();
    confess ("Position '$pos' is out of bounds (max is: ".scalar(@normalized).")") if ($pos>scalar(@normalized));
    confess ("Invalid wildtype amino acid: '$wt'") unless defined $index{$wt};
    confess ("Invalid mutation amino acid: '$mut'") unless defined $index{$mut};    
    my $diff=($normalized[$pos-1][$index{$wt}])-($normalized[$pos-1][$index{$mut}]);
    cluck (Dumper ("$wt: ".($normalized[$pos-1][$index{$wt}]),"$mut: ".($normalized[$pos-1][$index{$mut}]))) if $debug;
    my $sign=0;
    if ($diff<0){$sign=1};
    cluck (Dumper (abs($diff),$sign)) if $debug;
    return (abs($diff),$sign);
}
sub profbval{
    my ($length,$pos,$profbval,$win,$debug)=@_;
    my @norm1=$$profbval->norm1();
    my @norm2=$$profbval->norm2();
    my @ri=$$profbval->ri();
    confess ("Window size needs to be uneven (window: '$win')") if $win % 2 == 0;
    confess ("Window size needs to be > 0 (window: '$win')") if $win < 1;
    confess ("Position '$pos' is out of bounds: [1,$length]") if ($pos > $length || $pos < 1);
    confess ("Position '$pos' is out of bounds (max is: ".scalar(@norm1).")") if ($pos>scalar(@norm1));
    $pos-=($win+1)/2;
    my @return;
    for (my $i = 0; $i < $win; $i++) {
       if ($pos<0 || $pos >= $length){
        push (@return,0,0,0);
       } 
       else {
        push @return,$norm1[$pos],$norm2[$pos],$ri[$pos];
       }
    $pos++;
    }
    cluck( Dumper (@return) ) if $debug;
    return @return;
}
sub disis{
    my ($length,$pos,$disis,$win,$debug)=@_;
    my @bin=$$disis->bin();
    my @ri=$$disis->ri();
    confess ("Window size needs to be uneven (window: '$win')") if $win % 2 == 0;
    confess ("Window size needs to be > 0 (window: '$win')") if $win < 1;
    confess ("Position '$pos' is out of bounds: [1,$length]") if ($pos > $length || $pos < 1);
    confess ("Position '$pos' is out of bounds (max is: ".scalar(@bin).")") if ($pos>scalar(@bin));
    $pos-=($win+1)/2;
    my @return;
    for (my $i = 0; $i < $win; $i++) {
       if ($pos<0 || $pos >= $length){
        push (@return,0,0);
       } 
       else {
        push @return,$bin[$pos],$ri[$pos];
       }
    $pos++;
    }
    cluck( Dumper (@return) ) if $debug;
    return @return;
}
sub isis{
    my ($length,$pos,$isis,$win,$debug)=@_;
    my @bin=$$isis->bin();
    my @ri=$$isis->ri();
    confess ("Window size needs to be uneven (window: '$win')") if $win % 2 == 0;
    confess ("Window size needs to be > 0 (window: '$win')") if $win < 1;
    confess ("Position '$pos' is out of bounds: [1,$length]") if ($pos > $length || $pos < 1);
    confess ("Position '$pos' is out of bounds (max is: ".scalar(@bin).")") if ($pos>scalar(@bin));
    $pos-=($win+1)/2;
    my @return;
    for (my $i = 0; $i < $win; $i++) {
       if ($pos<0 || $pos >= $length){
        push (@return,0,0);
       } 
       else {
        push @return,$bin[$pos],$ri[$pos];
       }
    $pos++;
    }
    cluck( Dumper (@return) ) if $debug;
    return @return;
}
sub aa_comp{
    my ($length,$seq_array,$debug)=@_;
    my (%composition,@result);
    map {$composition{$_}=0} @amino_acids;
    foreach my $aa (@{$seq_array}) {
        if (defined $composition{$aa}){
            $composition{$aa}++
        }
        else {
            confess ("Unknown amino acid: '$aa'\n");
        }
    }
    foreach my $aa (@amino_acids) {
        print $aa . " " . $composition{$aa}/$length . "\n" if $debug;
        push @result,($composition{$aa}/$length);
    }
    return @result;
}
sub md{
    my ($length,$pos,$md,$win,$debug)=@_;
    my @normalized=$$md->normalized();
    my @ri=$$md->ri();
    my @bin=$$md->bin();
    confess ("Window size needs to be uneven (window: '$win')") if $win % 2 == 0;
    confess ("Window size needs to be > 0 (window: '$win')") if $win < 1;
    confess ("Position '$pos' is out of bounds: [1,$length]") if ($pos > $length || $pos < 1);
    confess ("Position '$pos' is out of bounds (max is: ".scalar(@normalized).")") if ($pos>scalar(@normalized));
    $pos-=($win+1)/2;
    my @return;
    for (my $i = 0; $i < $win; $i++) {
       if ($pos<0 || $pos >= $length){
        push (@return,0,0,0);
       } 
       else {
        push @return,$normalized[$pos],$ri[$pos],$bin[$pos];
       }
    $pos++;
    }
    cluck( Dumper (@return) ) if $debug;
    return @return;
    
}
sub qsnap_pred{
    my ($snap,$mutation,$debug)=@_;
    my %preds=$$snap->all();
    confess ("No Quicksnap prediction found for mutation: $mutation") unless defined $preds{$mutation};
    my $score=$preds{$mutation};
    my @return=($score > 0 ? qw(0 1) : qw(1 0));
    push @return,abs($score/100);
    cluck( Dumper (\@return)) if $debug;
    return @return;
}
sub qsnap_avg{
    my ($snap,$pos,$win,$length,$debug)=@_;
    my @return;
    my @avg=$$snap->avg();
    confess ("Window size needs to be uneven (window: '$win')") if $win % 2 == 0;
    confess ("Window size needs to be > 0 (window: '$win')") if $win < 1;
    confess ("Position '$pos' is out of bounds: [1,$length]") if ($pos > $length || $pos < 1);
    confess ("Inconsistency: found " . scalar(@avg) . "Quicksnap predictions when expecting $length") if scalar(@avg) != $length;
    $pos-=($win+1)/2;
    for (my $i = 0; $i < $win; $i++) {
       if ($pos<0 || $pos >= $length){
           push (@return,0,0,0);
       } 
       else {
           my $score=$avg[$pos];
           push @return,($score > 0 ? qw(0 1) : qw(1 0)),abs($score/100);
       }
    $pos++;
    }
    cluck( Dumper (\@return) ) if $debug;
    return @return;  

}
sub sift{
    my ($siftfile,$mutation,$debug)=@_;
    my @feature=(0,0,0);
    #return @feature unless -e $siftfile;
    open SIFT,$siftfile or confess "Failed to open Sift prediction: $siftfile";
    my ($mutline) = grep (/$mutation/,<SIFT>);
    close SIFT;
    unless ($mutline){
        cluck "No SIFT prediction available for '$mutation'" if ($debug);
        return @feature;
    } 
    my ($mut,$pred,$score) = split(/\s+/,$mutline);
    if ($pred eq "TOLERATED"){
        $feature[0]=1;
    }   
    elsif ($pred eq "DELETERIOUS"){
        $feature[1]=1;
    }   
    elsif ($pred eq "NOT"){
        return @feature;
    }   
    else {
        confess "SIFT prediction is not in expected format: '$mutline'"
    }   
    $feature[2]=$score;
    cluck (Dumper(@feature)) if $debug;
    return @feature;
}
########### Helper subroutines ##########

#returns $norm: inputvalue normalized linearly between 0 and 1
#requires $input: numeric value
#requires $upper_bound: upper bound of input values
#requires $lower_bound: lower bound of input values
sub lin_normalize_0_1{
	my($input,$upper_bound,$lower_bound)=@_;
	my $norm=($input - $lower_bound) / ($upper_bound - $lower_bound);
	return sprintf("%.3f",$norm);
	
}

#returns @result: array with [wildtype aminoacid, position, mutant_aminoacid]
#requires $mut: mutation in format A38D
sub wt_pos_mut {
	my ($mut,$debug)=@_;
	$mut=~/^\s*(\w)(\d+)(\w)\s*$/o || confess "\nError: unknown format for mutation: $mut\n";
	my @result=($1, $2, $3);
	if ($debug) {cluck (Dumper(\@result))};
	return @result;
}


### Swissprot related helpers
#requires $_swiss_dat_fh: filehandle for uniprot_sprot.dat
#requires $__startpos: position to seek within uniprot_sprot.dat
#returns $ret: swissprot record at given $_startpos
sub	_sprot_rec_at_pos
{
    my( $__swiss_dat_fh, $__startpos ) = @_;
    seek( $__swiss_dat_fh, $__startpos, 0 );
    local $/ = "//\n";
    my $ret = <$__swiss_dat_fh>;
    return $ret;
}

#returns $best_hit: String with the best hit alignment (multiple lines)
#requires $blastfile: path to blast file
sub best_swiss_hit {
	my($blastfile,$debug) = @_;
	open (FILE, $blastfile);
	my @file_content_array = <FILE>;
	close FILE;	
	my $blast_file_content = "@file_content_array";
	return "No hits found" if ($blast_file_content =~ /No hits found/);
	$blast_file_content =~ s/[^\>]+(\>[^\s\|]+\|+[^\s]+\s+[^\>]+)(\>|Database\:)//;
	#$blast_file_content =~ s/[^\>]+\>([^\s\|]+\|)+([^\s]+)\s+([^\>]+)(\>|Database\:)//;
	my $best_hit = $1;
	return "No hits found" unless $best_hit =~/Expect = (0\.0|\d*e\-\d+)/o;
	cluck ($best_hit) if ($debug);
	#print "$best_hit\n";
	return $best_hit;
}

#returns %swiss_keywords hash: position => swissprot keyword annotation
#requires $protein_name: protein for which annotation should be looked up e.g. RAD51_HUMAN
#requires $swiss_dat_file: path to uniprot_sprot.dat
#requires $db_swiss: path to dbSwiss index
#This method looks up Swissprot annotation for a given protein
#the following keywords are considered: TRANSMEM|PROPEP|MOD_RES|SIGNAL|MUTAGEN|CONFLICT|VARIANT|BINDING|ACT_SITE|SITE|LIPID|METAL|CARBOHYD|DNA_BIND|ZN_FING|CA_BIND|NP_BIND
#If annotation for this protein is found $swiss_keywords{0} equals 1 
#otherwise $swiss_keywords{0}=0
sub extractSwissKeywords {
	my ($protein_name,$swiss_dat_file,$db_swiss,$debug)=@_;
	my (%ID_index,%swiss_keywords,$entry,$keyword,$from_position,$to_position);
    # open ID index database, open uniprot_sprot.dat
    my $swiss_dat_fh = IO::File->new( $swiss_dat_file, 'r' ) || confess("\nError: could not open '$swiss_dat_file': $!");    
    tie %ID_index, "DB_File", $db_swiss, O_RDONLY, 0666, $DB_HASH or confess("\nError: could not open file '$db_swiss': $!");
	$entry = lc( $protein_name );

	if( exists( $ID_index{$entry} ) and defined( $ID_index{$entry} ) )
    {
        my $temp = _sprot_rec_at_pos( $swiss_dat_fh, $ID_index{$entry} ) || confess( "\nError: no record in '$swiss_dat_file' at position $ID_index{$entry}" );
		my @entry_lines = split (/\n/o, $temp);
		foreach my $line (@entry_lines){
			#print $line."\n";
			if ($line =~ /FT\s+(DISULFID|SE_CYS|TRANSMEM|PROPEP|MOD_RES|SIGNAL|MUTAGEN|CONFLICT|VARIANT|BINDING|ACT_SITE|SITE|LIPID|METAL|CARBOHYD|DNA_BIND|ZN_FING|CA_BIND|NP_BIND)/o){
				$line =~ s/FT\s+//;
				if ($line =~ /TRANSMEM|PROPEP|MOD_RES|SIGNAL|MUTAGEN|CONFLICT|VARIANT|BINDING|ACT_SITE|SITE|LIPID|METAL|CARBOHYD|DNA_BIND|ZN_FING|CA_BIND|NP_BIND/o){

					$line =~ /(TRANSMEM|PROPEP|MOD_RES|SIGNAL|MUTAGEN|CONFLICT|VARIANT|BINDING|ACT_SITE|SITE|LIPID|METAL|CARBOHYD|DNA_BIND|ZN_FING|CA_BIND|NP_BIND)\s+(\?|\>|\<)*(\d+)\s+(\?|\<|\>)*(\d+)/;
					$keyword = $1;
					$from_position = $3;
					$to_position = $5;
					if (!$from_position or !$to_position or !$keyword){
						cluck ("Missing start/stop position for current entry: $line\n") if ($debug);
						next;
					}
					foreach my $position ($from_position..$to_position){
						$swiss_keywords{$position}.="$keyword ";
					}
				}
				elsif($line =~ /DISULFID|SE_CYS/o){
					$line =~ s/(DISULFID|SE_CYS)\s+\?*(\d+)\s+\?*(\d+)//;
					$keyword = $1;
					$from_position = $2;
					$to_position = $3;
					if (!$from_position or !$to_position or !$keyword){
						cluck ("Missing start/stop position for current entry: $line\n") if ($debug);
						next;
					}					
					$swiss_keywords{$from_position}.="$keyword ";
					$swiss_keywords{$to_position}.="$keyword ";
				}					
			}
		}
		$swiss_keywords{0}=1;
		cluck (Dumper(\%swiss_keywords)) if ($debug);
		return %swiss_keywords;
	}
	else{
		$swiss_keywords{0}=0;
		cluck ("No Swissprot entry for $entry\n") if ($debug);
		return %swiss_keywords;
	}
}

#returns %phat_matrix: hash-matrix representation of the phat matrix;
#requires $file: path to phat matrix file
sub getPhatMatrix{
	my ($file,$debug)  = @_;
	my ($current_aa, $i, $aa, %phat_matrix);
	open (MATRIX, $file) || confess ("\nError: could not open PHAT file: $file\n");
	foreach my $line (<MATRIX>){
		if ($line =~ /\d/){
			$line =~ s/([A-Z])//;
			$current_aa = $1;
			$i = 0;
			while ($i < @amino_acids-1){
				$aa = $amino_acids[$i];
				$line =~ s/^\s+(\-*\d+)\s+/ /;
				$phat_matrix{$current_aa}{$aa} = $1;
				$i++;
			}
		}
	}
	close MATRIX;
	cluck (Dumper(\%phat_matrix)) if ($debug);
	return %phat_matrix;
}

#returns %matrix: hash-matrix representation of normalized phat matrix
#requires $phat_file: path to phat matrix file
#this method calls 'getPhatMatrix' and then applies 'lin_normalize_0_1' to every value, using $ub as upper bound and $lb as lower bound
#$ub is hardcoded to 13
#$lb is hardcoded to -10
#These need to be adjusted if the phat file content changes.
#this method should fail if $ub and $lb are not correctly set
sub getNormalizedPhatMatrix{
	my ($phat_file,$debug)=@_;
	my %matrix=getPhatMatrix($phat_file,$debug);
	my $upper_bound=0;
	my $lower_bound=0;
	my $ub=13;
	my $lb=-10;
	foreach my $aa1 (keys %matrix){
		foreach my $aa2 (keys %{ $matrix{$aa1} }){
			#the following two if-clauses ensure that $ub and $lb are correctly set.
			if ($matrix{$aa1}{$aa2}>$upper_bound) {$upper_bound=$matrix{$aa1}{$aa2}}
			if ($matrix{$aa1}{$aa2}<$lower_bound) {$lower_bound=$matrix{$aa1}{$aa2}}
			
			$matrix{$aa1}{$aa2}=lin_normalize_0_1($matrix{$aa1}{$aa2},$ub,$lb);
		}
	}
	if ($ub!=$upper_bound || $lb!=$lower_bound) {confess ("\nError: normalization bounds not correct: please adjust upper and lower bound\nLower bound should be : $lower_bound\nUpper bound should be: $upper_bound\n") }
	if ($debug){
		cluck (Dumper(\%matrix));
	}
	return %matrix;
}
1;

							




