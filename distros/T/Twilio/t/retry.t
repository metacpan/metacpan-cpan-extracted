use 5.016;
use warnings;

use Test::More;

# Replaces the built-in, not a method of the client, so these tests run the code that really
# waits, and a retry that stopped waiting would fail them. It must be set before the client
# is compiled.
my @waits;

BEGIN {
  *CORE::GLOBAL::sleep = sub {
    push @waits, $_[0];
    return $_[0];
  };
}

use Twilio::Http::FakeClient;
use Twilio::Http::File;
use Twilio::Rest::Client;

my $URL = 'https://api.twilio.com/2010-04-01/Accounts.json';

subtest 'nothing is retried by default' => sub {
  my $client = client();
  my $http   = $client->get_http_client;
  $http->mock(429, { code => 20429 });

  my $response = $client->request('GET', $URL);

  is($client->get_max_retries,     0,   'the default is no retries');
  is($response->get_status_code,   429, 'the 429 is returned');
  is(scalar(() = $http->requests), 1,   'one request');
  is_deeply([@waits], [], 'no waiting');
};

subtest 'a 429 is retried when enabled' => sub {
  my $client = client(1);
  my $http   = $client->get_http_client;
  $http->mock(429, {})->mock(200, { ok => 1 });

  my $response = $client->request('POST', $URL, { data => { Body => 'Hello' } });
  my @requests = $http->requests;

  is($response->get_status_code, 200,                   'the second response is returned');
  is(scalar @requests,           2,                     'two requests');
  is($requests[0]{content},      'Body=Hello',          'the body');
  is($requests[1]{content},      $requests[0]{content}, 'the same body is sent again');
  ok($requests[1]{headers}{Authorization}, 'the retry is authenticated');
  is_deeply([@waits], [1], 'waited before retrying');
};

subtest 'a retried upload sends the file again' => sub {
  my $client = client(1);
  my $http   = $client->get_http_client;
  $http->mock(429, {})->mock(200, {});

  open my $handle, '<', \'the document' or die "Cannot open an in-memory file: $!\n";
  my $file = Twilio::Http::File->new('id.pdf', $handle);
  $client->request('POST', $URL, { data => { File => $file } });
  close $handle or die "Cannot close an in-memory file: $!\n";
  my @requests = $http->requests;

  like($requests[0]{content}, qr/\r\n\r\nthe document\r\n/, 'the file');
  is(
    $requests[1]{content} =~ s/twilio-[0-9a-f]+/BOUNDARY/gr,
    $requests[0]{content} =~ s/twilio-[0-9a-f]+/BOUNDARY/gr,
    'the same file is sent again, from a filehandle read once'
  );
};

subtest 'a retried create returns the resource' => sub {
  my $client = client(1);
  my $http   = $client->get_http_client;
  $http->mock(429, {})->mock(201, { sid => 'SMxx', body => 'Hello' });

  my $message = $client->messages->create('+15558675309', { from => '+15017250604' });

  is($message->sid, 'SMxx', 'the instance comes from the retry');
};

subtest 'the number of attempts has a limit' => sub {
  my $client = client(2);
  my $http   = $client->get_http_client;
  $http->mock(429, { attempt => 1 })->mock(429, { attempt => 2 })->mock(429, { attempt => 3 });
  $http->mock(200, {});

  my $response = $client->request('GET', $URL);

  is(scalar(() = $http->requests),      3,   'the first request and two retries');
  is($response->get_status_code,        429, 'the status of the last response');
  is($response->get_content->{attempt}, 3,   'the last response is returned');
  is_deeply([@waits], [1, 2], 'no wait after the last attempt');
};

subtest 'the wait doubles up to a limit' => sub {
  my $client = client(8);
  my $http   = $client->get_http_client;
  $http->mock(429, {}) for 1 .. 9;

  $client->request('GET', $URL);

  is_deeply([@waits], [1, 2, 4, 8, 16, 32, 60, 60], 'waits');
};

