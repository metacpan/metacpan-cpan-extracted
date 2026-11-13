use 5.016;
use warnings;

use Test::More;

# A retry waits with the built-in sleep; this keeps the test from waiting.
BEGIN {
  *CORE::GLOBAL::sleep = sub { return $_[0] };
}

use Twilio::CredentialProvider::ClientCredentialProvider;
use Twilio::Http::FakeClient;
use Twilio::Metadata;
use Twilio::Rest::Client;

my %MESSAGE = (sid => 'SM1', account_sid => 'ACxx', body => 'Hi', status => 'queued');
my %HEADERS = ('content-type' => 'application/json', 'twilio-request-id' => 'RQ1');

subtest 'a create' => sub {
  my ($client, $http) = client();
  $http->mock(201, {%MESSAGE}, {%HEADERS});

  my $answer = $client->messages->with_metadata(create => '+15005550006', { body => 'Hi' });

  isa_ok($answer, 'Twilio::Metadata');
  isa_ok($answer->get_data, 'Twilio::Rest::Api::V2010::Account::MessageInstance', 'the data');
  is($answer->get_data->sid,                   'SM1', 'the record that was created');
  is($answer->get_status_code,                 201,   'the status');
  is($answer->get_header('Twilio-Request-Id'), 'RQ1', 'a header');
  is_deeply($answer->get_headers, \%HEADERS, 'all headers');

  my ($request) = $http->requests;
  is($request->{content}, 'Body=Hi&To=%2B15005550006', 'the arguments reach the operation');
};

subtest 'a fetch, an update and a delete on a context' => sub {
  my ($client, $http) = client();
  my $context = $client->messages('SM1');
  $http->mock(200, {%MESSAGE},                {%HEADERS});
  $http->mock(200, { %MESSAGE, body => q{} }, { 'twilio-request-id' => 'RQ2' });
  $http->mock(204, q{},                       { 'twilio-request-id' => 'RQ3' });

  my $fetched = $context->with_metadata('fetch');
  is($fetched->get_data->body,  'Hi', 'fetch: the record');
  is($fetched->get_status_code, 200,  'fetch: the status');

  my $updated = $context->with_metadata(update => { body => q{} });
  is($updated->get_data->body,                  q{},   'update: the record');
  is($updated->get_header('twilio-request-id'), 'RQ2', 'update: its own header');

  my $deleted = $context->with_metadata('delete');
  is($deleted->get_data,                        1,     'delete: 1');
  is($deleted->get_status_code,                 204,   'delete: the status');
  is($deleted->get_header('Twilio-Request-Id'), 'RQ3', 'delete: its own header');
};

subtest 'a read gives a list of records and the first page answer' => sub {
  my ($client, $http) = client();
  my $next = '/2010-04-01/Accounts/ACxx/Messages.json?PageSize=1&Page=1';
  $http->mock(200, message_page($next, 'SM1'), { 'twilio-request-id' => 'RQ-PAGE-1' });
  $http->mock(200, message_page(undef, 'SM2'), { 'twilio-request-id' => 'RQ-PAGE-2' });

  my $answer = $client->messages->with_metadata(read => {}, undef, 1);

  is(ref $answer->get_data, 'ARRAY', 'an array reference');
  is_deeply([map { $_->sid } @{ $answer->get_data }], [qw(SM1 SM2)], 'of every page');
  is($answer->get_header('Twilio-Request-Id'), 'RQ-PAGE-1', 'the first page answer');
  is(scalar(() = $http->requests),             2,           'two pages');
};

subtest 'a read of one record is still a list' => sub {
  my ($client, $http) = client();
  $http->mock(200, message_page(undef, 'SM1'));

  my $answer = $client->messages->with_metadata(read => {});
  is(ref $answer->get_data,         'ARRAY', 'an array reference');
  is(scalar @{ $answer->get_data }, 1,       'with one record');
};

subtest 'a stream and a page' => sub {
  my ($client, $http) = client();
  $http->mock(200, message_page(undef, 'SM1'), { 'twilio-request-id' => 'RQ-STREAM' });
  $http->mock(200, message_page(undef, 'SM2'), { 'twilio-request-id' => 'RQ-PAGE' });

  my $streamed = $client->messages->with_metadata(stream => {});
  isa_ok($streamed->get_data, 'Twilio::Stream', 'stream');
  is($streamed->get_data->next->sid,             'SM1',       'which starts at the first record');
  is($streamed->get_header('Twilio-Request-Id'), 'RQ-STREAM', 'and has its answer');

  my $paged = $client->messages->with_metadata(page => {});
  isa_ok($paged->get_data, 'Twilio::Page', 'page');
  is($paged->get_header('Twilio-Request-Id'), 'RQ-PAGE', 'with its answer');
};

