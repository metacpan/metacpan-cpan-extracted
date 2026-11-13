use 5.016;
use warnings;

use MIME::Base64 qw(encode_base64url);
use Test::More;

use Twilio::AuthStrategy::AuthStrategy;
use Twilio::AuthStrategy::NoAuthStrategy;
use Twilio::AuthStrategy::TokenAuthStrategy;
use Twilio::CredentialProvider::ClientCredentialProvider;
use Twilio::CredentialProvider::CredentialProvider;
use Twilio::CredentialProvider::NoAuthCredentialProvider;
use Twilio::CredentialProvider::OrgsCredentialProvider;
use Twilio::Http::BearerToken::ApiTokenManager;
use Twilio::Http::BearerToken::TokenManager;
use Twilio::Http::FakeClient;
use Twilio::Json;
use Twilio::Rest::Client;

my $TOKEN_URL = 'https://oauth.twilio.com/v2/token';
my $API_URL   = 'https://api.twilio.com/2010-04-01/Accounts/ACxx.json';
my $HOUR      = 3600;

subtest 'a provider needs a client id and secret' => sub {
  for my $case (
    ['no options',   undef, 'client_id is required'],
    ['no secret',    { client_id => 'OQxx' },                         'client_secret is required'],
    ['an empty id',  { client_id => q{}, client_secret => 'secret' }, 'client_id is required'],
    ['no id at all', { client_secret => 'secret' },                   'client_id is required'],
    )
  {
    my ($name, $options, $message) = @{$case};
    my $ok    = eval { Twilio::CredentialProvider::ClientCredentialProvider->new($options); 1 };
    my $error = $@;
    ok(!$ok, "$name dies");
    isa_ok($error, 'Twilio::Exceptions::ConfigurationException');
    is($error->get_message, $message, 'and says what is missing') if ref $error;
  }
};

subtest 'what a provider holds' => sub {
  my $provider = provider();
  is($provider->get_auth_type, 'client-credentials', 'auth type');
  is($provider->get_client_id, 'OQxx',               'client id');
  isa_ok($provider->get_token_manager, 'Twilio::Http::BearerToken::ApiTokenManager');

  my $strategy = $provider->to_auth_strategy;
  isa_ok($strategy, 'Twilio::AuthStrategy::TokenAuthStrategy');
  is($strategy->get_auth_type, 'token', 'strategy type');
  ok($strategy->requires_authentication, 'a token is required');
  is($provider->to_auth_strategy, $strategy, 'the same strategy each time, so the token is kept');

  my $orgs = Twilio::CredentialProvider::OrgsCredentialProvider->new(
    { client_id => 'OQxx', client_secret => 'secret' });
  isa_ok($orgs->get_token_manager, 'Twilio::Http::BearerToken::OrgsTokenManager');
  is($orgs->get_auth_type, 'client-credentials', 'an Organization app has the same type');

  my $mine = Local::TokenManager->new(jwt($HOUR));
  is(provider({ token_manager => $mine })->get_token_manager, $mine, 'a token manager of my own');
};

subtest 'the first request asks for a token' => sub {
  my ($client, $http) = oauth_client();
  my $token = jwt($HOUR);
  $http->mock(200, token_answer($token))->mock(200, { sid => 'ACxx' });

  my $account = $client->api->v2010->accounts('ACxx')->fetch;
  my ($token_request, $api_request) = $http->requests;

  is($account->sid,            'ACxx',     'the answer to the request');
  is($token_request->{method}, 'POST',     'the token is created');
  is($token_request->{url},    $TOKEN_URL, 'at the OAuth endpoint');
  is(
    $token_request->{content},
    'client_id=OQxx&client_secret=secret&grant_type=client_credentials',
    'with the client credentials grant'
  );
  is(authorization($token_request), undef,           'with no credentials of its own');
  is($api_request->{url},           $API_URL,        'then the request');
  is(authorization($api_request),   "Bearer $token", 'with the token');
};

subtest 'the token is kept until it is about to expire' => sub {
  my ($client, $http) = oauth_client();
  my $token = jwt($HOUR);
  $http->mock(200, token_answer($token));
  $http->mock(200, {}) for 1 .. 3;

  $client->request('GET', $API_URL) for 1 .. 3;
  my @requests = $http->requests;

  is(scalar @requests, 4, 'one token for three requests');
  is_deeply([map { authorization($_) } @requests[1 .. 3]], [("Bearer $token") x 3], 'all with it');
};