subtest 'Retry-After sets the wait' => sub {
  for my $case (
    ['lower case header',   'retry-after', 7,     7],
    ['usual header case',   'Retry-After', 7,     7],
    ['spaces in the value', 'retry-after', ' 7 ', 7],
    ['no wait at all',      'retry-after', 0,     0],
    ['the longest wait',    'retry-after', 60,    60],
    )
  {
    my ($name, $header, $value, $expected) = @{$case};
    my $client = client(1);
    my $http   = $client->get_http_client;
    $http->mock(429, {}, { $header => $value })->mock(200, {});

    my $response = $client->request('GET', $URL);

    is($response->get_status_code, 200, "$name: retried");
    is_deeply([@waits], [$expected], "$name: waited");
  }
};

subtest 'a long Retry-After is left to the caller' => sub {
  my $client = client(3);
  my $http   = $client->get_http_client;
  $http->mock(429, {}, { 'retry-after' => 61 })->mock(200, {});

  my $response = $client->request('GET', $URL);

  is($response->get_status_code,   429, 'the 429 is returned');
  is(scalar(() = $http->requests), 1,   'no retry');
  is_deeply([@waits], [], 'no waiting');
};

subtest 'a Retry-After that is not a number uses the backoff' => sub {
  for my $value ('Wed, 21 Oct 2026 07:28:00 GMT', q{}, '-5', '1.5') {
    my $client = client(2);
    my $http   = $client->get_http_client;
    $http->mock(429, {}, { 'retry-after' => $value })->mock(429, {})->mock(200, {});

    $client->request('GET', $URL);

    is_deeply([@waits], [1, 2], "backoff with '$value'");
  }
};

subtest 'other statuses are never retried' => sub {
  for my $status (200, 201, 204, 301, 400, 401, 404, 428, 430, 500, 502, 503, 504) {
    my $client = client(3);
    my $http   = $client->get_http_client;
    $http->mock($status, {}, { 'retry-after' => 1 })->mock(200, {});

    my $response = $client->request('POST', $URL);

    is($response->get_status_code,   $status, "$status is returned");
    is(scalar(() = $http->requests), 1,       "$status is not repeated");
  }
};

subtest 'a transport failure is not retried' => sub {
  my $client = client(3);
  my $http   = $client->get_http_client;

  # The fake client dies when it has no response, as a transport would.
  my $ok = eval { $client->request('POST', $URL); 1 };

  ok(!$ok, 'the failure reaches the caller');
  is(scalar(() = $http->requests), 1, 'one request');
  is_deeply([@waits], [], 'no waiting');
};

subtest 'each attempt is logged' => sub {
  my $client = client(1);
  my $http   = $client->get_http_client;
  $client->set_log_level('debug');
  $http->mock(429, {})->mock(200, {});

  my @logged;
  {
    local $SIG{__WARN__} = sub { push @logged, @_ };
    $client->request('GET', $URL);
  }

  is(scalar(grep { /BEGIN Twilio API Request/ } @logged), 2, 'two requests logged');
  is(scalar(grep { /Status Code: 429/ } @logged),         1, 'the 429 logged');
  is(scalar(grep { /Status Code: 200/ } @logged),         1, 'the 200 logged');
};

subtest 'max_retries is checked' => sub {
  for my $value (-1, 1.5, 'many', q{}) {
    my $ok    = eval { client($value); 1 };
    my $error = $@;
    ok(!$ok, "'$value' is refused");
    isa_ok($error, 'Twilio::Exceptions::ConfigurationException');
  }
};

subtest 'set_max_retries' => sub {
  my $client = client();

  $client->set_max_retries(3);
  is($client->get_max_retries, 3, 'set');

  $client->set_max_retries;
  is($client->get_max_retries, 0, 'no argument turns retries off');

  my $ok = eval { $client->set_max_retries('many'); 1 };
  ok(!$ok, 'a bad value is refused');
  is($client->get_max_retries, 0, 'a bad value changes nothing');
};

done_testing;

sub client {
  my ($max_retries) = @_;
  @waits = ();
  return Twilio::Rest::Client->new(
    'ACxx', 'token',
    {
      http_client => Twilio::Http::FakeClient->new,
      environment => {},
      max_retries => $max_retries,
    }
  );
}
