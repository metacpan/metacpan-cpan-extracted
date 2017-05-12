#####################################################################
#
#  Test suite for 'Weather::Com::Simple'
#
#  Functional tests with 'Test::MockObject'. These could only be run
#  if Test::MockObject is installed.
#
#  Before `make install' is performed this script should be runnable
#  with `make test'. After `make install' it should work as
#  `perl t/Simple.t'
#
#####################################################################
#
# initialization
#
no warnings;
use Data::Dumper;
use Test::More tests => 2;
require 't/TestData.pm';

BEGIN {
	use_ok('Weather::Com::Simple');
}

#####################################################################
#
# Test functionality if Test::MockObject is installed.
#
SKIP: {
	eval { require Test::MockObject; };
	skip( "Test::MockObject not installed", 1 ) if ($@);

	my %weatherargs = (
						'place'    => 'New York/Central Park, NY',
						'debug'    => 0,
						'language' => 'en',
	);

	my $wc = Weather::Com::Simple->new(%weatherargs);

	# define mock object
	my $mock = Test::MockObject->new();
	$mock->fake_module(
		'Weather::Com::Cached' => ( '_cache_time' => sub { return 1110000000 } ) );

	is_deeply( $wc->get_weather, $simpleWeather,
			   'Checking simple weather format.' );
}
