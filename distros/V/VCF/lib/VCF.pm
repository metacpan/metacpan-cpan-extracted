package VCF;
$VCF::VERSION = '1.003';
# http://vcftools.sourceforge.net/specs.html
# http://samtools.github.io/hts-specs/
#
# Authors: petr.danecek@sanger
# for VCF v3.2, v3.3, v4.0, v4.1, v4.2
#

# ABSTRACT: Module for validation, parsing and creating VCF files.

=head1 NAME

VCF.pm.  Module for validation, parsing and creating VCF files.
         Supported versions: 3.2, 3.3, 4.0, 4.1, 4.2

=head1 SYNOPSIS

From the command line:
    perl -MVCF -e validate example.vcf
    perl -I/path/to/the/module/ -MVCF -e validate_v32 example.vcf

From a script:
    use VCF;

    my $vcf = VCF->new(file=>'example.vcf.gz',region=>'1:1000-2000');
    $vcf->parse_header();

    # Do some simple parsing. Most thorough but slowest way how to get the data.
    while (my $x=$vcf->next_data_hash())
    {
        for my $gt (keys %{$$x{gtypes}})
        {
            my ($al1,$sep,$al2) = $vcf->parse_alleles($x,$gt);
            print "\t$gt: $al1$sep$al2\n";
        }
        print "\n";
    }

    # This will split the fields and print a list of CHR:POS
    while (my $x=$vcf->next_data_array())
    {
        print "$$x[0]:$$x[1]\n";
    }

    # This will return the lines as they were read, including the newline at the end
    while (my $x=$vcf->next_line())
    {
        print $x;
    }

    # Only the columns NA00001, NA00002 and NA00003 will be printed.
    my @columns = qw(NA00001 NA00002 NA00003);
    print $vcf->format_header(\@columns);
    while (my $x=$vcf->next_data_array())
    {
        # this will recalculate AC and AN counts, unless $vcf->recalc_ac_an was set to 0
        print $vcf->format_line($x,\@columns);
    }

    $vcf->close();

=cut

use strict;
use warnings;
use Carp;
use Exporter;
use Data::Dumper;
use POSIX ":sys_wait_h";

use vars qw/@ISA @EXPORT/;
@ISA = qw/Exporter/;
@EXPORT = qw/validate validate_v32/;

use VCF::V3_2;
use VCF::V3_3;
use VCF::V4_0;
use VCF::V4_1;
use VCF::V4_2;

=head2 validate

    About   : Validates the VCF file.
    Usage   : perl -MVCF -e validate example.vcf.gz     # (from the command line)
              validate('example.vcf.gz');               # (from a script)
              validate(\*STDIN);
    Args    : File name or file handle. When no argument given, the first command line
              argument is interpreted as the file name.

=cut

sub validate
{
    my ($fh) = @_;

    if ( !$fh && @ARGV ) { $fh = $ARGV[0]; }

    my $vcf;
    if ( $fh ) { $vcf = fileno($fh) ? VCF->new(fh=>$fh) : VCF->new(file=>$fh); }
    else { $vcf = VCF->new(fh=>\*STDIN); }

    $vcf->run_validation();
}


=head2 validate_v32

    About   : Same as validate, but assumes v3.2 VCF version.
    Usage   : perl -MVCF -e validate_v32 example.vcf.gz     # (from the command line)
    Args    : File name or file handle. When no argument given, the first command line
              argument is interpreted as the file name.

=cut

sub validate_v32
{
    my ($fh) = @_;

    if ( !$fh && @ARGV && -e $ARGV[0] ) { $fh = $ARGV[0]; }

    my %params = ( version=>'3.2' );

    my $vcf;
    if ( $fh ) { $vcf = fileno($fh) ? VCF->new(%params, fh=>$fh) : VCF->new(%params, file=>$fh); }
    else { $vcf = VCF->new(%params, fh=>\*STDIN); }

    $vcf->run_validation();
}


=head2 new

    About   : Creates new VCF reader/writer.
    Usage   : my $vcf = VCF->new(file=>'my.vcf', version=>'3.2');
    Args    :
                fh      .. Open file handle. If neither file nor fh is given, open in write mode.
                file    .. The file name. If neither file nor fh is given, open in write mode.
                region  .. Optional region to parse (requires tabix indexed VCF file)
                silent  .. Unless set to 0, warning messages may be printed.
                strict  .. Unless set to 0, the reader will die when the file violates the specification.
                version .. If not given, '4.0' is assumed. The header information overrides this setting.

=cut

