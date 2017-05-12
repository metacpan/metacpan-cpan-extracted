package Weather::OpenWeatherMap::Units;
$Weather::OpenWeatherMap::Units::VERSION = '0.005004';
use feature 'state';
use strictures 2;
use Carp;

use Types::Standard  -all;

use parent 'Exporter::Tiny';
our @EXPORT = our @EXPORT_OK = qw/
  f_to_c
  mph_to_kph
  deg_to_compass
  CoercedInt
/;

sub f_to_c { ($_[0] - 32) * (5/9) }

sub mph_to_kph { $_[0] * 1.609344 }

sub deg_to_compass {
  # I think I stole this from a stackoverflow answer I read, once.
  # Credit where it's due except I can't recall where that might be...
  my $val = int( ($_[0] / 22.5) + 0.5 );
  state $compass = [qw/
    N NNE NE ENE E ESE SE SSE S SSW SW WSW W WNW NW NNW
  /];
  $compass->[ $val % 16 ]
}

my $CoercedInt = Int->plus_coercions(StrictNum, sub { int });
sub CoercedInt { $CoercedInt }

=pod

=for Pod::Coverage .*

=cut

1;
