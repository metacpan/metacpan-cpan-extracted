use Test::Roo;

use Weather::OpenWeatherMap::Request;

has request_obj => (
  is        => 'ro',
  builder   => sub {
    Weather::OpenWeatherMap::Request->new_for(
      Forecast =>
        api_key  => 'abcd',
        hourly   => 1,
        tag      => 'foo',
        location => 'Manchester, NH',
    )
  },
);

has request_obj_bycoord => (
  is        => 'ro',
  builder   => sub {
    Weather::OpenWeatherMap::Request->new_for(
      Forecast =>
        api_key  => 'abcd',
        hourly   => 1,
        tag      => 'foo',
        location => 'lat 42, long 24',
    )
  },
);

has request_obj_bycode => (
  is        => 'ro',
  builder   => sub {
    Weather::OpenWeatherMap::Request->new_for(
      Forecast =>
        api_key  => 'abcd',
        hourly   => 1,
        tag      => 'foo',
        location => 5089178,
    )
  },
);


use lib 't/inc';
with 'Testing::Request::Forecast';
run_me;

done_testing
