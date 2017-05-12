package Testing::Result::Cachable;

use Weather::OpenWeatherMap::Cache;

{ package Testing::Result::Cachable::Current;
  use Test::Roo;
  has [qw/request_obj result_obj mock_json/] => ( is => 'ro' );
  with 'Testing::Result::Current';
}

{ package Testing::Result::Cachable::Forecast;
  use Test::Roo;
  has [qw/request_obj result_obj mock_json/] => ( is => 'ro' );
  with 'Testing::Result::Forecast::Daily';
}

{ package Testing::Result::Cachable::Hourly;
  use Test::Roo;
  has [qw/request_obj result_obj mock_json/] => ( is => 'ro' );
  with 'Testing::Result::Forecast::Hourly';
}

{ package Testing::Result::Cachable::Find;
  use Test::Roo;
  has [qw/request_obj result_obj mock_json/] => ( is => 'ro' );
  with 'Testing::Result::Find';
}


use Test::Roo::Role;

requires 'current_result_generator', 
         'forecast_result_generator',
         'find_result_generator',
         'cache_obj';

after each_test => sub {
  my ($self) = @_;
  $self->cache_obj->clear
};


test 'cache bare result' => sub {
  my ($self) = @_;
  my $cache = $self->cache_obj;

  my $current = $self->current_result_generator->();
  isa_ok $current, 'Weather::OpenWeatherMap::Result::Current';

  my $forecast = $self->forecast_result_generator->();
  isa_ok $forecast, 'Weather::OpenWeatherMap::Result::Forecast';
  ok !$forecast->hourly, 'daily forecast !hourly';

  my $hourly = $self->hourly_result_generator->();
  isa_ok $forecast, 'Weather::OpenWeatherMap::Result::Forecast';
  ok $hourly->hourly, 'hourly forecast marked as such';

  my $find = $self->find_result_generator->();
  isa_ok $find, 'Weather::OpenWeatherMap::Result::Find';

  $cache->cache($current);
  $cache->cache($forecast, $find, $hourly);

  my $cached_current  = $cache->retrieve($current->request);
  my $cached_forecast = $cache->retrieve($forecast->request);
  my $cached_hourly   = $cache->retrieve($hourly->request);
  my $cached_find     = $cache->retrieve($find->request);

  Testing::Result::Cachable::Current->run_tests( +{
      result_obj  => $cached_current->object,
      request_obj => $cached_current->object->request,
      mock_json   => $cached_current->object->json,
  } );
  Testing::Result::Cachable::Forecast->run_tests( +{
      result_obj  => $cached_forecast->object,
      request_obj => $cached_forecast->object->request,
      mock_json   => $cached_forecast->object->json,
  } );
  Testing::Result::Cachable::Hourly->run_tests( +{
      result_obj  => $cached_hourly->object,
      request_obj => $cached_hourly->object->request,
      mock_json   => $cached_hourly->object->json,
  } );
  Testing::Result::Cachable::Find->run_tests( +{
      result_obj  => $cached_find->object,
      request_obj => $cached_find->object->request,
      mock_json   => $cached_find->object->json,
  } );
};

test 'cache populated result' => sub {
  my ($self) = @_;
  my $cache = $self->cache_obj;

  my $current = $self->current_result_generator->();
  isa_ok $current, 'Weather::OpenWeatherMap::Result::Current';

  my $forecast = $self->forecast_result_generator->();
  isa_ok $forecast, 'Weather::OpenWeatherMap::Result::Forecast';
  ok !$forecast->hourly, 'daily forecast !hourly';

  my $hourly = $self->hourly_result_generator->();
  isa_ok $hourly, 'Weather::OpenWeatherMap::Result::Forecast';
  ok $hourly->hourly, 'hourly forecast marked as such';

  my $find = $self->find_result_generator->();
  isa_ok $find, 'Weather::OpenWeatherMap::Result::Find';

  # force attr population:
  Testing::Result::Cachable::Current->run_tests( +{
    result_obj  => $current,
    request_obj => $current->request,
    mock_json   => $current->json,
  } );
  Testing::Result::Cachable::Forecast->run_tests( +{
    result_obj  => $forecast,
    request_obj => $forecast->request,
    mock_json   => $forecast->json,
  } );
  Testing::Result::Cachable::Hourly->run_tests( +{
    result_obj  => $hourly,
    request_obj => $hourly->request,
    mock_json   => $hourly->json,
  } );
  Testing::Result::Cachable::Find->run_tests( +{
    result_obj  => $find,
    request_obj => $find->request,
    mock_json   => $find->json,
  } );

  $cache->cache($current, $forecast, $hourly, $find);

  my $cached_current  = $cache->retrieve($current->request);
  my $cached_forecast = $cache->retrieve($forecast->request);
  my $cached_hourly   = $cache->retrieve($hourly->request);
  my $cached_find     = $cache->retrieve($find->request);

  Testing::Result::Cachable::Current->run_tests( +{
      result_obj  => $cached_current->object,
      request_obj => $cached_current->object->request,
      mock_json   => $cached_current->object->json,
  } );
  Testing::Result::Cachable::Forecast->run_tests( +{
      result_obj  => $cached_forecast->object,
      request_obj => $cached_forecast->object->request,
      mock_json   => $cached_forecast->object->json,
  } );
  Testing::Result::Cachable::Hourly->run_tests( +{
      result_obj  => $cached_hourly->object,
      request_obj => $cached_hourly->object->request,
      mock_json   => $cached_hourly->object->json,
  } );
  Testing::Result::Cachable::Find->run_tests( +{
      result_obj  => $cached_find->object,
      request_obj => $cached_find->object->request,
      mock_json   => $cached_find->object->json,
  } ); 
};

test 'cache expiry' => sub {
  my ($self) = @_;
  my $cache = Weather::OpenWeatherMap::Cache->new(
    expiry => '0.5',
  );

  my $current = $self->current_result_generator->();
  isa_ok $current, 'Weather::OpenWeatherMap::Result::Current';

  my $forecast = $self->forecast_result_generator->();
  isa_ok $forecast, 'Weather::OpenWeatherMap::Result::Forecast';

  $cache->cache($current);
  diag "Sleeping 1 second";
  sleep 1;
  ok !$cache->retrieve($current), 'cache expiry on retrieve';

  cmp_ok $cache->cache($current, $forecast), '==', 2, '2 items cached';
  diag "Sleeping 1 second";
  sleep 1;
  cmp_ok $cache->expire, '==', 2, '2 items expired';
};

test 'cache clear' => sub {
  my ($self) = @_;
  my $cache = $self->cache_obj;

  my $current = $self->current_result_generator->();
  isa_ok $current, 'Weather::OpenWeatherMap::Result::Current';

  my $forecast = $self->forecast_result_generator->();
  isa_ok $forecast, 'Weather::OpenWeatherMap::Result::Forecast';

  my $hourly = $self->hourly_result_generator->();
  isa_ok $hourly, 'Weather::OpenWeatherMap::Result::Forecast';

  $cache->cache($current, $forecast, $hourly);
  note "Cache paths: " . join ', ', $cache->cache_paths;

  cmp_ok $cache->clear, '==', 3, 'clear removed 3 items';
  ok !$cache->retrieve($current->request), 'current no longer cached';
  ok !$cache->retrieve($forecast->request), 'forecast no longer cached';
  ok !$cache->retrieve($hourly->request), 'hourly forecast no longer cached';
};


1;