subtest 'a token about to expire is replaced' => sub {
  my ($client, $http)  = oauth_client();
  my ($soon,   $later) = (jwt(20), jwt($HOUR));
  $http->mock(200, token_answer($soon))->mock(200, {});
  $http->mock(200, token_answer($later))->mock(200, {})->mock(200, {});

  $client->request('GET', $API_URL) for 1 .. 3;
  my @requests = $http->requests;

  is(scalar @requests,  5, 'a second token after the first one, which expires within 30 seconds');
  is($requests[2]{url}, $TOKEN_URL, 'asked for before the second request');
  is_deeply(
    [map { authorization($_) } @requests[1, 3, 4]],
    ["Bearer $soon", "Bearer $later", "Bearer $later"],
    'and used from then on'
  );
};

subtest 'when a token expires' => sub {
  my $strategy = Twilio::AuthStrategy::TokenAuthStrategy->new;
  my $now      = time;
  my @cases    = (
    ['an hour left',               jwt($HOUR),                                     0],
    ['a minute left',              jwt(60),                                        0],
    ['29 seconds left',            jwt(29),                                        1],
    ['already expired',            jwt(-$HOUR),                                    1],
    ['an exp with decimals',       jwt_with({ exp => ($now + $HOUR) . '.5' }),     0],
    ['no exp',                     jwt_with({ sub => 'OQxx' }),                    1],
    ['an exp that is text',        jwt_with({ exp => 'tomorrow' }),                1],
    ['an exp that is a list',      jwt_with({ exp => [$now + $HOUR] }),            1],
    ['a payload that is not JSON', 'e30.' . encode_base64url('not json') . '.sig', 1],
    ['a payload that is a list',   'e30.' . encode_base64url('[1]') . '.sig',      1],
    ['not a JWT',                  'opaque-token',                                 1],
    ['empty',                      q{},                                            1],
    ['nothing',                    undef,                                          1],
  );
  for my $case (@cases) {
    my ($name, $token, $expired) = @{$case};
    is($strategy->is_token_expired($token), $expired, $name);
  }
};

subtest 'a token whose expiry cannot be read is asked for again' => sub {
  my ($client, $http) = oauth_client();
  $http->mock(200, token_answer('opaque'))->mock(200, {});
  $http->mock(200, token_answer('opaque'))->mock(200, {});

  $client->request('GET', $API_URL) for 1 .. 2;

  is(scalar(grep { $_->{url} eq $TOKEN_URL } $http->requests), 2, 'a token for each request');
};

subtest 'a refused token request reaches the caller' => sub {
  my ($client, $http) = oauth_client();
  $http->mock(401, { code => 70002, message => 'Invalid client', more_info => 'https://x' });

  my $ok    = eval { $client->api->v2010->accounts('ACxx')->fetch; 1 };
  my $error = $@;

  ok(!$ok, 'dies');
  isa_ok($error, 'Twilio::Exceptions::RestException');
  is($error->get_status_code,      401,   'with the status')   if ref $error;
  is($error->get_code,             70002, "and Twilio's code") if ref $error;
  is(scalar(() = $http->requests), 1,     'and the request is not sent');

  $http->mock(200, token_answer(jwt($HOUR)))->mock(200, { sid => 'ACxx' });
  is($client->api->v2010->accounts('ACxx')->fetch->sid, 'ACxx', 'the next request tries again');
};

subtest 'an answer without a token' => sub {
  for my $answer ({ token_type => 'Bearer' }, { access_token => q{} }) {
    my ($client, $http) = oauth_client();
    $http->mock(200, $answer);

    my $ok    = eval { $client->request('GET', $API_URL); 1 };
    my $error = $@;
    ok(!$ok, 'dies');
    isa_ok($error, 'Twilio::Exceptions::TwilioException');
    like(ref $error ? $error->get_message : $error, qr/no OAuth access token/, 'and says why');
    is(scalar(() = $http->requests), 1, 'and the request is not sent');
  }
};

