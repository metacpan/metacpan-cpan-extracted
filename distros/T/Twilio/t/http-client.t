use 5.016;
use warnings;

use MIME::Base64 qw(decode_base64);
use Test::More;

use Twilio::Http::Client;
use Twilio::Http::FakeClient;
use Twilio::Json;

my $url  = 'https://api.twilio.com/2010-04-01/Accounts.json';
my $http = Twilio::Http::Client->new;

subtest 'query strings' => sub {
  my @cases = (
    ['plain',     { To => '+15558675309' },        'To=%2B15558675309'],
    ['space',     { Body => 'a b' },               'Body=a+b'],
    ['tilde',     { Body => 'a~b' },               'Body=a~b'],
    ['reserved',  { Body => 'a&b=c/d?e' },         'Body=a%26b%3Dc%2Fd%3Fe'],
    ['repeated',  { MediaUrl => ['x', 'y'] },      'MediaUrl=x&MediaUrl=y'],
    ['sorted',    { B => 1, A => 2 },              'A=2&B=1'],
    ['undefined', { A => undef, B => 1 },          'B=1'],
    ['operator',  { 'DateSent>' => '2026-01-01' }, 'DateSent%3E=2026-01-01'],
    ['no params', undef,                           q{}],
  );

  for my $case (@cases) {
    my ($name, $params, $expected) = @{$case};
    is($http->build_query($params), $expected, $name);
  }
};

subtest 'text is sent as UTF-8 however the caller holds it' => sub {
  my @cases = (
    ['characters',                 "\x{263A}",        'Body=%E2%98%BA'],
    ['UTF-8 bytes',                "\xE2\x98\xBA",    'Body=%E2%98%BA'],
    ['latin-1 character',          "\xF1",            'Body=%C3%B1'],
    ['latin-1, upgraded internal', _upgraded("\xF1"), 'Body=%C3%B1'],
  );

  for my $case (@cases) {
    my ($name, $body, $expected) = @{$case};
    is($http->build_query({ Body => $body }), $expected, $name);
  }
};

subtest 'params go in the URL' => sub {
  my $request = $http->prepare_request('GET', $url, { params => { PageSize => 2 } });
  is($request->{url}, "$url?PageSize=2", 'added');

  $request = $http->prepare_request('GET', "$url?Page=1", { params => { PageSize => 2 } });
  is($request->{url}, "$url?Page=1&PageSize=2", 'appended to an existing query');

  $request = $http->prepare_request('GET', $url);
  is($request->{url}, $url, 'left alone without params');
};

subtest 'auth is sent up front' => sub {
  my $request = $http->prepare_request('GET', $url, { username => 'ACxx', password => 's3cret' });
  my ($scheme, $encoded) = split q{ }, $request->{headers}{Authorization};

  is($scheme,                 'Basic',       'scheme');
  is(decode_base64($encoded), 'ACxx:s3cret', 'credentials');

  $request = $http->prepare_request('GET', $url);
  ok(!exists $request->{headers}{Authorization}, 'no header without credentials');

  # Flex Insights takes a token of its own, as an option of the operation.
  $request = $http->prepare_request('GET', $url,
    { username => 'ACxx', password => 's3cret', headers => { Authorization => 'Token abc' } });
  is($request->{headers}{Authorization}, 'Token abc', 'one from the caller is sent instead');
};

subtest 'form bodies' => sub {
  my $request = $http->prepare_request('POST', $url, { data => { To => '+1', Body => 'a b' } });

  is($request->{content},                 'Body=a+b&To=%2B1',                  'encoded');
  is($request->{headers}{'Content-Type'}, 'application/x-www-form-urlencoded', 'default type');
};

subtest 'JSON bodies' => sub {
  my $request = $http->prepare_request(
    'POST', $url,
    {
      data    => { name           => "\x{263A}", list => [1, 2] },
      headers => { 'Content-Type' => 'application/json' },
    }
  );

  is_deeply(
    Twilio::Json::decode($request->{content}),
    { name => "\x{263A}", list => [1, 2] },
    'encoded as UTF-8 JSON'
  );
};

subtest 'only methods with a body get one' => sub {
  for my $method (qw(POST PUT PATCH)) {
    my $request = $http->prepare_request($method, $url, { data => { A => 1 } });
    is($request->{content}, 'A=1', "$method has a body");
  }

  for my $method (qw(GET DELETE HEAD)) {
    my $request = $http->prepare_request($method, $url, { data => { A => 1 } });
    ok(!exists $request->{content}, "$method has no body");
  }
};

subtest 'method and timeout' => sub {
  my $request = $http->prepare_request('get', $url);
  is($request->{method},  'GET', 'method upper-cased');
  is($request->{timeout}, 60,    'default timeout');

  $request = $http->prepare_request('GET', $url, { timeout => 5 });
  is($request->{timeout}, 5, 'request timeout');

  $request = Twilio::Http::Client->new({ timeout => 9 })->prepare_request('GET', $url);
  is($request->{timeout}, 9, 'client timeout');
};

subtest 'the base class has no transport' => sub {
  my $ok = eval { $http->request('GET', $url); 1 };
  ok(!$ok, 'died');
  like($@, qr/must implement send_request/, 'explains why');
};

subtest 'last_request and last_response' => sub {
  my $fake = Twilio::Http::FakeClient->new;
  $fake->mock(200, { sid => 'SM1' });

  my $response = $fake->request('GET', $url);
  is($fake->last_request->{url}, $url,      'last request');
  is($fake->last_response,       $response, 'last response');

  my $ok = eval { $fake->request('GET', "$url?again=1"); 1 };
  ok(!$ok, 'an unmocked request dies');
  is($fake->last_response,       undef,          'no stale response after a failure');
  is($fake->last_request->{url}, "$url?again=1", 'last request still recorded');
};

subtest 'FakeClient answers in order and keeps every request' => sub {
  my $fake = Twilio::Http::FakeClient->new;
  $fake->mock(200, { n => 1 })->mock(404, 'plain text', { 'x-a' => 'b' });

  is_deeply($fake->request('GET', $url)->get_content, { n => 1 }, 'reference encoded as JSON');

  my $missing = $fake->request('GET', $url);
  is($missing->get_status_code, 404,          'mocked status');
  is($missing->get_raw_content, 'plain text', 'string used as it is');
  is_deeply($missing->get_headers, { 'x-a' => 'b' }, 'headers');

  is(scalar(() = $fake->requests), 2, 'both recorded');
};

done_testing;

sub _upgraded {
  my ($text) = @_;
  utf8::upgrade($text);
  return $text;
}
