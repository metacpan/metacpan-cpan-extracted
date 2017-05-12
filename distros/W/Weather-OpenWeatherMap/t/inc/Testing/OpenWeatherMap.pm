package Testing::OpenWeatherMap;


{ package Testing::OWM::Current;
  use Test::Roo;
  has [qw/request_obj result_obj mock_json/] => ( is => 'ro' );
  with 'Testing::Result::Current';
}
{ package Testing::OWM::Forecast;
  use Test::Roo;
  has [qw/request_obj result_obj mock_json/] => ( is => 'ro' );
  with 'Testing::Result::Forecast::Daily';
}
{ package Testing::OWM::Forecast::Hourly;
  use Test::Roo;
  has [qw/request_obj result_obj mock_json/] => ( is => 'ro' );
  with 'Testing::Result::Forecast::Hourly';
}
{ package Testing::OWM::Find;
  use Test::Roo;
  has [qw/request_obj result_obj mock_json/] => ( is => 'ro' );
  with 'Testing::Result::Find';
}


use Weather::OpenWeatherMap;
use Weather::OpenWeatherMap::Test;


use Test::Roo::Role;

has wx => (
  lazy    => 1,
  is      => 'ro',
  writer  => 'set_wx',
  builder => sub {
    Weather::OpenWeatherMap->new(
      api_key => 'foo',
      ua      => mock_http_ua(),
    )
  },
);

test 'api_key' => sub {
  my ($self) = @_;
  cmp_ok $self->wx->api_key, 'eq', 'foo',
    'api_key';
  $self->wx->set_api_key('bar');
  cmp_ok $self->wx->api_key, 'eq', 'bar',
    'set_api_key';
};

test 'retrieve current' => sub {
  my ($self) = @_;
  my $result = $self->wx->get_weather(
    location => 'Manchester, NH',
  );
  Testing::OWM::Current->run_tests( +{
    result_obj  => $result,
    request_obj => $result->request,
    mock_json   => $result->json,
  } );
};

test 'retrieve forecasts' => sub {
  my ($self) = @_;
  my $result = $self->wx->get_weather(
    location => 'Manchester, NH',
    forecast => 1,
    days     => 3,
  );
  Testing::OWM::Forecast->run_tests( +{
    result_obj  => $result,
    request_obj => $result->request,
    mock_json   => $result->json,
  } );

  my $hourly = $self->wx->get_weather(
    location => 'Moscow, Russia',
    forecast => 1,
    hourly   => 1,
  );
  Testing::OWM::Forecast::Hourly->run_tests( +{
    result_obj  => $hourly,
    request_obj => $hourly->request,
    mock_json   => $hourly->json,
  } );
};

test 'retrieve find' => sub {
  my ($self) = @_;
  my $result = $self->wx->get_weather(
    location => 'London, UK',
    find     => 1,
  );
  Testing::OWM::Find->run_tests( +{
    result_obj  => $result,
    request_obj => $result->request,
    mock_json   => $result->json,
  } );
};

test 'caching' => sub {
  my ($self) = @_;
  $self->set_wx(
    Weather::OpenWeatherMap->new(
      api_key => 'foo',
      ua      => mock_http_ua(),
      cache   => 1,
    )
  );

  my $result = $self->wx->get_weather(
    location => 'Manchester, NH',
  );

  ok $self->wx->_cache->is_cached($result->request),
    'result was cached';

  my $cached = $self->wx->get_weather(
    location => 'Manchester, NH',
  );
  Testing::OWM::Current->run_tests( +{
    result_obj  => $cached,
    request_obj => $cached->request,
    mock_json   => $cached->json,
  } );
};

1;