subtest 'a request repeated after HTTP 429 gives its last answer' => sub {
  my ($client, $http) = client({ max_retries => 1 });
  $http->mock(429, { code => 20429 }, { 'twilio-request-id' => 'RQ-REFUSED' });
  $http->mock(201, {%MESSAGE}, { 'twilio-request-id' => 'RQ-ACCEPTED' });

  my $answer = $client->messages->with_metadata(create => '+15005550006', { body => 'Hi' });
  is($answer->get_status_code,                 201,           'the status');
  is($answer->get_header('Twilio-Request-Id'), 'RQ-ACCEPTED', 'the header');
};

subtest 'an OAuth token request is not the answer' => sub {
  my $http     = Twilio::Http::FakeClient->new;
  my $provider = Twilio::CredentialProvider::ClientCredentialProvider->new(
    { client_id => 'id', client_secret => 'secret' });
  my $client = Twilio::Rest::Client->new(
    undef, undef,
    {
      http_client         => $http,
      credential_provider => $provider,
      account_sid         => 'ACxx',
      environment         => {}
    }
  );
  $http->mock(
    200,
    { access_token        => 'opaque', token_type => 'Bearer', expires_in => 3600 },
    { 'twilio-request-id' => 'RQ-TOKEN' }
  );
  $http->mock(200, {%MESSAGE}, { 'twilio-request-id' => 'RQ-MESSAGE' });

  my $answer = $client->messages('SM1')->with_metadata('fetch');
  is($answer->get_header('Twilio-Request-Id'), 'RQ-MESSAGE', 'the request made');
  is(scalar(() = $http->requests),             2,            'after the token request');
};

subtest 'only the requests of the operation count' => sub {
  my ($client, $http) = client();
  $http->mock(200, {%MESSAGE}, { 'twilio-request-id' => 'RQ-BEFORE' });
  $http->mock(200, {%MESSAGE}, { 'twilio-request-id' => 'RQ-DURING' });
  $http->mock(200, {%MESSAGE}, { 'twilio-request-id' => 'RQ-AFTER' });

  $client->messages('SM1')->fetch;
  my $answer = $client->messages('SM1')->with_metadata('fetch');
  $client->messages('SM1')->fetch;

  is($answer->get_header('Twilio-Request-Id'), 'RQ-DURING', 'not the one before');
  ok(!exists $client->{captured_responses}, 'nothing is recorded afterwards');
};

subtest 'an error answer still throws' => sub {
  my ($client, $http) = client();
  $http->mock(404, { code => 20404, message => 'Not found', status => 404 });

  my $answer = eval { $client->messages('SM1')->with_metadata('fetch') };
  my $error  = $@;
  ok(!$answer, 'no answer');
  isa_ok($error, 'Twilio::Exceptions::RestException', 'the error');
  is($error->get_status_code, 404, 'with the status');
  ok(!exists $client->{captured_responses}, 'and nothing is left recording');
};

subtest 'what is not an operation dies' => sub {
  my ($client) = client();
  my $list = $client->messages;

  my %refused = (
    'no name'           => [],
    'an empty name'     => [q{}],
    'an unknown method' => ['nope'],
    'a private method'  => ['_build_page'],
    'itself'            => ['with_metadata'],
  );
  for my $case (sort keys %refused) {
    my $ok = eval { $list->with_metadata(@{ $refused{$case} }); 1 };
    ok(!$ok, $case);
    like($@, qr/with_metadata (?:needs the name|cannot call)/, "$case: the reason");
  }
};

subtest 'an operation that makes no request dies' => sub {
  my ($client, $http) = client();

  my $ok = eval { $client->messages('SM1')->with_metadata('media'); 1 };
  ok(!$ok, 'a list of a record is not a request');
  like($@, qr/media made no request to Twilio/, 'the reason');
  is(scalar(() = $http->requests), 0, 'nothing was sent');
};

subtest 'get_header' => sub {
  my $answer = Twilio::Metadata->new(1, 200,
    { 'Content-Type' => 'application/json', 'set-cookie' => ['a=1', 'b=2'] });

  is($answer->get_header('content-type'), 'application/json', 'any case');
  is($answer->get_header('Set-Cookie'),   'a=1, b=2',         'one sent twice, joined');
  is($answer->get_header('X-Missing'),    undef,              'a missing one');
  is($answer->get_header(undef),          undef,              'no name');
  is_deeply(Twilio::Metadata->new(1, 200)->get_headers, {}, 'no headers');
};

done_testing;

sub client {
  my ($options) = @_;
  my $http      = Twilio::Http::FakeClient->new;
  my $client    = Twilio::Rest::Client->new('ACxx', 'secret',
    { http_client => $http, environment => {}, %{ $options // {} } });
  return ($client, $http);
}

sub message_page {
  my ($next, @sids) = @_;
  return { messages => [map { +{ %MESSAGE, sid => $_ } } @sids], next_page_uri => $next };
}
