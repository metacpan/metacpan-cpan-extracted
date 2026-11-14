package Twilio::Jwt::JWT;

use 5.016;
use warnings;

use Digest::SHA  qw(hmac_sha256 hmac_sha384 hmac_sha512);
use MIME::Base64 ();

use Twilio::Exceptions::TwilioException;
use Twilio::Json;
use Twilio::Security::RequestValidator;

our $VERSION = '2.002';

my $SEGMENTS = 3;

# All of these need a key, so a token cannot choose a method that does not. "none" is the
# classic way to forge a JWT, and it is refused here for not being in either list.
my %METHOD = (HS256 => \&hmac_sha256, HS384 => \&hmac_sha384, HS512 => \&hmac_sha512);

# RS256 is RSA with PKCS#1 v1.5 padding and SHA-256, signed with a private key and checked with
# the public one. Only client validation needs it, so its module is optional and loaded then.
my %RSA_HASH = (RS256 => 'use_sha256_hash');

sub encode {
  my ($class, $payload, $key, $algorithm, $headers) = @_;
  $algorithm //= 'HS256';

  my %header = (%{ $headers // {} }, typ => 'JWT', alg => $algorithm);
  my $signed = join q{.}, $class->urlsafe_b64_encode(Twilio::Json::encode(\%header)),
    $class->urlsafe_b64_encode(Twilio::Json::encode($payload));

  return join q{.}, $signed, $class->urlsafe_b64_encode($class->sign($signed, $key, $algorithm));
}

sub decode {
  my ($class, $token, $key, $verify) = @_;
  $verify //= 1;

  my ($header_text, $payload_text, $signature_text) = _segments($token);
  my $header  = _json($class->urlsafe_b64_decode($header_text));
  my $payload = _json($class->urlsafe_b64_decode($payload_text));
  return $payload if !$verify;

  _fail('Empty algorithm') if ref $header ne 'HASH' || !length($header->{alg} // q{});
  _fail('A key is needed to verify a token') if !length($key // q{});

  my $signed = "$header_text.$payload_text";
  my $given  = $class->urlsafe_b64_decode($signature_text);
  my $valid;
  if ($RSA_HASH{ $header->{alg} }) {
    my $public = _rsa_key($key, 'public', $header->{alg});
    $valid = eval { $public->verify($signed, $given) };
  }
  else {
    my $expected = $class->sign($signed, $key, $header->{alg});
    $valid = Twilio::Security::RequestValidator->compare($given, $expected);
  }
  _fail('Signature verification failed') if !$valid;
  return $payload;
}

sub get_header {
  my ($class, $token) = @_;

  my ($header_text) = _segments($token);
  return _json($class->urlsafe_b64_decode($header_text));
}

sub sign {
  my ($class, $message, $key, $algorithm) = @_;
  $algorithm //= 'HS256';

  return _rsa_key($key, 'private', $algorithm)->sign(_bytes($message)) if $RSA_HASH{$algorithm};

  my $method = $METHOD{$algorithm} // _fail('Algorithm not supported');

  # A token that names HS256 must not be checked with the text of a public key as its secret:
  # anyone could sign that, since the key is public.
  _fail("$algorithm takes a shared secret, not a key in PEM form")
    if ($key // q{}) =~ /-----BEGIN /;
  return $method->($message, _bytes($key));
}

sub urlsafe_b64_encode {
  my ($class, $text) = @_;

  my $encoded = MIME::Base64::encode_base64($text, q{});
  $encoded =~ tr{+/}{-_};
  $encoded =~ tr/=//d;
  return $encoded;
}

sub urlsafe_b64_decode {
  my ($class, $text) = @_;

  my $standard = $text =~ tr{-_}{+/}r;
  return MIME::Base64::decode_base64($standard);
}

sub _segments {
  my ($token) = @_;

  my @segments = split /[.]/, $token // q{}, -1;
  _fail('Wrong number of segments') if @segments != $SEGMENTS;
  return @segments;
}

sub _json {
  my ($text) = @_;

  my $value = eval { Twilio::Json::decode($text) };
  _fail('Invalid segment encoding') if !defined $value;
  return $value;
}

sub _rsa_key {
  my ($pem, $kind, $algorithm) = @_;

  if (!eval { require Crypt::OpenSSL::RSA; 1 }) {
    _fail("$algorithm needs the Perl module Crypt::OpenSSL::RSA, which is not installed");
  }
  my $key = length($pem // q{})
    && eval {
    $kind eq 'private'
      ? Crypt::OpenSSL::RSA->new_private_key(_bytes($pem))
      : Crypt::OpenSSL::RSA->new_public_key(_bytes($pem));
    };
  _fail("$algorithm needs an RSA $kind key in PEM form") if !$key;

  my $hash = $RSA_HASH{$algorithm};
  $key->$hash;

  # Crypt::OpenSSL::RSA 0.35 to 0.37 refused this padding for signatures too, not only for
  # encryption; 0.38 allows it again.
  if (!eval { $key->use_pkcs1_padding; 1 }) {
    _fail("$algorithm needs Crypt::OpenSSL::RSA 0.38 or later (or before 0.35), which allow "
        . 'PKCS#1 v1.5 signatures');
  }
  return $key;
}

sub _bytes {
  my ($text) = @_;
  my $bytes = "$text";
  utf8::encode($bytes) if utf8::is_utf8($bytes);
  return $bytes;
}

sub _fail {
  my ($message) = @_;
  Twilio::Exceptions::TwilioException->throw($message);
  return;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Twilio::Jwt::JWT - Encode, decode and verify JSON Web Tokens

=head1 SYNOPSIS

  use Twilio::Jwt::JWT;

  my $token   = Twilio::Jwt::JWT->encode({ sub => 'me' }, $secret);
  my $payload = Twilio::Jwt::JWT->decode($token, $secret);

=head1 DESCRIPTION

The signing underneath L<Twilio::Jwt::AccessToken>. Most code does not need it
directly, except to read a token in a test.

Tokens are signed with C<HS256>, C<HS384> or C<HS512> and a shared secret, or
with C<RS256> and an RSA key in PEM form: the private key to sign, and the public
one to verify. Everything else, including C<none>, is refused, and so is a key in
PEM form given as the secret of an C<HS> method. These methods throw
L<Twilio::Exceptions::TwilioException> on any problem.

C<RS256> needs L<Crypt::OpenSSL::RSA>, which is optional and loaded only then:
version 0.38 or later, or one before 0.35, since 0.35 to 0.37 refuse the padding
that C<RS256> uses. Twilio uses C<RS256> for client validation; see
L<Twilio::Http::ValidationClient>.

=head1 METHODS

=head2 encode

  my $token = Twilio::Jwt::JWT->encode($payload, $key, $algorithm, \%headers);

Returns a signed token. C<$algorithm> defaults to C<HS256>. C<typ> and C<alg> are
always set here, whatever C<\%headers> says.

=head2 decode

  my $payload = Twilio::Jwt::JWT->decode($token, $key);

Returns the payload after checking the signature: in constant time for the C<HS>
methods, and with the public key for C<RS256>. Passing a false third argument
skips that check, so only do it for a token you do not rely on.

=head2 get_header

  my $header = Twilio::Jwt::JWT->get_header($token);

Returns the header. It does not check the signature.

=head2 sign

  my $signature = Twilio::Jwt::JWT->sign($message, $key, $algorithm);

Returns the raw signature of a message.

=head2 urlsafe_b64_encode

=head2 urlsafe_b64_decode

Convert to and from the URL-safe Base64 that tokens use, with no padding.

=head1 LICENSE

Copyright (c) 2026 Francisco Zarabozo. Released under the MIT License.

=cut
