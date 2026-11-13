use 5.016;
use warnings;

use Test::More;

use Twilio::Http::FakeClient;
use Twilio::Rest::Client;

my $api = 'https://api.twilio.com/2010-04-01/Accounts.json';

subtest 'credentials from arguments' => sub {
  my $client = client('ACxx', 'token');

  is($client->get_username,    'ACxx',  'username');
  is($client->get_password,    'token', 'password');
  is($client->get_account_sid, 'ACxx',  'account defaults to the username');
};

subtest 'API key with a separate account' => sub {
  my $client = client('SKxx', 'secret', { account_sid => 'ACxx' });

  is($client->get_username,    'SKxx', 'username');
  is($client->get_account_sid, 'ACxx', 'account');
};

subtest 'settings fall back to the environment' => sub {
  my $client = client(
    undef, undef,
    {
      environment => {
        TWILIO_ACCOUNT_SID => 'ACenv',
        TWILIO_AUTH_TOKEN  => 'tokenenv',
        TWILIO_REGION      => 'au1',
        TWILIO_EDGE        => 'sydney',
        TWILIO_LOG_LEVEL   => 'debug',
      },
    }
  );

  is($client->get_username,    'ACenv',    'username');
  is($client->get_password,    'tokenenv', 'password');
  is($client->get_account_sid, 'ACenv',    'account');
  is($client->get_region,      'au1',      'region');
  is($client->get_edge,        'sydney',   'edge');
  is($client->get_log_level,   'debug',    'log level');
};

subtest 'arguments win over the environment' => sub {
  my $client = client(
    'ACarg', 'token',
    {
      region      => 'ie1',
      edge        => 'dublin',
      environment => { TWILIO_ACCOUNT_SID => 'ACenv', TWILIO_REGION => 'au1', TWILIO_EDGE => 'x' },
    }
  );

  is($client->get_username, 'ACarg',  'username');
  is($client->get_region,   'ie1',    'region');
  is($client->get_edge,     'dublin', 'edge');
};

subtest 'the default transport is TinyClient' => sub {
  my $client = Twilio::Rest::Client->new('ACxx', 'token', { environment => {} });
  isa_ok($client->get_http_client, 'Twilio::Http::TinyClient');
};

subtest 'setters' => sub {
  my $client = client('ACxx', 'token');
  my $other  = Twilio::Http::FakeClient->new;

  $client->set_username('ACnew');
  $client->set_password('new');
  $client->set_account_sid('ACother');
  $client->set_edge('sydney');
  $client->set_log_level('debug');
  $client->set_http_client($other);

  is($client->get_username,    'ACnew',   'username');
  is($client->get_password,    'new',     'password');
  is($client->get_account_sid, 'ACother', 'account');
  is($client->get_edge,        'sydney',  'edge');
  is($client->get_log_level,   'debug',   'log level');
  is($client->get_http_client, $other,    'http client');

  $client->set_edge;
  is($client->get_edge, undef, 'set_edge with no argument unsets it');
};