subtest 'a provider replaces the username and password' => sub {
  my $client = Twilio::Rest::Client->new(
    undef, undef,
    {
      http_client         => Twilio::Http::FakeClient->new,
      credential_provider => provider(),
      environment         => { TWILIO_ACCOUNT_SID => 'ACenv', TWILIO_AUTH_TOKEN => 'token' },
    }
  );

  is($client->get_username,    undef,   'no username');
  is($client->get_password,    undef,   'no password');
  is($client->get_account_sid, 'ACenv', 'the account still comes from the environment');

  my ($with_account) = oauth_client({ account_sid => 'ACmine' });
  is($with_account->get_account_sid, 'ACmine', 'or from the account_sid option');
};

subtest 'account resources use the account SID' => sub {
  my ($client, $http) = oauth_client({ account_sid => 'ACmine' });
  $http->mock(200, token_answer(jwt($HOUR)))->mock(201, { sid => 'SMxx' });

  $client->messages->create('+15558675309', { from => '+15017250604', body => 'Hello' });
  my (undef, $request) = $http->requests;

  is($request->{url}, 'https://api.twilio.com/2010-04-01/Accounts/ACmine/Messages.json', 'the URL');
};

subtest 'account resources without an account SID' => sub {
  my ($client, $http) = oauth_client();

  my $ok = eval { $client->messages->create('+15558675309', { from => '+15017250604' }); 1 };
  ok(!$ok, 'die');
  like($@, qr/set the client's account_sid/, 'and say what to set');
  is(scalar(() = $http->requests), 0, 'before any request');
};

subtest 'a username and password given again win' => sub {
  my ($client, $http) = oauth_client();
  $http->mock(200, {})->mock(200, {});

  $client->request('GET', $API_URL, { username => 'SKxx', password => 'secret' });
  $client->set_username('ACxx');
  $client->set_password('token');
  $client->request('GET', $API_URL);
  my @requests = $http->requests;

  is(scalar @requests, 2, 'no token is asked for');
  like(authorization($requests[0]), qr/\ABasic /, 'for one request');
  like(authorization($requests[1]), qr/\ABasic /, 'or for the client');
};

subtest 'only a username or a password is not enough to skip the token' => sub {
  my ($client, $http) = oauth_client();
  my $token = jwt($HOUR);
  $http->mock(200, token_answer($token))->mock(200, {});

  $client->request('GET', $API_URL, { username => 'SKxx' });
  my (undef, $request) = $http->requests;

  is(authorization($request), "Bearer $token", 'the token is sent');
};

subtest "the caller's Authorization header is sent instead" => sub {
  my ($client, $http) = oauth_client();
  $http->mock(200, {});

  $client->request('GET', $API_URL, { headers => { authorization => 'Token flex' } });
  my @requests = $http->requests;

  is(scalar @requests,                     1,            'no token is asked for');
  is($requests[0]{headers}{authorization}, 'Token flex', 'the header given');
  ok(!exists $requests[0]{headers}{Authorization}, 'and no other');
};

subtest 'invalidate_oauth and invalidate_basic_auth' => sub {
  my ($client) = oauth_client();
  $client->invalidate_oauth;
  is($client->get_credential_provider, undef, 'no provider');

  my $ok    = eval { $client->request('GET', $API_URL); 1 };
  my $error = $@;
  ok(!$ok, 'so a request needs credentials again');
  is(ref $error ? $error->get_message : $error, 'username is required', 'and says so');

  my $basic = Twilio::Rest::Client->new('ACxx', 'token', { environment => {} });
  $basic->invalidate_basic_auth;
  is($basic->get_username,    undef,  'no username');
  is($basic->get_password,    undef,  'no password');
  is($basic->get_account_sid, 'ACxx', 'the account is kept');
};

subtest 'set_credential_provider' => sub {
  my $http = Twilio::Http::FakeClient->new;
  my $client =
    Twilio::Rest::Client->new('ACxx', 'token', { http_client => $http, environment => {} });
  my $provider = provider();

  $client->set_credential_provider($provider);

  is($client->get_credential_provider, $provider, 'set');
  is($client->get_username,            undef,     'the username is cleared, as in twilio-php');
  is($client->get_account_sid,         'ACxx',    'the account is kept');

  for my $value (undef, 'provider', {}, Twilio::Http::FakeClient->new) {
    my $ok    = eval { $client->set_credential_provider($value); 1 };
    my $error = $@;
    ok(!$ok, 'something else is refused');
    isa_ok($error, 'Twilio::Exceptions::ConfigurationException');
  }
  is($client->get_credential_provider, $provider, 'and changes nothing');

  my $ok = eval {
    Twilio::Rest::Client->new(undef, undef, { credential_provider => 'x', environment => {} });
    1;
  };
  ok(!$ok, 'the constructor checks it too');
};

subtest 'clients that share a provider share its token' => sub {
  my $provider = provider();
  my $http     = Twilio::Http::FakeClient->new;
  my @clients  = map {
    Twilio::Rest::Client->new(undef, undef,
      { http_client => $http, credential_provider => $provider, environment => {} })
  } 1 .. 2;
  $http->mock(200, token_answer(jwt($HOUR)))->mock(200, {})->mock(200, {});

  $_->request('GET', $API_URL) for @clients;

  is(scalar(grep { $_->{url} eq $TOKEN_URL } $http->requests), 1, 'one token');
};

subtest 'the token request uses the settings of the client' => sub {
  my ($client, $http) = oauth_client({ edge => 'sydney', region => 'au1', max_retries => 1 });
  $http->mock(429, {}, { 'retry-after' => 0 })->mock(200, token_answer(jwt($HOUR)));
  $http->mock(200, {});

  $client->request('GET', $API_URL);
  my @requests = $http->requests;

  is($requests[0]{url}, 'https://oauth.sydney.au1.twilio.com/v2/token', 'edge and region');
  is($requests[1]{url}, $requests[0]{url},                              'retries');
  like($requests[0]{headers}{'User-Agent'}, qr/\Atwilio-perl/, 'the standard headers');
};

subtest 'a retried request keeps its token' => sub {
  my ($client, $http) = oauth_client({ max_retries => 1 });
  my $token = jwt($HOUR);
  $http->mock(200, token_answer($token))->mock(429, {}, { 'retry-after' => 0 })->mock(200, {});

  my $response = $client->request('GET', $API_URL);
  my @requests = $http->requests;

  is($response->get_status_code,  200,             'retried');
  is(scalar @requests,            3,               'with no second token');
  is(authorization($requests[2]), "Bearer $token", 'and the same one');
};

subtest 'debug logs show neither the token nor the secret' => sub {
  my ($client, $http) = oauth_client();
  my $token = jwt($HOUR);
  $client->set_log_level('debug');
  $http->mock(200, token_answer($token))->mock(200, {});

  my @logged;
  {
    local $SIG{__WARN__} = sub { push @logged, @_ };
    $client->request('GET', $API_URL);
  }
  my $log = join q{}, @logged;

  like($log, qr/Request URL: \Q$TOKEN_URL\E/, 'the token request is logged');
  like($log, qr/Request URL: \Q$API_URL\E/,   'and the request');
  unlike($log, qr/\Q$token\E/, 'without the token');
  unlike($log, qr/secret/,     'or the secret');
};

subtest 'a token manager of my own' => sub {
  my $token   = jwt($HOUR);
  my $manager = Local::TokenManager->new($token);
  my ($client, $http) = oauth_client({}, provider({ token_manager => $manager }));
  $http->mock(200, {});

  $client->request('GET', $API_URL);
  my @requests = $http->requests;

  is(scalar @requests,            1,               'Twilio is not asked');
  is(authorization($requests[0]), "Bearer $token", 'the token is sent');
  is($manager->{clients}[0],      $client,         'the token manager gets the client');
};

subtest 'an Organization app asks the same endpoint' => sub {
  my $provider = Twilio::CredentialProvider::OrgsCredentialProvider->new(
    { client_id => 'OQxx', client_secret => 'secret' });
  my ($client, $http) = oauth_client({}, $provider);
  my $token = jwt($HOUR);
  $http->mock(200, token_answer($token))->mock(200, {});

  $client->request('GET', 'https://preview-iam.twilio.com/Organizations/OOxx/scim/Users');
  my ($token_request, $request) = $http->requests;

  is($token_request->{url},   $TOKEN_URL,      'the token');
  is(authorization($request), "Bearer $token", 'is sent');
};

subtest 'a token manager on its own' => sub {
  my $http = Twilio::Http::FakeClient->new;
  my $client =
    Twilio::Rest::Client->new('ACxx', 'token', { http_client => $http, environment => {} });
  my $manager = Twilio::Http::BearerToken::ApiTokenManager->new(
    {
      client_id     => 'OQxx',
      client_secret => 'secret',
      scope         => 'offline_access',
      audience      => 'https://api.twilio.com',
    }
  );
  $http->mock(200, token_answer('abc'));

  is($manager->fetch_token($client), 'abc', 'returns the token');
  my ($request) = $http->requests;
  is(
    $request->{content},
    'audience=https%3A%2F%2Fapi.twilio.com&client_id=OQxx&client_secret=secret'
      . '&grant_type=client_credentials&scope=offline_access',
    'and sends every option given'
  );
  is(authorization($request), undef, "without the client's own credentials");
};

subtest 'no credentials at all' => sub {
  my $http   = Twilio::Http::FakeClient->new;
  my $client = Twilio::Rest::Client->new(
    undef, undef,
    {
      http_client         => $http,
      credential_provider => Twilio::CredentialProvider::NoAuthCredentialProvider->new,
      environment         => {},
    }
  );
  $http->mock(200, {});

  $client->request('GET', $API_URL);
  my ($request) = $http->requests;

  is(authorization($request),                         undef,    'no Authorization header');
  is($client->get_credential_provider->get_auth_type, 'noauth', 'auth type');

  my $strategy = Twilio::AuthStrategy::NoAuthStrategy->new;
  is($strategy->get_auth_type,   'noauth', 'strategy type');
  is($strategy->get_auth_string, q{},      'an empty header');
  ok(!$strategy->requires_authentication, 'nothing is required');
};

subtest 'base classes must be extended' => sub {
  for my $case (
    [Twilio::AuthStrategy::AuthStrategy->new('x'),             'get_auth_string'],
    [Twilio::AuthStrategy::AuthStrategy->new('x'),             'requires_authentication'],
    [Twilio::CredentialProvider::CredentialProvider->new('x'), 'to_auth_strategy'],
    [Twilio::Http::BearerToken::TokenManager->new,             'fetch_token'],
    )
  {
    my ($object, $method) = @{$case};
    my $ok = eval { $object->$method; 1 };
    ok(!$ok, ref($object) . "->$method dies");
    like($@, qr/must implement \Q$method\E/, 'and says what to write');
  }
};

done_testing;

sub provider {
  my ($options) = @_;
  return Twilio::CredentialProvider::ClientCredentialProvider->new(
    { client_id => 'OQxx', client_secret => 'secret', %{ $options // {} } });
}

sub oauth_client {
  my ($options, $provider) = @_;
  my $http   = Twilio::Http::FakeClient->new;
  my $client = Twilio::Rest::Client->new(
    undef, undef,
    {
      http_client         => $http,
      credential_provider => $provider // provider(),
      environment         => {},
      %{ $options // {} },
    }
  );
  return ($client, $http);
}

sub jwt {
  my ($seconds_left) = @_;
  return jwt_with({ exp => time + $seconds_left, sub => 'OQxx' });
}

sub jwt_with {
  my ($claims) = @_;
  return join q{.}, map { encode_base64url(Twilio::Json::encode($_)) } { alg => 'RS256' }, $claims,
    'signature';
}

sub token_answer {
  my ($token) = @_;
  return { access_token => $token, token_type => 'Bearer', expires_in => $HOUR };
}

sub authorization {
  my ($request) = @_;
  my ($name)    = grep { lc eq 'authorization' } keys %{ $request->{headers} };
  return defined $name ? $request->{headers}{$name} : undef;
}

package Local::TokenManager;

use parent -norequire, 'Twilio::Http::BearerToken::TokenManager';

sub new {
  my ($class, $token) = @_;
  return bless { token => $token, clients => [] }, $class;
}

sub fetch_token {
  my ($self, $client) = @_;
  push @{ $self->{clients} }, $client;
  return $self->{token};
}
