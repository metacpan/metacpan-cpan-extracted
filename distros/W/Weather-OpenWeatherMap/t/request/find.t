use Test::Roo;

use Weather::OpenWeatherMap::Request;

has request_obj => (
  is      => 'ro',
  builder => sub {
    Weather::OpenWeatherMap::Request->new_for(
      Find =>
        api_key  => 'abcd',
        tag      => 'foo',
        location => 'London',
        max      => 2, 
    )
  },
);

has request_obj_bycoord => (
  is      => 'ro',
  builder => sub {
    Weather::OpenWeatherMap::Request->new_for(
      Find =>
        api_key  => 'abcd',
        tag      => 'foo',
        # Totally wrong for our test data, but whatever
        location => 'lat 41.51, long -0.12',
    );
  },
);


use lib 't/inc';
with 'Testing::Request::Find';
run_me;

done_testing
