use Test::Roo;

sub _build_description { "Testing Cache" }

use Weather::OpenWeatherMap::Cache;
use Weather::OpenWeatherMap::Request;
use Weather::OpenWeatherMap::Result;
use Weather::OpenWeatherMap::Test;

has current_result_generator => (
  is      => 'ro',
  builder => sub {
    sub {
      my $req = Weather::OpenWeatherMap::Request->new_for(
        Current =>
          api_key  => 'abcd',
          tag      => 'foo',
          location => 'Manchester, NH',
      );
      Weather::OpenWeatherMap::Result->new_for(
        Current =>
          request => $req,
          json    => get_test_data('current'),
      )
    }
  },
);

has forecast_result_generator => (
  is      => 'ro',
  builder => sub {
    sub {
      my $req = Weather::OpenWeatherMap::Request->new_for(
        Forecast =>
          api_key  => 'abcd',
          tag      => 'foo',
          location => 'Manchester, NH',
      );
      Weather::OpenWeatherMap::Result->new_for(
        Forecast =>
          request => $req,
          json    => get_test_data('3day'),
      )
    }
  },
);

has hourly_result_generator => (
  is      => 'ro',
  builder => sub {
    sub {
      my $req = Weather::OpenWeatherMap::Request->new_for(
        Forecast =>
          api_key  => 'abcd',
          tag      => 'foo',
          location => 'Moscow, RU',
          hourly   => 1,
      );
      Weather::OpenWeatherMap::Result->new_for(
        Forecast =>
          request => $req,
          json    => get_test_data('hourly'),
      )
    }
  },
);

has find_result_generator => (
  is      => 'ro',
  builder => sub {
    sub {
      my $req = Weather::OpenWeatherMap::Request->new_for(
        Find =>
          api_key  => 'abcd',
          tag      => 'foo',
          location => 'London',
          max      => 2,
      );
      Weather::OpenWeatherMap::Result->new_for(
        Find =>
          request => $req,
          json    => get_test_data('find'),
      )
    }
  },
);

has cache_obj => (
  lazy    => 1,
  is      => 'ro',
  builder => sub { Weather::OpenWeatherMap::Cache->new },
);


use lib 't/inc';
with 'Testing::Result::Cachable';

run_me;
done_testing
