#####################################################################
#
#  Test suite for 'Weather::Com::Wind'
#
#  Before `make install' is performed this script should be runnable
#  with `make test'. After `make install' it should work as
#  `perl t/Wind.t'
#
#####################################################################
#
# initialization
#
no warnings;
use Test::More tests => 25;

BEGIN {
	use_ok('Weather::Com::Wind');
}

#####################################################################
#
# Testing object instantiation (do we use the right class)?
#
my $wind = Weather::Com::Wind->new();
isa_ok( $wind, "Weather::Com::Wind",   'Is a Weatcher::Com::Wind object' );
isa_ok( $wind, "Weather::Com::Object", 'Is a Weatcher::Com::Object object' );

#
# Test negative init when instantiated without arguments
#
is( $wind->speed(),        -1, 'Test negative initialization of speed.' );
is( $wind->maximum_gust(), -1, 'Test negative initialization of speed.' );
is( $wind->direction_degrees(),
	-1, 'Test negative initialization of wind direction.' );
is( $wind->direction_short(),
	'N/A', 'Test negative initialization of wind direction.' );
is( $wind->direction_long(),
	"Not Available",
	'Test negative initialization of wind direction.' );

#
# Test negative init when instantiated for German
#
$wind = Weather::Com::Wind->new( lang => 'de' );
is( $wind->direction_short(),
	'nicht verfügbar',
	'Test negative initialization of wind direction.' );
is( $wind->direction_long(),
	"nicht verfügbar",
	'Test negative initialization of wind direction.' );

#
# Test positive update
#
$wind->update(
			   'gust' => '50',
			   'd'    => '104',
			   's'    => '29',
			   't'    => 'ESE'
);
is( $wind->speed(),             29,           'Test speed update.' );
is( $wind->maximum_gust(),      50,           'Test max gust update.' );
is( $wind->direction_degrees(), 104,          'Test wind direction update.' );
is( $wind->direction_short(),   'OSO',        'Test wind direction update.' );
is( $wind->direction_long(),    "Ost Südost", 'Test wind direction update.' );

#
# Test positive update
#
$wind->update(
			   'gust' => '50',
			   'd'    => '104',
			   's'    => undef,
			   't'    => 'ESE'
);
is( $wind->speed(),        -1, 'Test negative update of speed.' );
is( $wind->maximum_gust(), -1, 'Test negative update of speed.' );
is( $wind->direction_degrees(),	-1, 'Test negative update of wind direction.' );
is( $wind->direction_short(), 'nicht verfügbar', 'Test negative update of wind direction.' );
is( $wind->direction_long(), "nicht verfügbar", 'Test negative update of wind direction.' );

#
# Test calm update
#
$wind->update(
			   'gust' => '50',
			   'd'    => '104',
			   's'    => 'calm',
			   't'    => 'ESE'
);
is( $wind->speed(),        0, 'Test calm update of speed.' );
is( $wind->maximum_gust(), 0, 'Test calm update of speed.' );
is( $wind->direction_degrees(),	-1, 'Test calm update of wind direction.' );
is( $wind->direction_short(), 'nicht verfügbar', 'Test calm update of wind direction.' );
is( $wind->direction_long(), "nicht verfügbar", 'Test calm update of wind direction.' );
