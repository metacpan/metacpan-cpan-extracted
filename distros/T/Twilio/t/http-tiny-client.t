use 5.016;
use warnings;

use Test::More;

use Twilio::Http::TinyClient;

my $url = 'https://api.twilio.com/2010-04-01/Accounts.json';

subtest 'the default HTTP::Tiny verifies TLS and refuses redirects' => sub {
  my $http_tiny = Twilio::Http::TinyClient->new->{http_tiny};

  isa_ok($http_tiny, 'HTTP::Tiny');
  ok($http_tiny->verify_SSL, 'certificates are verified');
  is($http_tiny->max_redirect, 0, 'redirects are not followed');
};

subtest 'a request reaches HTTP::Tiny complete' => sub {
  my $tiny = Local::FakeTiny->new({ status => 201, content => '{"sid":"SM1"}', headers => {} });
  my $http = Twilio::Http::TinyClient->new({ http_tiny => $tiny });

  my $response = $http->request(
    'POST', $url,
    {
      data     => { Body => 'hi' },
      username => 'ACxx',
      password => 'secret',
      timeout  => 7,
    }
  );

  my ($method, $sent_url, $arguments) = @{ $tiny->{call} };
  is($method,               'POST',    'method');
  is($sent_url,             $url,      'url');
  is($arguments->{content}, 'Body=hi', 'body');
  like($arguments->{headers}{Authorization}, qr/\ABasic /, 'auth header');
  is($tiny->{timeout}, 7, 'timeout');

  is($response->get_status_code, 201, 'response status');
  is_deeply($response->get_content, { sid => 'SM1' }, 'response content');
};

subtest 'a request without a body sends no content' => sub {
  my $tiny = Local::FakeTiny->new({ status => 200, content => '{}', headers => {} });
  Twilio::Http::TinyClient->new({ http_tiny => $tiny })->request('GET', $url);
  ok(!exists $tiny->{call}[2]{content}, 'no content');
};

subtest 'HTTP errors are responses, not exceptions' => sub {
  my $tiny     = Local::FakeTiny->new({ status => 500, content => 'oops', headers => {} });
  my $response = Twilio::Http::TinyClient->new({ http_tiny => $tiny })->request('GET', $url);
  is($response->get_status_code, 500, 'status kept');
};

subtest 'transport failures throw' => sub {
  my $tiny = Local::FakeTiny->new({ status => 599, content => 'Could not connect', headers => {} });

  my $ok = eval { Twilio::Http::TinyClient->new({ http_tiny => $tiny })->request('GET', $url); 1 };
  my $error = $@;

  ok(!$ok, 'died');
  isa_ok($error, 'Twilio::Exceptions::EnvironmentException');
  like($error->get_message, qr/Could not connect/, 'message from HTTP::Tiny');
};

# twilio-php's testFileProtocolThrowsException: a URL may never read a local file.
subtest 'only http and https URLs are fetched' => sub {
  my $client = Twilio::Http::TinyClient->new;

  for my $other ('file:///etc/passwd', 'ftp://example.com/x') {
    my $ok    = eval { $client->request('GET', $other); 1 };
    my $error = $@;
    ok(!$ok, "$other: refused");
    like("$error", qr/Unsupported URL scheme/, 'by HTTP::Tiny, before any I/O');
  }
};

done_testing;

package Local::FakeTiny;    ## no critic (Modules::ProhibitMultiplePackages)

sub new {
  my ($class, $result) = @_;
  return bless { result => $result }, $class;
}

sub timeout {
  my ($self, $timeout) = @_;
  $self->{timeout} = $timeout;
  return;
}

sub request {
  my ($self, @call) = @_;
  $self->{call} = \@call;
  return $self->{result};
}
