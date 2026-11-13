package Twilio::Security::RequestValidator;

use 5.016;
use warnings;

use Carp         qw(carp);
use Digest::SHA  qw(hmac_sha1 hmac_sha256 sha256_hex);
use MIME::Base64 ();

use Twilio::Exceptions::TwilioException;

our $VERSION = '2.001';

my $DEFAULT_ALGORITHM = 'HMAC_SHA1';
my %HMAC              = (HMAC_SHA1 => \&hmac_sha1, HMAC_SHA256 => \&hmac_sha256);

my %DEFAULT_PORT = (https => 443, http => 80);

# scheme, user information, host, port, and everything after them
my $HOST      = qr/\[[^\]]*\]|[^\/?\#:]*/;
my $URL_PARTS = qr{\A([^:/?\#]+)://(?:([^/?\#@]*)@)?($HOST)(?::(\d*))?(.*)\z}s;

sub SIGNATURE_HEADER          { return 'X-Twilio-Signature' }
sub SIGNATURE_SETTINGS_HEADER { return 'X-Twilio-Webhooks-Signature-Settings' }
sub HMAC_SHA1                 { return 'HMAC_SHA1' }
sub HMAC_SHA256               { return 'HMAC_SHA256' }

sub new {
  my ($class, $auth_token) = @_;
  return bless { auth_token => _bytes($auth_token // q{}) }, $class;
}

sub get_signature_algorithm {
  my ($class, $settings_header) = @_;

  for my $part (split /,/, $settings_header // q{}) {
    my ($name, $value) = split /=/, $part, 2;
    next if !defined $value;

    $name  =~ s/\A\s+|\s+\z//g;
    $value =~ s/\A\s+|\s+\z//g;
    return $value if $name eq 'algorithm' && length $value;
  }
  return $DEFAULT_ALGORITHM;
}

sub compute_signature {
  my ($self, $url, $data, $algorithm) = @_;

  my $hmac = _hmac_for($algorithm);
  if (!$hmac) {
    Twilio::Exceptions::TwilioException->throw(
      "Unsupported webhook signature algorithm: $algorithm");
  }

  my $text   = _bytes($url);
  my %values = %{ $data // {} };
  for my $key (sort keys %values) {
    my $value = $values{$key};
    my @list  = ref $value eq 'ARRAY' ? @{$value} : ($value);
    my %seen;
    my @unique = grep { !$seen{$_}++ } map { _bytes($_ // q{}) } @list;
    $text .= _bytes($key) . $_ for sort @unique;
  }

  return MIME::Base64::encode_base64($hmac->($text, $self->{auth_token}), q{});
}

sub compute_body_hash {
  my ($class, $body) = @_;
  return sha256_hex(_bytes($body // q{}));
}

sub validate {
  my ($self, $signature, $url, $data, $algorithm) = @_;

  if (!_hmac_for($algorithm)) {
    carp "Unsupported webhook signature algorithm '$algorithm'";
    return 0;
  }

  # May not receive a body, so that part passes unless one is given.
  my $valid_body = 1;
  if (defined $data && ref $data ne 'HASH') {
    $valid_body = $self->compare($self->compute_body_hash($data), _query_value($url, 'bodySHA256'));
    $data       = {};
  }

  # Twilio is not consistent about the port in what it signs, so both forms are accepted.
  my $with_port    = $self->compute_signature(_url_with_port($url),    $data, $algorithm);
  my $without_port = $self->compute_signature(_url_without_port($url), $data, $algorithm);

  # Both comparisons run every time, so the time taken says nothing about which one matched.
  my $matches_with    = $self->compare($signature, $with_port);
  my $matches_without = $self->compare($signature, $without_port);
  return $valid_body && ($matches_with || $matches_without) ? 1 : 0;
}

# The time taken depends on the length, not on where the two strings differ.
sub compare {
  my ($class, $one, $other) = @_;

  return 0 if !length($one // q{}) || !length($other // q{});

  my $one_bytes   = _bytes($one);
  my $other_bytes = _bytes($other);
  return 0 if length $one_bytes != length $other_bytes;

  my $difference = 0;
  for my $position (0 .. length($one_bytes) - 1) {
    $difference |= ord(substr $one_bytes, $position, 1) ^ ord(substr $other_bytes, $position, 1);
  }
  return $difference == 0 ? 1 : 0;
}

sub _hmac_for {
  my ($algorithm) = @_;
  return $HMAC{ uc($algorithm // q{}) || $DEFAULT_ALGORITHM };
}

sub _bytes {
  my ($text) = @_;
  my $bytes = "$text";
  utf8::encode($bytes) if utf8::is_utf8($bytes);
  return $bytes;
}

sub _url_without_port {
  my ($url) = @_;

  my ($scheme, $user, $host, undef, $rest) = $url =~ $URL_PARTS or return $url;
  return _url($scheme, $user, $host, $rest);
}

sub _url_with_port {
  my ($url) = @_;

  my ($scheme, $user, $host, $port, $rest) = $url =~ $URL_PARTS or return $url;
  my $number = length($port // q{}) ? $port : $DEFAULT_PORT{ lc $scheme } // $DEFAULT_PORT{http};
  return _url($scheme, $user, "$host:$number", $rest);
}

sub _url {
  my ($scheme, $user, $host, $rest) = @_;
  return "$scheme://" . (defined $user ? "$user\@" : q{}) . $host . $rest;
}

sub _query_value {
  my ($url, $name) = @_;

  my ($query) = $url =~ /[?]([^#]*)/;
  my $found;
  for my $pair (split /&/, $query // q{}) {
    my ($key, $value) = split /=/, $pair, 2;
    $found = _decoded($value // q{}) if _decoded($key) eq $name;
  }
  return $found;
}

sub _decoded {
  my ($text) = @_;
  $text =~ tr/+/ /;
  $text =~ s/%([0-9A-Fa-f]{2})/chr hex $1/ge;
  return $text;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Twilio::Security::RequestValidator - Check that a webhook really came from Twilio

=head1 SYNOPSIS

  use Twilio::Security::RequestValidator;

  my $validator = Twilio::Security::RequestValidator->new($auth_token);

  # A form post: pass its parameters
  my $is_from_twilio = $validator->validate($signature, $url, \%params);

  # A JSON post: pass its raw body
  my $is_from_twilio = $validator->validate($signature, $url, $raw_body);

  # A webhook signed with a SharedKey
  my $algorithm = Twilio::Security::RequestValidator->get_signature_algorithm(
    $settings_header
  );
  my $validator = Twilio::Security::RequestValidator->new($shared_key_secret);
  my $is_from_twilio = $validator->validate($signature, $url, \%params, $algorithm);

=head1 DESCRIPTION

Anyone who finds the URL of a webhook can send it a request, so an application
should check each one before trusting it. Twilio signs its requests, and puts
the signature in the C<X-Twilio-Signature> header.

C<$url> must be the full URL Twilio called, as Twilio knows it, including the query
string. Behind a proxy, that is not always the URL your server sees.

Keys and values may be given as characters or as UTF-8 bytes. A value can be an
array reference, for a parameter that came more than once.

=head1 METHODS

=head2 new

  my $validator = Twilio::Security::RequestValidator->new($secret);

C<$secret> is the auth token of the account, or the SharedKey secret when the
request has an C<X-Twilio-Webhooks-Signature-Settings> header.

=head2 validate

  my $valid = $validator->validate($signature, $url, $data, $algorithm);

Returns 1 when the signature is right, and 0 otherwise. C<$data> is a hash reference
of parameters, or the raw body as a string. A body must match the C<bodySHA256>
parameter in the URL. The signature is accepted with or without the port in the
URL, because Twilio is not consistent about it.

C<$algorithm> is C<HMAC_SHA1>, which is the default, or C<HMAC_SHA256>. One that this
library does not know gives a warning and returns 0.

=head2 compute_signature

  my $signature = $validator->compute_signature($url, \%params, $algorithm);

Returns the signature of a request. It throws
L<Twilio::Exceptions::TwilioException> when it does not know the algorithm.

=head2 compute_body_hash

  my $hash = Twilio::Security::RequestValidator->compute_body_hash($body);

Returns the SHA-256 hash of a body, in hexadecimal.

=head2 compare

  my $same = Twilio::Security::RequestValidator->compare($one, $other);

Returns 1 when two non-empty strings are the same. It takes the same time wherever
they differ, so that the time cannot be used to guess a signature.

=head2 get_signature_algorithm

  my $algorithm = Twilio::Security::RequestValidator->get_signature_algorithm($header);

Returns the algorithm named in the C<X-Twilio-Webhooks-Signature-Settings> header,
or C<HMAC_SHA1> when there is no such header, or it does not name one.

=head2 SIGNATURE_HEADER

=head2 SIGNATURE_SETTINGS_HEADER

=head2 HMAC_SHA1

=head2 HMAC_SHA256

Return the names of the two headers and of the two algorithms.

=head1 LICENSE

Copyright (c) 2026 Francisco Zarabozo. Released under the MIT License.

=cut
