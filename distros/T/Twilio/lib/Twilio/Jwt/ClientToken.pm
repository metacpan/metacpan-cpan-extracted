package Twilio::Jwt::ClientToken;

use 5.016;
use warnings;

use Twilio::Exceptions::TwilioException;
use Twilio::Jwt::Client::ScopeURI;
use Twilio::Jwt::JWT;

our $VERSION = '2.002';

my $DEFAULT_TTL = 3600;
my $EVENTS_PATH = '/2010-04-01/Events';

sub new {
  my ($class, $account_sid, $auth_token) = @_;

  return bless {
    account_sid => $account_sid,
    auth_token  => $auth_token,
    scopes      => [],
    claims      => {},
  }, $class;
}

sub allow_client_incoming {
  my ($self, $client_name) = @_;

  if (($client_name // q{}) =~ /[^A-Za-z0-9_]/) {
    Twilio::Exceptions::TwilioException->throw(
      'Only alphanumeric characters allowed in client name.');
  }
  if (!length($client_name // q{})) {
    Twilio::Exceptions::TwilioException->throw('Client name must not be a zero length string.');
  }

  $self->{client_name} = $client_name;
  $self->_allow('client', 'incoming', [[clientName => $client_name]]);
  return;
}

sub allow_client_outgoing {
  my ($self, $application_sid, $params) = @_;

  my $query = Twilio::Jwt::Client::ScopeURI->build_query($params);
  $self->_allow('client', 'outgoing', [[appSid => $application_sid], [appParams => $query]]);
  return;
}

sub allow_event_stream {
  my ($self, $filters) = @_;

  my $query = Twilio::Jwt::Client::ScopeURI->build_query($filters);
  $self->_allow('stream', 'subscribe', [[path => $EVENTS_PATH], [params => $query]]);
  return;
}

sub add_claim {
  my ($self, $name, $value) = @_;
  $self->{claims}{$name} = $value;
  return;
}

sub generate_token {
  my ($self, $ttl) = @_;

  my $now = time;

  # An outgoing call has to say who it comes from, and that may be set after it is allowed.
  my @scopes = map { $self->_with_client_name($_)->to_string } @{ $self->{scopes} };

  my %payload = (
    %{ $self->{claims} },
    scope => join(q{ }, @scopes),
    iss   => $self->{account_sid},
    exp   => $now + ($ttl // $DEFAULT_TTL),
  );
  return Twilio::Jwt::JWT->encode(\%payload, $self->{auth_token});
}

sub _allow {
  my ($self, $service, $privilege, $params) = @_;
  push @{ $self->{scopes} }, Twilio::Jwt::Client::ScopeURI->new($service, $privilege, $params);
  return;
}

sub _with_client_name {
  my ($self, $scope) = @_;

  if ($scope->get_privilege eq 'outgoing' && defined $self->{client_name}) {
    $scope->add_param(clientName => $self->{client_name});
  }
  return $scope;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Twilio::Jwt::ClientToken - A capability token for older Twilio Client applications

=head1 SYNOPSIS

  use Twilio::Jwt::ClientToken;

  my $capability = Twilio::Jwt::ClientToken->new($account_sid, $auth_token);
  $capability->allow_client_incoming('alice');
  $capability->allow_client_outgoing($application_sid, { caller => 'alice' });

  print $capability->generate_token(3600);

=head1 DESCRIPTION

B<Twilio has deprecated Capability Tokens>, and says they will eventually reach
end of life. New code should use L<Twilio::Jwt::AccessToken>, which is signed with
an API key instead of your auth token, and works in every region. Capability Tokens
only work in the US1 region. See
L<Twilio's guide|https://www.twilio.com/docs/voice/sdks/javascript/migrating-capability-token>.

This class exists for applications that still rely on them.

=head1 METHODS

=head2 new

  my $capability = Twilio::Jwt::ClientToken->new($account_sid, $auth_token);

=head2 allow_client_incoming

  $capability->allow_client_incoming($client_name);

Lets the client receive calls under a name, which can only have letters, digits and
underscores. It throws L<Twilio::Exceptions::TwilioException> on any other name.

=head2 allow_client_outgoing

  $capability->allow_client_outgoing($application_sid, \%params);

Lets the client make calls through a TwiML application.

=head2 allow_event_stream

  $capability->allow_event_stream(\%filters);

Lets the client subscribe to its event stream.

=head2 add_claim

  $capability->add_claim($name, $value);

Adds a claim of your own. It cannot replace C<scope>, C<iss> or C<exp>.

=head2 generate_token

  my $token = $capability->generate_token($ttl);

Returns the token. C<$ttl> is in seconds, and defaults to 3600.

=head1 LICENSE

Copyright (c) 2026 Francisco Zarabozo. Released under the MIT License.

=cut
