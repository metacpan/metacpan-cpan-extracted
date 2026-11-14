package Twilio::Jwt::AccessToken;

use 5.016;
use warnings;

use overload
  q{""}    => sub { $_[0]->to_jwt },
  bool     => sub { 1 },
  fallback => 1;

use Carp         qw(croak);
use Scalar::Util qw(blessed);

use Twilio::Jwt::JWT;

our $VERSION = '2.002';

my $DEFAULT_TTL  = 3600;
my $CONTENT_TYPE = 'twilio-fpa;v=1';

sub new {
  my ($class, $account_sid, $signing_key_sid, $secret, $ttl, $identity, $region) = @_;

  return bless {
    account_sid     => $account_sid,
    signing_key_sid => $signing_key_sid,
    secret          => $secret,
    ttl             => $ttl // $DEFAULT_TTL,
    identity        => $identity,
    region          => $region,
    grants          => [],
    claims          => {},
  }, $class;
}

sub get_identity { return $_[0]{identity} }
sub get_nbf      { return $_[0]{nbf} }
sub get_region   { return $_[0]{region} }

sub set_identity {
  my ($self, $identity) = @_;
  $self->{identity} = $identity;
  return $self;
}

sub set_nbf {
  my ($self, $nbf) = @_;
  $self->{nbf} = $nbf;
  return $self;
}

sub set_region {
  my ($self, $region) = @_;
  $self->{region} = $region;
  return $self;
}

sub add_grant {
  my ($self, $grant) = @_;

  # Checked here, as twilio-python does: otherwise the mistake surfaces only in to_jwt, far from
  # where it was made and as a missing method.
  if (!blessed($grant) || !$grant->can('get_grant_key') || !$grant->can('get_payload')) {
    croak 'add_grant takes a grant object, such as Twilio::Jwt::Grants::VideoGrant->new, not '
      . (defined $grant ? (ref $grant || "'$grant'") : 'undef');
  }
  push @{ $self->{grants} }, $grant;
  return $self;
}

sub add_claim {
  my ($self, $name, $value) = @_;
  $self->{claims}{$name} = $value;
  return;
}

sub to_jwt {
  my ($self, $algorithm) = @_;

  my %header = (cty => $CONTENT_TYPE);
  $header{twr} = $self->{region} if length($self->{region} // q{});

  my $key = $self->{signing_key_sid};
  my $now = time;

  # Custom claims come first, so that one can never replace the claims that identify the token.
  my %payload = (
    %{ $self->{claims} },
    jti    => "$key-$now",
    iss    => $key,
    sub    => $self->{account_sid},
    exp    => $now + $self->{ttl},
    grants => $self->_grants,
  );
  $payload{nbf} = 0 + $self->{nbf} if defined $self->{nbf};

  return Twilio::Jwt::JWT->encode(\%payload, $self->{secret}, $algorithm, \%header);
}

sub _grants {
  my ($self) = @_;

  my %grants;
  $grants{identity} = $self->{identity} if length($self->{identity} // q{});
  $grants{ $_->get_grant_key } = $_->get_payload for @{ $self->{grants} };
  return \%grants;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Twilio::Jwt::AccessToken - A token that lets a client use Twilio directly

=head1 SYNOPSIS

  use Twilio::Jwt::AccessToken;
  use Twilio::Jwt::Grants::VoiceGrant;

  my $token = Twilio::Jwt::AccessToken->new(
    $account_sid, $api_key_sid, $api_key_secret, 3600, 'alice'
  );

  my $grant = Twilio::Jwt::Grants::VoiceGrant->new;
  $grant->set_outgoing_application_sid($application_sid);
  $grant->set_incoming_allow(1);
  $token->add_grant($grant);

  print $token->to_jwt;

=head1 DESCRIPTION

An Access Token gives a browser or a mobile app limited use of Twilio, without
handing it your credentials. It is signed with an API key, so create one for this
and keep its secret on your server.

What a token allows comes from the grants added to it: see
L<Twilio::Jwt::Grants::ChatGrant>, L<Twilio::Jwt::Grants::PlaybackGrant>,
L<Twilio::Jwt::Grants::SyncGrant>, L<Twilio::Jwt::Grants::TaskRouterGrant>,
L<Twilio::Jwt::Grants::VideoGrant> and L<Twilio::Jwt::Grants::VoiceGrant>.

A token converts to its text in string context.

=head1 METHODS

=head2 new

  my $token = Twilio::Jwt::AccessToken->new(
    $account_sid, $signing_key_sid, $secret, $ttl, $identity, $region
  );

C<$ttl> is how many seconds the token lasts, and defaults to 3600. C<$identity>
and C<$region> are optional.

=head2 add_grant

  $token->add_grant($grant);

Adds a grant and returns the token. It dies when C<$grant> is not a grant object.

=head2 add_claim

  $token->add_claim($name, $value);

Adds a claim of your own. It cannot replace the claims the token needs, such as
C<iss> or C<exp>.

=head2 to_jwt

  my $text = $token->to_jwt($algorithm);

Returns the signed token. C<$algorithm> defaults to C<HS256>. The expiry counts
from this call.

=head2 get_identity

=head2 set_identity

=head2 get_nbf

=head2 set_nbf

C<nbf> is the time, in seconds since the epoch, before which the token is not valid.

=head2 get_region

=head2 set_region

Read and change each value. The C<set_> methods return the token.

=head1 LICENSE

Copyright (c) 2026 Francisco Zarabozo. Released under the MIT License.

=cut
