package Twilio::Http::FakeClient;

use 5.016;
use warnings;

use parent 'Twilio::Http::Client';

use Carp qw(croak);

use Twilio::Http::Response;
use Twilio::Json;

our $VERSION = '2.001';

sub new {
  my ($class, $options) = @_;
  my $self = $class->SUPER::new($options);
  $self->{queued_responses} = [];
  $self->{requests}         = [];
  return $self;
}

sub mock {
  my ($self, $status_code, $content, $headers) = @_;
  my $body = ref $content ? Twilio::Json::encode($content) : $content;
  push @{ $self->{queued_responses} }, Twilio::Http::Response->new($status_code, $body, $headers);
  return $self;
}

sub send_request {
  my ($self, $request) = @_;
  push @{ $self->{requests} }, $request;
  my $response = shift @{ $self->{queued_responses} };
  croak "No mocked response for $request->{method} $request->{url}" unless $response;
  return $response;
}

sub requests {
  my ($self) = @_;
  return @{ $self->{requests} };
}

1;

__END__

=encoding UTF-8

=head1 NAME

Twilio::Http::FakeClient - HTTP transport for tests, with no network

=head1 SYNOPSIS

  use Twilio::Http::FakeClient;
  use Twilio::Rest::Client;

  my $http   = Twilio::Http::FakeClient->new;
  my $client = Twilio::Rest::Client->new('ACxxxx', 'token', { http_client => $http });

  $http->mock(200, { sid => 'SMxxxx', status => 'queued' });

  my $response = $client->request('GET', 'https://api.twilio.com/2010-04-01/Accounts.json');

  my ($request) = $http->requests;
  print $request->{url}, "\n";

=head1 DESCRIPTION

Records every request in its final wire format and answers from a queue of
mocked responses. Use it to test your own code without a Twilio account.

=head1 METHODS

=head2 new

  my $http = Twilio::Http::FakeClient->new;

=head2 mock

  $http->mock($status_code, $content, \%headers);

Adds a response to the queue. Responses are used in the order they were added.
A reference as C<$content> is encoded as JSON, and a string is used as it is.
Returns the client, so calls can be chained.

=head2 send_request

Records the request and returns the next mocked response. It croaks when the
queue is empty, so an unexpected request fails the test.

=head2 requests

Returns the recorded requests, in the format described in
L<Twilio::Http::Client/prepare_request>.

=head1 LICENSE

Copyright (c) 2026 Francisco Zarabozo. Released under the MIT License.

=cut