subtest 'build_uri' => sub {
  my @cases = (
    ['no edge or region', {}, 'https://api.twilio.com/v1/x', 'https://api.twilio.com/v1/x'],
    [
      'region only', { region => 'ie1' },
      'https://api.twilio.com/v1/x', 'https://api.ie1.twilio.com/v1/x'
    ],
    [
      'edge only', { edge => 'sydney' },
      'https://api.twilio.com/v1/x', 'https://api.sydney.us1.twilio.com/v1/x'
    ],
    [
      'edge and region', { edge => 'dublin', region => 'ie1' },
      'https://verify.twilio.com/v2/x', 'https://verify.dublin.ie1.twilio.com/v2/x',
    ],
    [
      'edge keeps a region in the URL', { edge => 'sydney' },
      'https://api.au1.twilio.com/v1', 'https://api.sydney.au1.twilio.com/v1'
    ],
    [
      'region keeps an edge in the URL', { region => 'us2' },
      'https://api.sydney.au1.twilio.com/v1', 'https://api.sydney.us2.twilio.com/v1'
    ],
    [
      'client settings replace the URL', { edge => 'dublin', region => 'ie1' },
      'https://api.sydney.au1.twilio.com/v1', 'https://api.dublin.ie1.twilio.com/v1'
    ],
    [
      'port kept', { region => 'ie1' },
      'https://api.twilio.com:8443/v1', 'https://api.ie1.twilio.com:8443/v1'
    ],
    [
      'query kept', { region => 'ie1' },
      'https://api.twilio.com/v1?a=b.c', 'https://api.ie1.twilio.com/v1?a=b.c'
    ],
    [
      'other hosts left alone', { region => 'ie1' },
      'http://localhost:3000/v1', 'http://localhost:3000/v1'
    ],
  );

  for my $case (@cases) {
    my ($name, $options, $input, $expected) = @{$case};
    is(client('ACxx', 'token', $options)->build_uri($input), $expected, $name);
  }
};

subtest 'request sends the standard headers and credentials' => sub {
  my $client = client('ACxx', 'token');
  $client->get_http_client->mock(200, {});

  $client->request('GET', $api, { params => { PageSize => 1 } });

  my ($request) = $client->get_http_client->requests;
  my $headers = $request->{headers};

  is($request->{url},              "$api?PageSize=1",  'url');
  is($headers->{Accept},           'application/json', 'accept');
  is($headers->{'Accept-Charset'}, 'utf-8',            'charset');
  like($headers->{Authorization}, qr/\ABasic /, 'auth');

  my $version = quotemeta Twilio->VERSION;
  like(
    $headers->{'User-Agent'},
    qr{\Atwilio-perl/$version \(\S.* \S+\) Perl/\d+[.]\d+[.]\d+\z},
    'user agent'
  );
};

subtest 'request details' => sub {
  my $client = client('ACxx', 'token', { user_agent_extensions => ['my-app/1.0', 'x/2'] });
  my $http   = $client->get_http_client;
  $http->mock(204)->mock(200, {})->mock(200, {});

  $client->request('DELETE', $api);
  $client->request('GET',    $api, { headers  => { Accept => 'text/plain' } });
  $client->request('GET',    $api, { username => 'SKother', password => 'pw', timeout => 3 });

  my ($delete, $custom, $override) = $http->requests;

  ok(!exists $delete->{headers}{Accept}, 'DELETE sends no Accept');

  $http->mock(200, {});
  $client->request('GET', $api, { headers => { 'If-Match' => undef, 'Ui-Version' => '2' } });
  my $headers = ($http->requests)[-1]{headers};
  ok(!exists $headers->{'If-Match'}, 'a header option that is not set is left out');
  is($headers->{'Ui-Version'},   '2',          'and one that is set is sent');
  is($custom->{headers}{Accept}, 'text/plain', 'caller Accept kept');
  like($delete->{headers}{'User-Agent'}, qr{ my-app/1[.]0 x/2\z}, 'user agent extensions');
  is($override->{timeout}, 3, 'timeout passed on');
  isnt(
    $override->{headers}{Authorization},
    $delete->{headers}{Authorization},
    'per-request credentials'
  );
};

subtest 'PUT and PATCH send their bodies, as forms or as JSON' => sub {
  my $client = client('ACxx', 'token');
  my $http   = $client->get_http_client;

  for my $method (qw(PUT PATCH)) {
    $http->mock(200, {})->mock(200, {});
    $client->request(lc $method, $api, { data => { Name => 'a b' } });
    $client->request($method, $api,
      { data => { name => 'a' }, headers => { 'Content-Type' => 'application/json' } });
    my ($form, $json) = ($http->requests)[-2, -1];

    is($form->{method},  $method,    "$method, whatever its case");
    is($form->{content}, 'Name=a+b', "$method sends a form");
    is(
      $form->{headers}{'Content-Type'},
      'application/x-www-form-urlencoded',
      "$method says it is a form"
    );
    is($json->{content},         '{"name":"a"}',     "$method sends JSON");
    is($json->{headers}{Accept}, 'application/json', "$method asks for JSON");
  }
};

