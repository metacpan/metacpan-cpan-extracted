#####################################################################
#
#  Test suite for 'Weather::Com::Base'
#
#  Testing network connection (without proxy).
#  Functional tests with 'Test::MockObject'. These could only be run
#  if Test::MockObject is installed.
#
#  Before `make install' is performed this script should be runnable 
#  with `make test'. After `make install' it should work as 
#  `perl t/Base.t'
#
#####################################################################
#
# initialization
#
no warnings;
use Test::More tests => 6;
require 't/TestData.pm';

BEGIN {
	use_ok('Weather::Com::Base');
}

#####################################################################
#
# Testing object instantiation (do we use the right class)?
#
my %weatherargs = (
					'debug'    => 0,
					'language' => 'en',
);

my $wc = Weather::Com::Base->new(%weatherargs);
isa_ok( $wc, "Weather::Com::Base", 'Is a Weatcher::Com::Base object' );

#
# Test static methods of Weather::Com::Base
#
is( &Weather::Com::Base::celsius2fahrenheit(20),
	68, 'Celsius to Fahrenheit conversion' );
is( &Weather::Com::Base::fahrenheit2celsius(68),
	20, 'Fahrenheit to Celsius conversion' );

# remove all old cache files
unlink <*.dat>;

#
# Test functionality if Test::MockObject is installed.
#
SKIP: {
	eval { require Test::MockObject };
	skip "Test::MockObject not installed", 2 if $@;

	my $mock = Test::MockObject->new();
	$mock->fake_module( 'LWP::UserAgent' =>
					   ( 'request' => sub { return HTTP::Response->new() }, ) );
	$mock->fake_module(
						'HTTP::Response' => (
										   'is_success' => sub { return 1 },
										   'content' => sub { return $NY_HTML },
						)
	);

	is_deeply( $wc->search('Heidelberg'),
			   $NY_Hash, 'Locations search with faked UserAgent' );

	$mock->fake_module(
						'HTTP::Response' => (
										 'is_success' => sub { return 1 },
										 'content' => sub { return $NYCP_HTML },
						)
	);

	is_deeply( $wc->get_weather('USNY0998'),
			   $NYCP_Hash,
			   'Look for weather data for "New York/Central Park, NY"' );
}

