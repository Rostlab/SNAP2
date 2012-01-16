package RG::Snap2::Swissparser;

use strict;
use warnings;
use Carp;
use IO::File;
use DB_File;

sub new {
    my ($class, $file,$swiss_dat,$db_swiss) = @_;

    my $self = {
        best_hit  => "No hits found",
        name => "No hits found",
        keywords => {0 => 0}
    };

    bless $self, $class;
    $self->parse($file,$swiss_dat,$db_swiss);
    return $self;
}

sub parse {
    my ($self, $file,$swiss_dat,$db_swiss) = @_;

    open SWISS, $file or croak "Could not open swiss file: '$file'\n";
    my @file_content_array = <SWISS>;
    close SWISS;
	my $blast_file_content = "@file_content_array";
	$blast_file_content =~ s/[^\>]+(\>[^\s\|]+\|+[^\s]+\s+[^\>]+)(\>|Database\:)//;
    my $best_hit=$1;
    $self->{best_hit}=$best_hit;
	confess "\nError: Blast header is not of expected format\n$best_hit" unless $best_hit =~s/^>\w+\|\w+\|(\S+)\s//;
	my $protein_name=$1;
    $self->{name}=$protein_name;
    $self->extractSwissKeywords($swiss_dat,$db_swiss);
    
}
sub extractSwissKeywords {
	my ($self,$swiss_dat_file,$db_swiss,$debug)=@_;
    my $protein_name=$self->{name};
	my (%ID_index,%swiss_keywords,$entry,$keyword,$from_position,$to_position);
    # open ID index database, open uniprot_sprot.dat
    my $swiss_dat_fh = IO::File->new( $swiss_dat_file, 'r' ) || confess("\nError: could not open '$swiss_dat_file': $!");    
    tie %ID_index, "DB_File", $db_swiss, O_RDONLY, 0666, $DB_HASH or confess("\nError: could not open file '$db_swiss': $!");
	$entry = lc( $protein_name );

	if( exists( $ID_index{$entry} ) and defined( $ID_index{$entry} ) )
    {
        my $temp = $self->_sprot_rec_at_pos( $swiss_dat_fh, $ID_index{$entry} ) || confess( "\nError: no record in '$swiss_dat_file' at position $ID_index{$entry}" );
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
						next;
					}					
					$swiss_keywords{$from_position}.="$keyword ";
					$swiss_keywords{$to_position}.="$keyword ";
				}					
			}
		}
		$swiss_keywords{0}=1;
		$self->{keywords}=\%swiss_keywords;
	}
	else{
		$swiss_keywords{0}=0;
		$self->{keywords}=\%swiss_keywords;
	}
}

sub	_sprot_rec_at_pos
{
    my( $self,$__swiss_dat_fh, $__startpos ) = @_;
    seek( $__swiss_dat_fh, $__startpos, 0 );
    local $/ = "//\n";
    my $ret = <$__swiss_dat_fh>;
    return $ret;
}

sub keywords {
    my $self = shift;
    return %{$self->{keywords}};
}

sub best_hit {
    my $self = shift;
    return ${$self->{best_hit}};
}

1;
