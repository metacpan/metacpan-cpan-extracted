use 5.016;
use warnings;

use lib 't/lib';

use Test::More;

use Local::Resources;

use Twilio::ApiV1Version;
use Twilio::Exceptions::RestExceptionV1;
use Twilio::Http::Response;
use Twilio::Json;

subtest 'an error in the new shape' => sub {
  my $error = exception_for(
    400,
    {
      code           => 20001,
      message        => 'Invalid name',
      httpStatusCode => 422,
      params         => { field => 'name' },
      userError      => Twilio::Json::decode('true'),
    }
  );

  isa_ok($error, 'Twilio::Exceptions::RestExceptionV1');
  is($error->get_code,             20001, 'code');
  is($error->get_http_status_code, 422,   'status from the body');
  is($error->get_status_code,      422,   'and through the classic name');
  is($error->get_message,          '[HTTP 400] Unable to fetch: Invalid name', 'message');
  is_deeply($error->get_params, { field => 'name' }, 'params');
  is($error->get_user_error, 1, 'user error');
};

subtest 'missing values have defaults' => sub {
  my $error = exception_for(503, {});

  isa_ok($error, 'Twilio::Exceptions::RestExceptionV1');
  is($error->get_code,             503,                          'code from the status');
  is($error->get_http_status_code, 503,                          'status from the response');
  is($error->get_message,          '[HTTP 503] Unable to fetch', 'no text to add');
  is_deeply($error->get_params, {}, 'no params');
  is($error->get_user_error, 0, 'not a user error');
};

subtest 'a false user error' => sub {
  my $error = exception_for(500, { userError => Twilio::Json::decode('false') });
  is($error->get_user_error, 0, 'false');
};

subtest 'it can be caught as a RestException' => sub {
  my $error = exception_for(400, { code => 1 });

  isa_ok($error, 'Twilio::Exceptions::RestException');
  isa_ok($error, 'Twilio::Exceptions::TwilioException');
  is($error->get_more_info, q{}, 'more_info has its default');
};

subtest 'an error in the classic shape' => sub {
  my $error = exception_for(
    404,
    {
      code      => 20404,
      message   => 'Not found',
      more_info => 'https://twilio.test/20404',
      status    => 404
    }
  );

  isa_ok($error, 'Twilio::Exceptions::RestException');
  ok(!$error->isa('Twilio::Exceptions::RestExceptionV1'), 'not the new class');
  is($error->get_code,      20404,                                   'code');
  is($error->get_more_info, 'https://twilio.test/20404',             'more_info');
  is($error->get_message,   '[HTTP 404] Unable to fetch: Not found', 'message');
};

subtest 'either classic key is enough' => sub {
  ok(!exception_for(400, { more_info => q{} })->isa('Twilio::Exceptions::RestExceptionV1'),
    'more_info');
  ok(!exception_for(400, { status => 400 })->isa('Twilio::Exceptions::RestExceptionV1'), 'status');
};

subtest 'a classic key with no value does not count' => sub {
  isa_ok(exception_for(400, { more_info => undef, status => undef }),
    'Twilio::Exceptions::RestExceptionV1');
};

subtest 'a body that is not JSON' => sub {
  my $error = version()->exception(Twilio::Http::Response->new(502, '<html>'), 'Unable to fetch');

  isa_ok($error, 'Twilio::Exceptions::RestExceptionV1');
  is($error->get_code,             502,                          'code');
  is($error->get_http_status_code, 502,                          'status');
  is($error->get_message,          '[HTTP 502] Unable to fetch', 'message');
};

subtest 'the version name' => sub {
  is(version()->get_version, 'v3', 'kept');
};

subtest 'errors reach the caller' => sub {
  my ($http) = Local::Resources::build();
  my $version = Twilio::ApiV1Version->new(Local::Domain->new(client($http)), 'v3');
  $http->mock(400, { code => 7, message => 'No', userError => 1 });

  my $ok    = eval { $version->handle_request('GET', '/Things', 'fetch'); 1 };
  my $error = $@;

  ok(!$ok, 'it dies');
  isa_ok($error, 'Twilio::Exceptions::RestExceptionV1');
  is($error->get_message, '[HTTP 400] Unable to fetch record: No', 'message');
};

done_testing;

sub client {
  my ($http) = @_;
  return Twilio::Rest::Client->new('ACxx', 'secret', { http_client => $http, environment => {} });
}

sub version {
  my ($http) = Local::Resources::build();
  return Twilio::ApiV1Version->new(Local::Domain->new(client($http)), 'v3');
}

sub exception_for {
  my ($status, $content) = @_;
  my $response = Twilio::Http::Response->new($status, Twilio::Json::encode($content));
  return version()->exception($response, 'Unable to fetch');
}
