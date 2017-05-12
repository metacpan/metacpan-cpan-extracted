#####################################################################
#
#  Test suite for the OO Interface
#
#  Functional tests with 'Test::MockObject'. These could only be run
#  if Test::MockObject is installed.
#
#  Before `make install' is performed this script should be runnable
#  with `make test'. After `make install' it should work as
#  `perl t/OOInterface.t'
#
#####################################################################
#
# initialization
#
no warnings;
use Test::More tests => 62;
require 't/TestData.pm';

BEGIN {
	use_ok('Weather::Com::Finder');
}

#####################################################################
#
# Testing object instantiation (do we use the right class)?
#
my %weatherargs = (
					'debug'    => 0,
					'language' => 'en',
);

my $wc = Weather::Com::Finder->new(%weatherargs);
isa_ok( $wc, "Weather::Com::Finder", 'Test class.' );

#
# Test functionality if Test::MockObject is installed.
#
SKIP: {
	eval { require Test::MockObject; };
	skip "Test::MockObject not installed", 60 if $@;

	# define mock object, set cache time to be able to
	# access the cache
	my $mock = Test::MockObject->new();
	$mock->fake_module(
		'Weather::Com::Cached' => ( '_cache_time' => sub { return 1110000000 } ) );

	# test finder method
	my $locations = $wc->find('New York');
	is( @{$locations}, 4, 'Did we get 4 locations?' );

	# test if we have the right 4 location objects
	my @sorted_locations = sort { $a->name() cmp $b->name() } @{$locations};
	isa_ok( $sorted_locations[0], "Weather::Com::Location",
			'Test location class.' );
	isa_ok( $sorted_locations[0], "Weather::Com::Cached",
			'Test location class.' );
	isa_ok( $sorted_locations[0], "Weather::Com::Base",
			'Test location class.' );
	isa_ok( $sorted_locations[1], "Weather::Com::Location",
			'Test location class.' );
	isa_ok( $sorted_locations[1], "Weather::Com::Cached",
			'Test location class.' );
	isa_ok( $sorted_locations[1], "Weather::Com::Base",
			'Test location class.' );
	isa_ok( $sorted_locations[2], "Weather::Com::Location",
			'Test location class.' );
	isa_ok( $sorted_locations[2], "Weather::Com::Cached",
			'Test location class.' );
	isa_ok( $sorted_locations[2], "Weather::Com::Base",
			'Test location class.' );
	isa_ok( $sorted_locations[3], "Weather::Com::Location",
			'Test location class.' );
	isa_ok( $sorted_locations[3], "Weather::Com::Cached",
			'Test location class.' );
	isa_ok( $sorted_locations[3], "Weather::Com::Base",
			'Test location class.' );
	is( $sorted_locations[0]->name(),
		'New York, NY', 'Test for location names.' );
	is(
		$sorted_locations[1]->name(),
		'New York/Central Park, NY',
		'Test for location names.'
	);
	is(
		$sorted_locations[2]->name(),
		'New York/JFK Intl Arpt, NY',
		'Test for location names.'
	);
	is(
		$sorted_locations[3]->name(),
		'New York/La Guardia Arpt, NY',
		'Test for location names.'
	);

	# test data of New York, Central Park
	my $ny = $sorted_locations[1];

	# 1. test units
	isa_ok( $ny->units(), 'Weather::Com::Units', 'Test units class:' );
	is( $ny->units->distance(),      'km',   'Test distance unit.' );
	is( $ny->units->precipitation(), 'mm',   'Test precipitation unit.' );
	is( $ny->units->pressure(),      'mb',   'Test pressure unit.' );
	is( $ny->units->speed(),         'km/h', 'Test speed unit.' );
	is( $ny->units->temperature(),   'C',    'Test temperature unit.' );

	# 2. test timezone
	is( $ny->timezone, '-4', 'Test timezone' );

	# 3. test geographic data
	is( $ny->latitude,  '40.79',  'Test latitude.' );
	is( $ny->longitude, '-73.96', 'Test longitude.' );

	# 4. test date and time objects
	isa_ok( $ny->localtime, 'Weather::Com::DateTime', 'localtime:' );
	isa_ok( $ny->sunrise,   'Weather::Com::DateTime', 'sunrise:' );
	isa_ok( $ny->sunset,    'Weather::Com::DateTime', 'sunset:' );
	is( $ny->sunrise->formatted('hhmm'), '0608', 'Sunrise value.' );
	is( $ny->sunset->formatted('hhmm'),  '1942', 'Sunset value.' );

	# 5. test current conditions
	my $cc = $ny->current_conditions();
	isa_ok( $cc, 'Weather::Com::CurrentConditions', 'current conditions:' );
	is( $cc->id,          $ny->id,   'Test current conditions id.' );
	is( $cc->name,        $ny->name, 'Test current conditions name.' );
	is( $cc->icon,        '34',      'Test current conditions icon.' );
	is( $cc->description, 'fair',    'Test current conditions description.' );
	is( $cc->temperature, '14',      'Test current conditions temperature.' );
	is( $cc->windchill,   '10',      'Test current conditions windchill.' );
	is( $cc->humidity,    '62',      'Test current conditions humidity.' );
	is( $cc->dewpoint,    '7',       'Test current conditions dewpoint.' );
	is( $cc->visibility,  '16.1',    'Test current conditions visibility.' );

	# 5.a test current conditions moon data
	my $cc_moon = $cc->moon;
	isa_ok( $cc_moon, 'Weather::Com::Moon', 'current conditions moon:' );
	is( $cc_moon->icon, '12', 'current conditions moon icon' );
	is( $cc_moon->description,
		'waxing gibbous',
		'current conditions moon description' );

	# 5.b test current conditions barometric pressure data
	my $cc_bar = $cc->pressure;
	isa_ok( $cc_bar, 'Weather::Com::AirPressure',
			'current conditions barom. pressure:' );
	is( $cc_bar->pressure, '1,014.6', 'current conditions pressure (mb)' );
	is( $cc_bar->tendency, 'steady',  'current conditions pressure tendency' );

	# 5.c test current conditions uv index
	my $cc_uv = $cc->uv_index;
	isa_ok( $cc_uv, 'Weather::Com::UVIndex', 'current conditions uv index:' );
	is( $cc_uv->index,       '2',   'current conditions uv index' );
	is( $cc_uv->description, 'low', 'current conditions uv description' );

	# 5.d test current conditions moon data
	my $cc_wind = $cc->wind;
	isa_ok( $cc_wind, 'Weather::Com::Wind', 'current conditions wind:' );
	is( $cc_wind->speed, '19', 'current conditions wind speed' );
	is( $cc_wind->direction_degrees, '160',
		'current conditions wind direction' );

	# 6. test forecasts
	isa_ok( $ny->forecast, 'Weather::Com::Forecast', 'forecast:' );
	my $d3 = $ny->forecast->day(2);
	isa_ok( $d3, 'Weather::Com::DayForecast', 'day forecast:' );
	is( $d3->date->formatted('ddmm'), '2304', "Forecast date." );
	is( $d3->high,                        '18',       'Forecast high temp.' );
	is( $d3->low,                         '11',       'Forecast low temp.' );
	my $night = $d3->night;
	isa_ok( $night, 'Weather::Com::DayPart', 'Test night and day.' );
	is( $night->conditions, 'light rain', 'Test nightly conditions.' );    

}
