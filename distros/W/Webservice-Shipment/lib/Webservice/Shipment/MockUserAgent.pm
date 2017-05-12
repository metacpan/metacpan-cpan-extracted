package Webservice::Shipment::MockUserAgent;

use Mojo::Base 'Mojo::UserAgent';

use Mojolicious;
use Mojo::URL;

has mock_blocking => 1;
has mock_response => sub { {} };

sub new {
  my $self = shift->SUPER::new(@_);

  my $app = Mojolicious->new;
  $app->routes->any('/*any' => {any => ''} => sub { shift->render(%{$self->mock_response}) });
  $self->server->app($app);

  $self->on(start => sub {
    my ($self, $tx) = @_;
    $self->emit(mock_request => $tx->req);
    my $port = $self->mock_blocking ? $self->server->url->port : $self->server->nb_url->port;
    $tx->req->url->host('')->scheme('')->port($port);
  });

  return $self;
}

1;

=head1 NAME

Webservice::Shipment::MockUserAgent - A useragent which can generate mock service call reponses

=head1 SYNOPSIS

  my $mock = Webservice::Shipment::MockUserAgent->new;
  my $ship = Webservice::Shipment->new(defaults => {ua => $mock})->add_carrier(...);

  # test blocking responses
  $mock->mock_response({text => $xml, format => 'xml'});
  my $info = $ship->track($id); # receives $xml

  # test non-blocking responses
  $mock->mock_blocking(0);
  $ship->track($id => sub{ my ($carrier, $err, $info) = @_; ... }); # receives $xml

  # test the built request
  $mock->on(mock_request => sub { ($mock, $req) = @_; ... });

=head1 DESCRIPTION

A subclass of L<Mojo::UserAgent> which can be used in place of the carrier's L<Webservice::Shipment::Carrier/ua> and is capable of mocking service results.
For the time being there is no packaged mock data.
The author recomends extracting a response from a valid request and injecting it into the mock, thereby pinning the result and no longer relying on the external service.

=head1 EVENTS

L<Webservice::Shipment::MockUserAgent> inherits all of the events from L<Mojo::UserAgent> and emits the following new ones

=head2 mock_request

  $mock->on(mock_request => sub { my ($mock, $res) = @_; ... });

Emitted when a request is emitted by the mock service.

Note that this class makes use of the existing C<start> event to rewrite the url.
This event is emitted during that process, before the url is rewritten so that users may test that request (if so desired).
Since the request url is mutated, if it is to be tested later, C<clone>ing the url is recommended.

  my $url;
  $mock->on(mock_request => sub { $url = pop->url->clone });
  is $url, $expected;

=head1 ATTRIBUTES

L<Webservice::Shipment::MockUserAgent> inherits all of the attributes from L<Mojo::UserAgent> and implements the following new ones

=head2 mock_blocking

When true, the default, the mock service will expect a blocking request.
In order to request a mock result in a non-blocking manner, set to a false value.

=head2 mock_response

A hash reference, used as stash values to build a response via a very generic embedded Mojolicious app.
Most users will use C<< {text => $xml, format => 'xml'} >> in order to render xml (where C<$xml> contains an xml document).


