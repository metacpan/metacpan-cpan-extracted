package Twilio::Http::Client;

use 5.016;
use warnings;

use Carp         qw(croak);
use MIME::Base64 qw(encode_base64);
use Scalar::Util qw(blessed);

use Twilio::Json;

our $VERSION = '2.001';

my $DEFAULT_TIMEOUT = 60;

sub new {
  my ($class, $options) = @_;
  return bless { %{ $options // {} } }, $class;
}

sub request {
  my ($self, $method, $url, $options) = @_;

  my $request = $self->prepare_request($method, $url, $options);
  $self->{last_request}  = $request;
  $self->{last_response} = undef;

  my $response = $self->send_request($request);
  $self->{last_response} = $response;
  return $response;
}

sub send_request {
  my ($self) = @_;
  croak ref($self) . ' must implement send_request';
}

sub prepare_request {
  my ($self, $method, $url, $options) = @_;
  $options //= {};

  # Flex Insights takes a token of its own in Authorization, as an option of the operation, and
  # that one is sent instead of the account's credentials.
  my %headers = %{ $options->{headers} // {} };
  my $given   = grep { lc eq 'authorization' } keys %headers;
  if (!$given && length($options->{username} // q{}) && length($options->{password} // q{})) {
    $headers{Authorization} = _basic_auth($options->{username}, $options->{password});
  }

  my $query = $self->build_query($options->{params});
  if (length $query) {
    $url .= ($url =~ /[?]/ ? q{&} : q{?}) . $query;
  }

  my %request = (
    method  => uc $method,
    url     => $url,
    headers => \%headers,
    timeout => $options->{timeout} // $self->{timeout} // $DEFAULT_TIMEOUT,
  );

  if ($request{method} =~ /\A(?:POST|PUT|PATCH)\z/) {
    $request{content} = $self->_build_body($options->{data}, \%headers);
  }

  return \%request;
}

sub build_query {
  my ($self, $params) = @_;

  my @parts;
  for my $key (sort keys %{ $params // {} }) {
    my $value  = $params->{$key};
    my @values = ref $value eq 'ARRAY' ? @{$value} : ($value);
    push @parts, map { _encode_component($key) . q{=} . _encode_component($_) }
      grep { defined } @values;
  }

  return join q{&}, @parts;
}

sub last_request  { return $_[0]{last_request} }
sub last_response { return $_[0]{last_response} }

sub _build_body {
  my ($self, $data, $headers) = @_;

  if (($headers->{'Content-Type'} // q{}) =~ m{\Aapplication/json\b}i) {
    return Twilio::Json::encode($data // {});
  }

  if (grep { _is_file($_) } _form_values($data)) {
    my ($boundary, $body) = _multipart($data);
    $headers->{'Content-Type'} = "multipart/form-data; boundary=$boundary";
    return $body;
  }

  $headers->{'Content-Type'} //= 'application/x-www-form-urlencoded';
  return $self->build_query($data);
}

sub _form_values {
  my ($data) = @_;
  return map { ref eq 'ARRAY' ? @{$_} : $_ } values %{ $data // {} };
}

sub _is_file {
  my ($value) = @_;
  return blessed($value) && $value->isa('Twilio::Http::File');
}

# Keys go in sorted order, as in a form, and a list sends one part per item.
sub _multipart {
  my ($data) = @_;

  my @parts;
  for my $key (sort keys %{$data}) {
    my $value = $data->{$key};
    for my $item (grep { defined } ref $value eq 'ARRAY' ? @{$value} : $value) {
      push @parts, _is_file($item) ? _file_part($key, $item) : _text_part($key, $item);
    }
  }

  my $boundary = _boundary(@parts);
  my $body     = join q{}, map { "--$boundary\r\n$_\r\n" } @parts;
  return ($boundary, "$body--$boundary--\r\n");
}

sub _text_part {
  my ($name, $value) = @_;
  return _disposition($name) . "\r\n\r\n" . _utf8_bytes($value);
}

sub _file_part {
  my ($name, $file) = @_;

  my $type = $file->get_content_type // 'application/octet-stream';
  return
      _disposition($name)
    . '; filename="'
    . _quoted($file->upload_name)
    . "\"\r\nContent-Type: $type\r\n\r\n"
    . $file->bytes;
}

sub _disposition {
  my ($name) = @_;
  return 'Content-Disposition: form-data; name="' . _quoted($name) . q{"};
}

# Escaped as browsers do in a form, so a name cannot end its header or add another.
sub _quoted {
  my ($text) = @_;
  my $bytes = _utf8_bytes($text);
  $bytes =~ s/(["\r\n])/sprintf('%%%02X', ord $1)/ge;
  return $bytes;
}

# The boundary must not occur in any part, which is checked rather than left to chance.
sub _boundary {
  my (@parts) = @_;

  my $boundary = _random_boundary();
  $boundary = _random_boundary() while grep { index($_, $boundary) >= 0 } @parts;
  return $boundary;
}

sub _random_boundary {
  return 'twilio-' . join q{}, map { sprintf '%04x', int rand 0x10000 } 1 .. 8;
}

sub _basic_auth {
  my ($username, $password) = @_;
  return 'Basic ' . encode_base64(_utf8_bytes("$username:$password"), q{});
}

# Encodes like PHP's rawurlencode, but with spaces as "+", which is what Twilio's
# signature validation and the official libraries expect in form bodies.
sub _encode_component {
  my ($value) = @_;
  my $encoded = _utf8_bytes($value);
  $encoded =~ s/([^A-Za-z0-9._~ -])/sprintf('%%%02X', ord $1)/ge;
  $encoded =~ tr/ /+/;
  return $encoded;
}

# Callers may hold text as characters or as UTF-8 bytes, for example a literal in a script
# without "use utf8". Treating valid UTF-8 bytes as already encoded sends both correctly,
# where always encoding would double-encode the second case and corrupt the message.
sub _utf8_bytes {
  my ($value) = @_;
  my $text = "$value";

  if (!utf8::is_utf8($text)) {
    my $probe = $text;
    return $text if utf8::decode($probe);
  }

  utf8::encode($text);
  return $text;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Twilio::Http::Client - Base class for HTTP transports

=head1 SYNOPSIS

  package My::Transport;
  use parent 'Twilio::Http::Client';

  sub send_request {
    my ($self, $request) = @_;

    # Send $request->{method} to $request->{url} with $request->{headers}, an
    # optional $request->{content} and a $request->{timeout} in seconds.

    return Twilio::Http::Response->new($status, $body, \%headers);
  }

  package main;
  my $client = Twilio::Rest::Client->new($sid, $token, {
    http_client => My::Transport->new,
  });

=head1 DESCRIPTION

This class turns a request into its exact wire format: URL, headers and body.
A transport only has to deliver it, by implementing L</send_request>. This is
how to replace the default L<Twilio::Http::TinyClient>, for example to use a
proxy library or a system without OpenSSL.

Text may be given as characters or as UTF-8 bytes in form and query values. A
JSON body must hold characters.

=head1 METHODS

=head2 new

  my $http = Twilio::Http::Client->new(\%options);

The C<timeout> option sets the default timeout in seconds, which is 60.

=head2 request

  my $response = $http->request($method, $url, \%options);

Prepares and sends a request, and returns a L<Twilio::Http::Response>. The
options are C<params> (query string), C<data> (request body), C<headers>,
C<username>, C<password> and C<timeout>. An array reference as a value of
C<params> or C<data> sends the key once per item, and C<undef> values are left
out.

The body is sent as a form unless the C<Content-Type> header is
C<application/json>. When a value of the form, or an item of a list, is a
L<Twilio::Http::File>, the form is sent as C<multipart/form-data> instead, with
one part per value. The C<Authorization> header is sent on the first request
rather than after a 401 challenge.

=head2 send_request

  my $response = $http->send_request($request);

Subclasses must implement this. It receives the hash reference built by
L</prepare_request>, and must return a L<Twilio::Http::Response>.

=head2 prepare_request

  my $request = $http->prepare_request($method, $url, \%options);

Returns a hash reference with C<method>, C<url>, C<headers>, C<timeout>, and
C<content> for POST, PUT and PATCH.

=head2 build_query

  my $query = $http->build_query({ To => '+15558675309', MediaUrl => [$first, $second] });

Returns the URL-encoded form of a hash reference, with keys in sorted order.

=head2 last_request

Returns the last request sent, as built by L</prepare_request>. It includes the
C<Authorization> header, so treat it as a secret.

=head2 last_response

Returns the last L<Twilio::Http::Response>, or nothing if the last request failed
before a response arrived.

=head1 LICENSE

Copyright (c) 2026 Francisco Zarabozo. Released under the MIT License.

=cut
