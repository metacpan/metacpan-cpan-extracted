package Theodor::Wagner;

use 5.006;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Theodor::Wagner ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();
our $VERSION = '0.81';


my $package = __PACKAGE__;

# GLOBAL VARIABLES
my %Var = ();
my $contentType = "";

$| = 1;

#-----  FORWARD DECLARATIONS & PROTOTYPING
sub Error($);
sub Debug($);

sub new {
	my $type = shift;
	my %params = @_;
	my $self = {};

	$self->{'file'} = $params{'file'};
	$self->{'debug'} = $params{'debug'};

	Debug "$package V$VERSION" if $self->{'debug'};

	bless $self, $type;
}

sub weekday {
	my $self = shift;
	my %Params = @_;

	my $yyyy = $Params{Y};
	my $mm   = $Params{M};
	my $dd   = $Params{D};
	
	my $cc = substr($yyyy, 0, 2);
	my $yy = substr($yyyy, 2, 2);

	print "$mm/$dd/$yyyy - $cc/$yy\...\n";

	my $mod_dd = $dd % 7;

	print "> $dd (dd) % 7 = $mod_dd\n";

	if ($mm == 1 or $mm ==2) {
		if ((($yy % 4) == 0 && ($yy % 100) != 0) or ($yy % 400) == 0) {
			$mm += 12;
		}
	}

	#####  CALCULATING TABLE 1:
	my $h_month =  0;
	   $h_month =  0 if $mm ==  8 or ($mm == 14);
	   $h_month =  1 if $mm ==  2 or ($mm ==  3) or ($mm == 11);
	   $h_month =  2 if $mm ==  6;
	   $h_month =  3 if $mm ==  9 or ($mm == 12);
	   $h_month =  4 if $mm ==  4 or ($mm ==  7) or ($mm == 13);
	   $h_month =  5 if $mm ==  1 or ($mm == 10);
	   $h_month =  6 if $mm ==  5;

	$mm -= 12 if $mm > 12;

	my $table1 = $mod_dd + $h_month;

	print "> [Table 1]  $mod_dd + $h_month (h_month) = $table1\n";


	#####  CALCULATING TABLE 2:
	my $year2 = ($yy * 1.25) % 7;

	print "> ($yy * 1.25) % 7 = $year2\n";

	my $ccTmp = (($cc - 1) % 4) +1;

	my $century2 = 0;

	if ($ccTmp == 4) { $century2 = 2 } else { $century2 = 9 - 2 * $ccTmp }

	my $table2 = $century2 + $year2;

	print "> [Table 2]  $century2 (century2) + $year2 (year2) = $table2\n";

	my $wd = ($table1 + $table2) % 7;

	my @weekdays = ('Sa', 'So', 'Mo', 'Tu', 'We', 'Th', 'Fr');

	$weekdays[$wd];
}

sub Error ($) {
	print "Content-type: text/html\n\n" unless $contentType;
	print "<b>ERROR</b> ($package): $_[0]\n";
	exit(1);
}

sub Debug ($)  { print "[ $package ] $_[0]\n" }

####  Used Warning / Error Codes  ##########################
#	Next free W Code: 1000
#	Next free E Code: 1000

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Theodor::Wagner - Perl extension for calculating each weekday, based on Theodor Wagners model "Ewiger Kalender"

=head1 SYNOPSIS

  use Theodor::Wagner;

  $tw = Theodor::Wagner->new();

  $weekday = $tw->weekday( D => 30, M => 5, Y => 1966 );

=head1 DESCRIPTION

Find the documentation for Theodor::Wagner on
http://www.infocopter.com/perl/

=head2 EXPORT

None by default.


=head1 AUTHOR

Reto Hersiczky, E<lt>retoh@dplanet.chE<gt>

=head1 SEE ALSO

L<perl>.

=cut
