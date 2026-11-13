package Twilio::Base::BaseClient;

use 5.016;
use warnings;

use POSIX        ();
use Scalar::Util qw(blessed);

use Twilio;
use Twilio::Exceptions::ConfigurationException;
use Twilio::Exceptions::TwilioException;
use Twilio::Http::TinyClient;

our $VERSION = '2.001';

my $ENV_ACCOUNT_SID = 'TWILIO_ACCOUNT_SID';
my $ENV_AUTH_TOKEN  = 'TWILIO_AUTH_TOKEN';
my $ENV_REGION      = 'TWILIO_REGION';
my $ENV_EDGE        = 'TWILIO_EDGE';
my $ENV_LOG_LEVEL   = 'TWILIO_LOG_LEVEL';
my $DEFAULT_REGION  = 'us1';

my $PIECES_WITH_REGION = 4;    # product.region.twilio.com
my $PIECES_WITH_EDGE   = 5;    # product.edge.region.twilio.com

my $STATUS_TOO_MANY_REQUESTS = 429;
my $RETRY_BACKOFF_BASE       = 2;
my $RETRY_MAX_WAIT_SECONDS   = 60;

sub new {
  my ($class, $username, $password, $options) = @_;
  $options //= {};

  my $self = bless {
    environment           => $options->{environment}           // \%ENV,
    user_agent_extensions => $options->{user_agent_extensions} // [],
    http_client           => $options->{http_client}           // Twilio::Http::TinyClient->new,
  }, $class;

  $self->set_username($self->get_arg($username, $ENV_ACCOUNT_SID));
  $self->set_password($self->get_arg($password, $ENV_AUTH_TOKEN));
  $self->set_account_sid($options->{account_sid} // $self->get_username);
  $self->{region}    = $self->get_arg($options->{region}, $ENV_REGION);
  $self->{edge}      = $self->get_arg($options->{edge},   $ENV_EDGE);
  $self->{log_level} = $self->get_arg(undef,              $ENV_LOG_LEVEL);
  $self->set_max_retries($options->{max_retries});
  $self->set_credential_provider($options->{credential_provider})
    if $options->{credential_provider};

  return $self;
}

sub get_arg {
  my ($self, $arg, $env_var) = @_;
  return $arg if defined $arg && length $arg;
  return $self->{environment}{$env_var};
}

sub request {
  my ($self, $method, $uri, $options) = @_;
  $options //= {};
  $method = uc $method;

  # A username and password win over a provider, as in twilio-php. Setting a provider clears the
  # client's own, so they only apply when given again, to the client or to one request.
  my $username = $options->{username} || $self->get_username;
  my $password = $options->{password} || $self->get_password;
  my $strategy = $username && $password ? undef : $self->_auth_strategy;
  if (!$strategy) {
    Twilio::Exceptions::ConfigurationException->throw('username is required') if !$username;
    Twilio::Exceptions::ConfigurationException->throw('password is required') if !$password;
  }

  # Header options the caller did not set are left out, like any other option.
  my %headers =
    map { $_ => $options->{headers}{$_} } grep { defined $options->{headers}{$_} }
    keys %{ $options->{headers} // {} };
  $headers{'User-Agent'}     = $self->_user_agent;
  $headers{'Accept-Charset'} = 'utf-8';

  # Delete responses have no body to negotiate.
  $headers{Accept} //= 'application/json' if $method ne 'DELETE';

  # An Authorization header from the caller is Flex Insights' own token, and it is sent instead.
  my $given = grep { lc eq 'authorization' } keys %headers;
  if ($strategy && $strategy->requires_authentication && !$given) {
    $headers{Authorization} = $strategy->get_auth_string($self);
  }

  my $response = $self->_send_with_retries(
    $method,
    $self->build_uri($uri),
    {
      %{$options},
      headers  => \%headers,
      username => $username,
      password => $password,
    }
  );
  push @{ $self->{captured_responses} }, $response if $self->{captured_responses};
  return $response;
}

# Scoped to $code, so the answers to other callers of a shared client are never mixed in. An
# OAuth token comes through a client of its own, so its answer is not among these.
sub capture_responses {
  my ($self, $code) = @_;
  local $self->{captured_responses} = [];
  my $result = $code->();
  return ($result, @{ $self->{captured_responses} });
}

# Only 429 is retried: Twilio has refused the request, so repeating it cannot send anything
# twice. After a 5xx or a broken connection, a POST may already have sent its message.
sub _send_with_retries {
  my ($self, $method, $url, $options) = @_;

  my $response = $self->_send($method, $url, $options);
  for my $attempt (1 .. $self->get_max_retries) {
    my $wait = _retry_wait($response, $attempt);
    last if !defined $wait;
    $self->_sleep($wait);
    $response = $self->_send($method, $url, $options);
  }
  return $response;
}

sub _send {
  my ($self, $method, $url, $options) = @_;

  my $log_debug = $self->_log_debug_enabled;
  _log_request($method, $url, $options->{params}, $options->{headers}) if $log_debug;
  my $response = $self->get_http_client->request($method, $url, $options);
  _log_response($response) if $log_debug;
  return $response;
}

sub _retry_wait {
  my ($response, $attempt) = @_;
  return if $response->get_status_code != $STATUS_TOO_MANY_REQUESTS;

  my $retry_after = _retry_after($response->get_headers);
  if (defined $retry_after) {

    # Retrying sooner than Twilio asked would only use up an attempt, and waiting longer than
    # the limit could hang a web request, so a long wait is the caller's to decide.
    return $retry_after <= $RETRY_MAX_WAIT_SECONDS ? $retry_after : undef;
  }

  my $backoff = $RETRY_BACKOFF_BASE**($attempt - 1);
  return $backoff < $RETRY_MAX_WAIT_SECONDS ? $backoff : $RETRY_MAX_WAIT_SECONDS;
}

# The date form of Retry-After is not read: it would depend on the local clock, and the
# backoff is a safe answer to it.
sub _retry_after {
  my ($headers) = @_;
  my ($name)    = grep { lc $_ eq 'retry-after' } keys %{$headers};
  return if !defined $name;

  my ($seconds) = ($headers->{$name} // q{}) =~ /\A\s*([0-9]+)\s*\z/;
  return $seconds;
}

sub _sleep {
  my ($self, $seconds) = @_;
  sleep $seconds;
  return;
}

sub build_uri {
  my ($self, $uri)    = @_;
  my ($edge, $region) = ($self->{edge}, $self->{region});
  return $uri if !$edge && !$region;

  my ($scheme, $host, $rest) = $uri =~ m{\A([a-z]+://)([^/:?#]+)(.*)\z}is;
  return $uri if !defined $host;

  my @pieces = split /[.]/, $host;
  return $uri if @pieces < 3;

  if (@pieces == $PIECES_WITH_REGION) {
    $region ||= $pieces[1];
  }
  elsif (@pieces == $PIECES_WITH_EDGE) {
    $edge   ||= $pieces[1];
    $region ||= $pieces[2];
  }
  $region ||= $DEFAULT_REGION if $edge;

  my $domain = join q{.}, @pieces[-2, -1];
  return $scheme . join(q{.}, grep { $_ } $pieces[0], $edge, $region, $domain) . $rest;
}

sub validate_ssl_certificate {
  my ($self, $http_client) = @_;
  $http_client //= $self->get_http_client;

  my $response = $http_client->request('GET', 'https://tls-test.twilio.com:443');
  my $status   = $response->get_status_code;
  if ($status < 200 || $status > 300) {
    Twilio::Exceptions::TwilioException->throw('Failed to validate SSL certificate');
  }
  return 1;
}

sub _auth_strategy {
  my ($self) = @_;
  my $provider = $self->get_credential_provider or return;
  return $provider->to_auth_strategy;
}

sub get_credential_provider { return $_[0]{credential_provider} }
sub get_environment         { return $_[0]{environment} }

sub set_credential_provider {
  my ($self, $credential_provider) = @_;
  if (!blessed($credential_provider) || !$credential_provider->can('to_auth_strategy')) {
    Twilio::Exceptions::ConfigurationException->throw(
      'credential_provider must be a Twilio::CredentialProvider::CredentialProvider');
  }
  $self->{credential_provider} = $credential_provider;
  $self->invalidate_basic_auth;
  return;
}

sub invalidate_basic_auth {
  my ($self) = @_;
  $self->{username} = undef;
  $self->{password} = undef;
  return;
}

sub invalidate_oauth {
  my ($self) = @_;
  $self->{credential_provider} = undef;
  return;
}

sub get_username    { return $_[0]{username} }
sub get_password    { return $_[0]{password} }
sub get_account_sid { return $_[0]{account_sid} }
sub get_region      { return $_[0]{region} }
sub get_edge        { return $_[0]{edge} }
sub get_http_client { return $_[0]{http_client} }
sub get_log_level   { return $_[0]{log_level} }
sub get_max_retries { return $_[0]{max_retries} }

sub set_username {
  my ($self, $username) = @_;
  $self->{username} = $username;
  return;
}

sub set_password {
  my ($self, $password) = @_;
  $self->{password} = $password;
  return;
}

sub set_account_sid {
  my ($self, $account_sid) = @_;
  $self->{account_sid} = $account_sid;
  return;
}

sub set_max_retries {
  my ($self, $max_retries) = @_;
  $max_retries //= 0;
  if ($max_retries !~ /\A[0-9]+\z/) {
    Twilio::Exceptions::ConfigurationException->throw('max_retries must be a whole number');
  }
  $self->{max_retries} = $max_retries;
  return;
}

sub set_edge {
  my ($self, $edge) = @_;
  $self->{edge} = $self->get_arg($edge, $ENV_EDGE);
  return;
}

sub set_http_client {
  my ($self, $http_client) = @_;
  $self->{http_client} = $http_client;
  return;
}

sub set_log_level {
  my ($self, $log_level) = @_;
  $self->{log_level} = $self->get_arg($log_level, $ENV_LOG_LEVEL);
  return;
}

sub _user_agent {
  my ($self) = @_;
  my ($system, undef, undef, undef, $machine) = POSIX::uname();
  my $agent = sprintf 'twilio-perl/%s (%s %s) Perl/%vd', Twilio->VERSION, $system, $machine, $^V;
  return join q{ }, $agent, @{ $self->{user_agent_extensions} };
}

sub _log_debug_enabled {
  my ($self) = @_;
  return 1 if ($self->{environment}{DEBUG_HTTP_TRAFFIC} // q{}) eq 'true';
  return ($self->get_log_level // q{}) eq 'debug';
}

sub _log_request {
  my ($method, $url, $params, $headers) = @_;
  warn "-- BEGIN Twilio API Request --\n";
  warn "Request Method: $method\n";
  warn "Request URL: $url\n";
  warn "Query Params: $_=$params->{$_}\n" for sort keys %{ $params // {} };
  warn "Request Headers:\n";
  warn "$_: $headers->{$_}\n" for grep { !/authorization/i } sort keys %{$headers};
  warn "-- END Twilio API Request --\n";
  return;
}

sub _log_response {
  my ($response) = @_;
  my $headers = $response->get_headers;
  warn 'Status Code: ' . $response->get_status_code . "\n";
  warn "Response Headers:\n";
  warn "$_: $headers->{$_}\n" for sort keys %{$headers};
  return;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Twilio::Base::BaseClient - Credentials, routing and requests shared by all clients

=head1 DESCRIPTION

This is the base class of L<Twilio::Rest::Client>, which is the class to use.
It finds the credentials, chooses the host for the configured edge and region,
adds the standard headers and passes each request to the HTTP client.

=head1 METHODS

=head2 new

  my $client = Twilio::Base::BaseClient->new($username, $password, \%options);

C<$username> and C<$password> are an Account SID and Auth Token, or an API key
SID and secret. They default to the C<TWILIO_ACCOUNT_SID> and
C<TWILIO_AUTH_TOKEN> environment variables. The options are:

=over

=item account_sid

The account to act on, which defaults to C<$username>. It is required with an
API key, and with a credential provider for account resources such as
C<< $client->messages >>.

=item credential_provider

A L<Twilio::CredentialProvider::CredentialProvider> that authenticates requests
instead of the username and password, such as
L<Twilio::CredentialProvider::ClientCredentialProvider> for OAuth. See
L</set_credential_provider>.

=item region, edge

Where to route requests. They default to C<TWILIO_REGION> and C<TWILIO_EDGE>.
Set both: Twilio routes a region without an edge to US1, and hostnames with a
region but no edge no longer work.

=item http_client

A L<Twilio::Http::Client> object. The default is L<Twilio::Http::TinyClient>.

=item environment

A hash reference to read the environment variables from, instead of C<%ENV>.

=item user_agent_extensions

An array reference of strings to add to the C<User-Agent> header.

=item max_retries

How many times to repeat a request that Twilio answers with HTTP 429. The
default is 0, which means never. See L</Retries>.

=back

=head2 Retries

With C<max_retries> set, a request that gets a 429 response is sent again, after
the number of seconds in the C<Retry-After> header. Without that header, the
waits are 1, 2, 4 seconds and so on, up to 60.

Nothing else is retried. After a server error or a lost connection, Twilio may
already have accepted a request, so repeating it could send a message twice.

C<request> does not return while it waits, so each retry can block the process
for up to 60 seconds. When C<Retry-After> asks for more than that, there is no
retry, and the 429 response is returned. When the retries run out, the last
response is returned too.

=head2 request

  my $response = $client->request($method, $url, \%options);

Sends a request and returns a L<Twilio::Http::Response>. The options are those
of L<Twilio::Http::Client/request>. C<username> and C<password> default to the
client's credentials. Without both, the credential provider authenticates the
request, unless the request has its own C<Authorization> header. It throws
L<Twilio::Exceptions::ConfigurationException> when there are no credentials.
It does not treat HTTP error statuses as exceptions.

=head2 capture_responses

  my ($result, @responses) = $client->capture_responses(sub { ... });

Runs the code and returns what it returns, followed by the
L<Twilio::Http::Response> of each request the client made meanwhile, in order.
A request repeated after HTTP 429 gives only its last answer. This is what
C<with_metadata> uses; see L<Twilio::Metadata>.

=head2 build_uri

  my $url = $client->build_uri('https://api.twilio.com/2010-04-01/Accounts.json');

Returns the URL with the client's edge and region applied, in the form
C<api.sydney.au1.twilio.com>. An edge with no region uses C<us1>. A region or
edge already in the URL is kept, unless the client sets its own.

=head2 validate_ssl_certificate

  $client->validate_ssl_certificate;

Connects to Twilio's TLS test host, using the given HTTP client or the
client's own. Throws L<Twilio::Exceptions::TwilioException> on a bad response.

=head2 get_arg

  my $value = $client->get_arg($value, $environment_variable);

Returns the value if it is not empty, and otherwise the environment variable.

=head2 set_credential_provider

  $client->set_credential_provider($provider);

Authenticates requests with C<$provider>, and clears the username and password,
as twilio-php does. The account SID is kept. A username and password set again
later, or given to one request, are used instead of the provider. It throws
L<Twilio::Exceptions::ConfigurationException> when C<$provider> is not a
credential provider.

=head2 invalidate_basic_auth

Clears the username and password.

=head2 invalidate_oauth

Removes the credential provider. Requests then need a username and password.

=head2 get_credential_provider

=head2 get_environment

=head2 get_username

=head2 get_password

=head2 get_account_sid

=head2 get_region

=head2 get_edge

=head2 get_http_client

=head2 get_log_level

=head2 get_max_retries

Return the current value of each setting.

=head2 set_username

=head2 set_password

=head2 set_account_sid

=head2 set_http_client

Replace the current value of each setting.

=head2 set_max_retries

  $client->set_max_retries(3);

Sets the number of retries. With no argument, it turns retries off. It throws
L<Twilio::Exceptions::ConfigurationException> unless the value is a whole number.

=head2 set_edge

  $client->set_edge('sydney');

Sets the edge. With no argument, it uses C<TWILIO_EDGE>, or unsets the edge.

=head2 set_log_level

  $client->set_log_level('debug');

Sets the log level. At C<debug>, requests and responses are logged to STDERR
with C<warn>, without the C<Authorization> header. With no argument, it uses
C<TWILIO_LOG_LEVEL>. Setting C<DEBUG_HTTP_TRAFFIC=true> has the same effect.

=head1 LICENSE

Copyright (c) 2026 Francisco Zarabozo. Released under the MIT License.

=cut
