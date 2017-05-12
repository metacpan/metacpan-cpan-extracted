#####################################################################
#
#  Test suite for 'Weather::Com::AirPressure'
#
#  Before `make install' is performed this script should be runnable
#  with `make test'. After `make install' it should work as
#  `perl t/AirPressure.t'
#
#####################################################################
#
# initialization
#
no warnings;
use Test::More tests => 11;

BEGIN {
	use_ok('Weather::Com::AirPressure');
}

#####################################################################
#
# Testing object instantiation (do we use the right class)?
#
my $bar = Weather::Com::AirPressure->new();
isa_ok( $bar, "Weather::Com::AirPressure", 'Right class?' );
isa_ok( $bar, "Weather::Com::Object",      'Right inheritance?' );

#
# Test negative init when instantiated without arguments
#
is( $bar->pressure, -1, 'Test negative initialization of pressure.' );
is( $bar->tendency(), 'unknown', 'Test negative initialization of tendency.' );

#
# Test negative init when instantiated for German
#
$bar = Weather::Com::AirPressure->new( lang => 'de' );
is( $bar->pressure, -1, 'Test negative initialization of pressure.' );
is( $bar->tendency(), 'unbekannt',
	'Test negative initialization of tendency.' );

#
# Test negative update
#
$bar->update( 'r' => undef,
			  'd' => undef, );
is( $bar->pressure, -1, 'Test negative update of pressure.' );
is( $bar->tendency(), 'unbekannt', 'Test negative update of tendency.' );

#
# Test positive update
#
$bar->update(
			  'r' => '1,100',
			  'd' => 'steady'    
);
is( $bar->pressure, '1,100', 'Test update of pressure.' );
is( $bar->tendency(), 'stabil', 'Test update of tendency.' );

