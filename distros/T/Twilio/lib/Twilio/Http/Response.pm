package Twilio::Http::Response;

use 5.016;
use warnings;

use Twilio::Json;

our $VERSION = '2.002';

sub new {
  my ($class, $status_code, $content, $headers) = @_;
  return bless { status_code => $status_code, content => $content, headers => $headers // {} },
    $class;
}

sub get_status_code { return $_[0]{status_code} }
sub get_headers     { return $_[0]{headers} }
sub get_raw_content { return $_[0]{content} }

sub get_content {
  my ($self) = @_;
  my $content = $self->{content};
  return unless defined $content && length $content;

  # Gateways can answer with HTML, so a body that is not JSON is not an error here.
  my $decoded = eval { Twilio::Json::decode($content) };
  return $decoded;
}

sub ok {
  my ($self) = @_;
  return $self->{status_code} < 400;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Twilio::Http::Response - The response to an HTTP request

=head1 SYNOPSIS

  my $response = $client->request('GET', $url);
  print $response->get_status_code, "\n";
  my $data = $response->get_content;

=head1 METHODS

=head2 new

  my $response = Twilio::Http::Response->new($status_code, $content, \%headers);

=head2 get_status_code

Returns the HTTP status code.

=head2 get_content

Returns the decoded JSON body, or nothing when the body is empty or is not JSON.

=head2 get_raw_content

Returns the body exactly as received.

=head2 get_headers

Returns a hash reference of response headers. L<Twilio::Http::TinyClient>
gives the names in lower case.

=head2 ok

Returns true when the status code is below 400.

=head1 LICENSE

Copyright (c) 2026 Francisco Zarabozo. Released under the MIT License.

=cut
