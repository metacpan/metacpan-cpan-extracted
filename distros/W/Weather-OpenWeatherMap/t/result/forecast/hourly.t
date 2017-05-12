use Test::Roo;

sub _build_description { "Testing hourly forecast result" }


use Weather::OpenWeatherMap::Request;
use Weather::OpenWeatherMap::Result;


has request_obj => (
  lazy    => 1,
  is      => 'ro',
  default => sub {
    Weather::OpenWeatherMap::Request->new_for(
      Forecast =>
        api_key  => 'abcd',
        tag      => 'foo',
        location => 'Moscow, Russia',
        hourly   => 1,
        days     => 5,
    )
  },
);

has result_obj => (
  lazy    => 1,
  is      => 'ro',
  default => sub {
    my ($self) = @_;
    Weather::OpenWeatherMap::Result->new_for(
      Forecast =>
        request => $self->request_obj,
        json    => $self->mock_json,
        hourly  => 1,
    )
  },
);

has mock_json => (
  lazy    => 1,
  is      => 'ro',
  default => sub { shift->get_mock_json('hourly') },
);


use lib 't/inc';
with 'Testing::Result::Forecast::Hourly';
run_me;

done_testing