sub new
{
    my ($class,@args) = @_;
    my $self = {@args};
    bless $self, ref($class) || $class;

    $$self{silent}    = 0 unless exists($$self{silent});
    $$self{strict}    = 0 unless exists($$self{strict});
    $$self{buffer}    = [];       # buffer stores the lines in the reverse order
    $$self{columns}   = undef;    # column names
    $$self{mandatory} = ['CHROM','POS','ID','REF','ALT','QUAL','FILTER','INFO'] unless exists($$self{mandatory});
    $$self{reserved}{cols} = {CHROM=>1,POS=>1,ID=>1,REF=>1,ALT=>1,QUAL=>1,FILTER=>1,INFO=>1,FORMAT=>1} unless exists($$self{reserved_cols});
    $$self{recalc_ac_an} = 1;
    $$self{has_header} = 0;
    $$self{default_version} = '4.2';
    $$self{versions} = [ qw(Vcf3_2 Vcf3_3 Vcf4_0 Vcf4_1 Vcf4_2) ];
    if ( !exists($$self{max_line_len}) && exists($ENV{MAX_VCF_LINE_LEN}) ) { $$self{max_line_len} = $ENV{MAX_VCF_LINE_LEN} }
    $$self{fix_v40_AGtags} = $ENV{DONT_FIX_VCF40_AG_TAGS} ? 0 : 1;
    my %open_args = ();
    if ( exists($$self{region}) )
    {
        $open_args{region}=$$self{region};
        if ( !exists($$self{print_header}) ) { $$self{print_header}=1; }
    }
    if ( exists($$self{print_header}) ) { $open_args{print_header}=$$self{print_header}; }
    return $self->_open(%open_args);
}

sub throw
{
    my ($self,@msg) = @_;
    confess @msg,"\n";
}

sub warn
{
    my ($self,@msg) = @_;
    if ( $$self{silent} ) { return; }
    if ( $$self{strict} ) { $self->throw(@msg); }
    warn @msg;
}

