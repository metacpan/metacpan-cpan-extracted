package Twilio::AuthStrategy::TokenAuthStrategy;

use 5.016;
use warnings;

use parent 'Twilio::AuthStrategy::AuthStrategy';

use MIME::Base64 qw(decode_base64url);

use Twilio::Json;

our $VERSION = '2.002';

# A token that is about to expire could expire on its way to Twilio, so it is replaced this
# many seconds early, as the official libraries do.
my $EXPIRY_BUFFER_SECONDS = 30;

sub new {
  my ($class, $token_manager) = @_;
  my $self = $class->SUPER::new('token');
  $self->{token_manager} = $token_manager;
  $self->{token}         = undef;
  return $self;
}

sub get_auth_string {
  my ($self, $client) = @_;
  return 'Bearer ' . $self->fetch_token($client);
}

sub requires_authentication { return 1 }

sub fetch_token {
  my ($self, $client) = @_;
  if (!defined $self->{token} || $self->is_token_expired($self->{token})) {
    $self->{token} = $self->{token_manager}->fetch_token($client);
  }
  return $self->{token};
}

# twilio-php keeps a token whose expiry it can't read until Twilio refuses it. Like
# twilio-python, this asks for a new one instead, which costs a request but never fails one.
sub is_token_expired {
  my ($self, $token) = @_;
  my $expires_at = _expires_at($token);
  return 1 if !defined $expires_at;
  return $expires_at - $EXPIRY_BUFFER_SECONDS <= time ? 1 : 0;
}

sub _expires_at {
  my ($token) = @_;
  my (undef, $payload) = split /[.]/, $token // q{};
  return if !defined $payload;

  my $claims = eval { Twilio::Json::decode(decode_base64url($payload)) };
  return if ref $claims ne 'HASH';

  my $exp = $claims->{exp};
  return if !defined $exp || $exp !~ /\A[0-9]+(?:[.][0-9]+)?\z/;
  return $exp;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Twilio::AuthStrategy::TokenAuthStrategy - Requests with an OAuth access token

=head1 DESCRIPTION

Returned by L<Twilio::CredentialProvider::ClientCredentialProvider>. It sends
C<Authorization: Bearer> with a token from its token manager, and keeps that
token until 30 seconds before the expiry written in it, so most requests don't
ask for a new one.

A token is a JWT, and its C<exp> claim gives the expiry. A token whose expiry
can't be read counts as expired, so a token manager that returns something
other than a JWT gets a new token for each request.

=head1 METHODS

=head2 new

  my $strategy = Twilio::AuthStrategy::TokenAuthStrategy->new($token_manager);

C<$token_manager> is a L<Twilio::Http::BearerToken::TokenManager>.

=head2 get_auth_string

  my $header = $strategy->get_auth_string($client);

Returns C<Bearer> and the token from L</fetch_token>.

=head2 requires_authentication

Returns true.

=head2 fetch_token

  my $token = $strategy->fetch_token($client);

Returns the token it holds, or asks the token manager for a new one when it
has none or it is about to expire. C<$client> is passed to the token manager.
An error from the token manager reaches the caller.

=head2 is_token_expired

  my $expired = $strategy->is_token_expired($token);

Returns true when the token expires within 30 seconds, or its expiry can't be
read.

=head1 LICENSE

Copyright (c) 2026 Francisco Zarabozo. Released under the MIT License.

=cut
