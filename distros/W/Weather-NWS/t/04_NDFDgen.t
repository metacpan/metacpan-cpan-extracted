#!perl

use strict;
use warnings;

use Test::More tests => 81;

use Weather::NWS::NDFDgen;

my $LAT = 42;
my $LON = -88;
my $START_TIME = scalar localtime; #now
my $END_TIME = scalar localtime(time + (60*60*24)); #tomorrow

## Create Object

my $NDFDgen = Weather::NWS::NDFDgen->new();
ok($NDFDgen, 'Object creation');

# Get Lists

my @PRODUCTS = $NDFDgen->get_available_products();
ok(@PRODUCTS, 'Fetch product list');

my @W_PARAMS = $NDFDgen->get_available_weather_parameters();
ok(@W_PARAMS, 'Fetch weather parameter list');

## Latitude and Longitude

ok($NDFDgen->set_latitude($LAT)  == $LAT, 'Set latitude' );
ok($NDFDgen->get_latitude()      == $LAT, 'Get latitude' );

ok($NDFDgen->set_longitude($LON) == $LON, 'Set longitude');
ok($NDFDgen->get_longitude()     == $LON, 'Get longitude');

ok($NDFDgen->get_longitude() != $NDFDgen->get_latitude(), 'Cross lat/lon');

## Products

for my $product (@PRODUCTS) {
  ok($NDFDgen->set_product($product) eq $product, "Set $product product");
  ok($NDFDgen->get_product()         eq $product, "Get $product product");
}

eval { $NDFDgen->set_product('Not A Product'); };
ok($@, "Set bogus product");

## Start and End Times

my $st;
ok($st = $NDFDgen->set_start_time($START_TIME), 'Set start time');
ok($NDFDgen->get_start_time() eq $st          , 'Get start time');

my $et;
ok($et = $NDFDgen->set_end_time($END_TIME), 'Set end time');
ok($NDFDgen->get_end_time() eq $et        , 'Get end time');

## Weather Parameters

$NDFDgen->set_weather_parameters();

for my $parameter (@W_PARAMS) {
  my (@arguments, @results);

  # test setting valid values
  for my $value (0, 1) {
    @arguments = ($parameter => $value);
    @results = $NDFDgen->set_weather_parameters(@arguments);
    is_deeply(\@arguments, \@results, "Set $parameter to $value");
  }

  # test setting invalid values
  eval{$NDFDgen->set_weather_parameters($parameter => 2)};
  ok($@, "Set $parameter to 2");
  
  # test getting values
  @results = $NDFDgen->get_weather_parameters($parameter);
  is_deeply(\@results, \@arguments, "Get $parameter");
}

# test getting all parameters back
my %results = $NDFDgen->get_weather_parameters();
is_deeply([sort @W_PARAMS], [sort keys %results], 'Return all parameters');
is_deeply([(1)x@W_PARAMS], [values %results], 'Return valid parameter values');

my %results2 = $NDFDgen->set_weather_parameters(%results);

is_deeply(\%results2, \%results, 'Set all parameters');

eval {
  my $xml = $NDFDgen->get_forecast_xml('Weather Parameters' => {
    'Maximum Temperature'                  => 1,
    'Minimum Temperature'                  => 1,
    '3 Hourly Temperature'                 => 0,
    'Dewpoint Temperature'                 => 0,
    'Apparent Temperature'                 => 0,
    '12 Hour Probability of Precipitation' => 0,
    'Liquid Precipitation Amount'          => 0,
    'Cloud Cover Amount'                   => 0,
    'Snowfall Amount'                      => 0,
    'Wind Speed'                           => 0,
    'Wind Direction'                       => 0,
    'Weather'                              => 0,
    'Wave Height'                          => 0,
    'Weather Icons'                        => 0,
    'Relative Humidity'                    => 0,
  });
};

ok(not($@), "Fetch Data: $@");
