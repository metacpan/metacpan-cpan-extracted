use Test::Roo;

use Weather::OpenWeatherMap::Request;

has request_obj => (
  is        => 'ro',
  builder   => sub {
    Weather::OpenWeatherMap::Request->new_for(
      Current =>
        api_key  => 'abcd',
        tag      => 'foo',
        location => 'Manchester, NH',
    )
  },
);

has request_obj_bycoord => (
  is        => 'ro',
  builder   => sub {
    Weather::OpenWeatherMap::Request->new_for(
      Current =>
        api_key  => 'abcd',
        tag      => 'foo',
        location => 'lat 42, long 24',
    )
  },
);

has request_obj_bycode => (
  is        => 'ro',
  builder   => sub {
    Weather::OpenWeatherMap::Request->new_for(
      Current =>
        api_key  => 'abcd',
        tag      => 'foo',
        location => 5089178,
    )
  },
);


use lib 't/inc';
with 'Testing::Request::Current';
run_me;

{ my $warning;
  local $SIG{__WARN__} = sub {
    $warning = shift
  };
  my $req = Weather::OpenWeatherMap::Request->new_for(
    Current =>
      location => 'Manchester, NH',
  );
  fail "new Request without api_key should have warned"
    unless $warning;
  like $warning, qr/api_key/, "Request without api_key warned ok";
}


done_testing
