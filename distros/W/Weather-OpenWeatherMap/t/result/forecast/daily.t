use Test::Roo;

sub _build_description { "Testing 3-day forecast result" }


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
        location => 'Manchester, NH',
        days     => 3,
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
    )
  },
);

has mock_json => (
  lazy    => 1,
  is      => 'ro',
  default => sub { shift->get_mock_json('3day') },
);


use lib 't/inc';
with 'Testing::Result::Forecast::Daily';
run_me;


done_testing
