use Test::Roo;

sub _build_description { "Testing current weather result" }


use Weather::OpenWeatherMap::Request;
use Weather::OpenWeatherMap::Result;


has request_obj => (
  lazy    => 1,
  is      => 'ro',
  default => sub {
    Weather::OpenWeatherMap::Request->new_for(
      Current =>
        api_key  => 'abcd',
        tag      => 'foo',
        location => 'Manchester, NH',
    )
  },
);

has result_obj => (
  lazy    => 1,
  is      => 'ro',
  default => sub {
    my ($self) = @_;
    Weather::OpenWeatherMap::Result->new_for(
      Current =>
        request => $self->request_obj,
        json    => $self->mock_json,
    )
  },
);

has mock_json => (
  lazy    => 1,
  is      => 'ro',
  default => sub { shift->get_mock_json('current') },
);


use lib 't/inc';
with 'Testing::Result::Current';
run_me;


done_testing