sub _open
{
    my ($self,%args) = @_;

    if ( !exists($$self{fh}) && !exists($$self{file}) )
    {
        # Write mode, the version must be supplied by the user
        return $self->_set_version(exists($$self{version}) ? $$self{version} : $$self{default_version});
    }

    # Open the file unless filehandle is provided
    if ( !exists($$self{fh}) )
    {
        if ( !defined $$self{file} ) { $self->throw("Undefined value passed to VCF->new(file=>undef)."); }
        my $cmd = "<$$self{file}";

        my $tabix_args = '';
        if ( exists($args{print_header}) && $args{print_header} ) { $tabix_args .= ' -h '; }
        $tabix_args .= qq['$$self{file}'];
        if ( exists($args{region}) && defined($args{region}) ) { $tabix_args .= qq[ '$args{region}']; }

        if ( -e $$self{file} && $$self{file}=~/\.gz/i )
        {
            if ( exists($args{region}) && defined($args{region}) )
            {
                $cmd = "tabix $tabix_args |";
            }
            else { $cmd = "gunzip -c '$$self{file}' |"; }
        }
        elsif ( $$self{file}=~m{^(?:http|ftp)://} )
        {
            if ( !exists($args{region}) ) { $tabix_args .= ' .'; }
            $cmd = "tabix $tabix_args |";
        }
        open($$self{fh},$cmd) or $self->throw("$cmd: $!");
    }

    # Set the correct VCF version, but only when called for the first time
    my $vcf = $self;
    if ( !$$self{_version_set} )
    {
        my $first_line = $self->next_line();
        $vcf = $self->_set_version($first_line);
        $self->_unread_line($first_line);
    }
    return $vcf;
}



=head2 open

    About   : (Re)Open file. No need to call this explicitly unless reading from a different
              region is requested.
    Usage   : $vcf->open(); # Read from the start
              $vcf->open(region=>'1:12345-92345');
    Args    : region       .. Supported only for tabix indexed files

=cut

sub open
{
    my ($self,%args) = @_;
    $self->close();
    $self->_open(%args);
}


=head2 close

    About   : Close the filehandle
    Usage   : $vcf->close();
    Args    : none
	Returns : close exit status

=cut

sub close
{
    my ($self) = @_;
    if ( !$$self{fh} ) { return; }
    my $ret = close($$self{fh});
    delete($$self{fh});
    $$self{buffer} = [];
	return $ret;
}


=head2 next_line

    About   : Reads next VCF line.
    Usage   : my $vcf = VCF->new();
              my $x   = $vcf->next_line();
    Args    : none

=cut

sub next_line
{
    my ($self) = @_;
    if ( @{$$self{buffer}} ) { return shift(@{$$self{buffer}}); }

    my $line;
    if ( !exists($$self{max_line_len}) )
    {
        $line = readline($$self{fh});
    }
    else
    {
        while (1)
        {
            $line = readline($$self{fh});
            if ( !defined $line ) { last; }

            my $len = length($line);
            if ( $len>$$self{max_line_len} && !($line=~/^#/) )
            {
                if ( !($line=~/^([^\t]+)\t([^\t]+)/) ) { $self->throw("Could not parse the line: $line"); }
                $self->warn("The VCF line too long, ignoring: $1 $2 .. len=$len\n");
                next;
            }
            last;
        }
    }
    return $line;
}

sub _unread_line
{
    my ($self,$line) = @_;
    unshift @{$$self{buffer}}, $line;
    return;
}


=head2 next_data_array

    About   : Reads next VCF line and splits it into an array. The last element is chomped.
    Usage   : my $vcf = VCF->new();
              $vcf->parse_header();
              my $x = $vcf->next_data_array();
    Args    : Optional line to parse

=cut

sub next_data_array
{
    my ($self,$line) = @_;
    if ( !$line ) { $line = $self->next_line(); }
    if ( !$line ) { return undef; }
    if ( ref($line) eq 'ARRAY' ) { return $line; }
    my @items = split(/\t/,$line);
    if ( @items<8 ) { $line=~s/\n/\\n/g; $self->throw("Could not parse the line, wrong number of columns: [$line]"); }
    chomp($items[-1]);
    return \@items;
}


=head2 set_samples

    About   : Parsing big VCF files with many sample columns is slow, not parsing unwanted samples may speed things a bit.
    Usage   : my $vcf = VCF->new();
              $vcf->set_samples(include=>['NA0001']);   # Exclude all but this sample. When the array is empty, all samples will be excluded.
              $vcf->set_samples(exclude=>['NA0003']);   # Include only this sample. When the array is empty, all samples will be included.
              my $x = $vcf->next_data_hash();
    Args    : Optional line to parse

=cut

sub set_samples
{
    my ($self,%args) = @_;

    if ( exists($args{include}) )
    {
        for (my $i=0; $i<@{$$self{columns}}; $i++) { $$self{samples_to_parse}[$i] = 0; }
        for my $sample (@{$args{include}})
        {
            if ( !exists($$self{has_column}{$sample}) ) { $self->throw("The sample not present in the VCF file: [$sample]\n"); }
            my $idx = $$self{has_column}{$sample} - 1;
            $$self{samples_to_parse}[$idx]  = 1;
        }
    }

    if ( exists($args{exclude}) )
    {
        for (my $i=0; $i<@{$$self{columns}}; $i++) { $$self{samples_to_parse}[$i] = 1; }
        for my $sample (@{$args{exclude}})
        {
            if ( !exists($$self{has_column}{$sample}) ) { $self->throw("The sample not present in the VCF file: [$sample]\n"); }
            my $idx = $$self{has_column}{$sample} - 1;
            $$self{samples_to_parse}[$idx]  = 0;
        }
    }
}


sub _set_version
{
    my ($self,$version_line) = @_;

    if ( $$self{_version_set} ) { return $self; }
    $$self{_version_set} = 1;

    $$self{version} = $$self{default_version};
    if ( $version_line )
    {
        if ( $version_line=~/^(\d+(?:\.\d+)?)$/ )
        {
            $$self{version} = $1;
            undef $version_line;
        }
        elsif ( !($version_line=~/^##fileformat=/i) or !($version_line=~/(\d+(?:\.\d+)?)\s*$/i) )
        {
			chomp($version_line);
            $self->warn("Could not parse the fileformat version string [$version_line], assuming VCFv$$self{default_version}\n");
            undef $version_line;
        }
        else
        {
            $$self{version} = $1;
        }
    }

    my $reader;
    if ( $$self{version} eq '3.2' ) { $reader=VCF::V3_2->new(%$self); }
    elsif ( $$self{version} eq '3.3' ) { $reader=VCF::V3_3->new(%$self); }
    elsif ( $$self{version} eq '4.0' ) { $reader=VCF::V4_0->new(%$self); }
    elsif ( $$self{version} eq '4.1' ) { $reader=VCF::V4_1->new(%$self); }
    elsif ( $$self{version} eq '4.2' ) { $reader=VCF::V4_2->new(%$self); }
    else
    {
        $self->warn(qq[The version "$$self{version}" not supported, assuming VCFv$$self{default_version}\n]);
        $$self{version} = '4.2';
        $reader = VCF::V4_2->new(%$self);
    }

    $self = $reader;
    # When changing version, change also the fileformat header line
    if ( exists($$self{header_lines}) && exists($$self{header_lines}[0]{key}) && $$self{header_lines}[0]{key} eq 'fileformat' )
    {
        shift(@{$$self{header_lines}});
    }

    return $self;
}

1;