subtest 'request applies edge and region' => sub {
  my $client = client('ACxx', 'token', { edge => 'sydney', region => 'au1' });
  $client->get_http_client->mock(200, {});

  $client->request('GET', $api);

  my ($request) = $client->get_http_client->requests;
  like($request->{url}, qr{\Ahttps://api[.]sydney[.]au1[.]twilio[.]com/}, 'routed');
};

subtest 'request needs credentials' => sub {
  my @cases =
    ([undef, undef, qr/username is required/], ['ACxx', undef, qr/password is required/],);

  for my $case (@cases) {
    my ($username, $password, $pattern) = @{$case};
    my $client = client($username, $password);

    my $ok    = eval { $client->request('GET', $api); 1 };
    my $error = $@;

    ok(!$ok, 'died');
    isa_ok($error, 'Twilio::Exceptions::ConfigurationException');
    like("$error", $pattern, 'message');
  }
};

subtest 'debug logging never shows credentials' => sub {
  my @enablers = (
    sub { $_[0]->set_log_level('debug') },
    sub { $_[0]{environment} = { DEBUG_HTTP_TRAFFIC => 'true' } },
  );

  for my $enable (@enablers) {
    my $client = client('ACxx', 's3cret-token');
    $client->get_http_client->mock(200, {}, { 'x-request' => 'abc' });
    $enable->($client);

    my @logged;
    local $SIG{__WARN__} = sub { push @logged, @_ };
    $client->request('GET', $api, { params => { PageSize => 1 } });

    my $log = join q{}, @logged;
    like($log, qr/Request Method: GET/,      'logs the method');
    like($log, qr/Query Params: PageSize=1/, 'logs params');
    like($log, qr/Status Code: 200/,         'logs the status');
    like($log, qr/x-request: abc/,           'logs response headers');
    unlike($log, qr/authorization/i, 'no auth header');
    unlike($log, qr/s3cret-token/,   'no token');
  }
};

subtest 'debug logging hides an Authorization header from the caller' => sub {
  my $client = client('ACxx', 'token');
  $client->set_log_level('debug');
  $client->get_http_client->mock(200, {});

  my @logged;
  local $SIG{__WARN__} = sub { push @logged, @_ };
  $client->request('GET', $api, { headers => { Authorization => 'Bearer s3cret-token' } });

  unlike(join(q{}, @logged), qr/s3cret-token/, 'not logged');
};

subtest 'no logging by default' => sub {
  my $client = client('ACxx', 'token');
  $client->get_http_client->mock(200, {});

  my @logged;
  local $SIG{__WARN__} = sub { push @logged, @_ };
  $client->request('GET', $api);

  is_deeply(\@logged, [], 'silent');
};

subtest 'validate_ssl_certificate' => sub {
  my $client = client('ACxx', 'token');
  my $http   = $client->get_http_client;

  $http->mock(200, {});
  ok($client->validate_ssl_certificate, 'success');
  my ($request) = $http->requests;
  is($request->{url}, 'https://tls-test.twilio.com:443', 'test host');

  $http->mock(500, {});
  my $ok    = eval { $client->validate_ssl_certificate; 1 };
  my $error = $@;
  ok(!$ok, 'failure dies');
  isa_ok($error, 'Twilio::Exceptions::TwilioException');
};

done_testing;

sub client {
  my ($username, $password, $options) = @_;
  return Twilio::Rest::Client->new(
    $username,
    $password,
    {
      http_client => Twilio::Http::FakeClient->new,
      environment => {},
      %{ $options // {} },
    }
  );
}
