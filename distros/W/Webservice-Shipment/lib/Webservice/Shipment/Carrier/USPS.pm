package Webservice::Shipment::Carrier::USPS;

use Mojo::Base 'Webservice::Shipment::Carrier';

use constant DEBUG => $ENV{MOJO_SHIPMENT_DEBUG};

use Mojo::Template;
use Mojo::URL;
use Mojo::IOLoop;
use Mojo::IOLoop::Delay;
use Time::Piece;

has api_url => sub { Mojo::URL->new('http://production.shippingapis.com/ShippingAPI.dll?API=TrackV2') };

has template => <<'XML';
  % my ($self, $id) = @_;
<?xml version="1.0" encoding="UTF-8" ?>
<TrackFieldRequest USERID="<%= $self->username %>">
  <Revision>1</Revision>
  <ClientIp>127.0.0.1</ClientIp>
  <SourceId>Restore Health</SourceId>
  <TrackID ID="<%= $id %>"></TrackID>
</TrackFieldRequest>
XML

has carrier_description => sub { 'USPS' };
has validation_regex => sub { qr/\b(9\d\d\d ?\d\d\d\d ?\d\d\d\d ?\d\d\d\d ?\d\d\d\d ?\d\d|91\d\d ?\d\d\d\d ?\d\d\d\d ?\d\d\d\d ?\d\d\d\d)\b/i };

sub human_url {
  my ($self, $id, $dom) = @_;
  return Mojo::URL->new('https://tools.usps.com/go/TrackConfirmAction')->query(tLabels => $id);
}

sub extract_destination {
  my ($self, $id, $dom, $target) = @_;

  my %targets = (
    postal_code => 'DestinationZip',
    state => 'DestinationState',
    city => 'DestinationCity',
    country => 'DestinationCountryCode',
  );

  my $t = $targets{$target} or return;
  my $addr = $dom->at($t) or return;
  return $addr->text;
}

sub extract_service {
  my ($self, $id, $dom) = @_;
  my $class = $dom->at('Class');
  my $service = 'USPS';
  $service .= ' ' . $class->text if $class;
  return $service;
}

sub extract_status{
  my ($self, $id, $dom) = @_;
  my $summary = $dom->at('TrackSummary');
  return unless $summary;
  my $event = $summary->at('Event')->text;
  my $delivered = ($event =~ /delivered/i) ? 1 : 0;

  my $desc = $dom->at('StatusSummary');
  $desc = $desc ? $desc->text : $event;

  my $date = $summary->at('EventDate');
  $date = $date ? $date->text : '';
  my $fmt = '%B %d, %Y';

  if ($date) {
    if (my $time = $summary->at('EventTime')) {
      $time = $time->text;
      $date .= " T $time";
      $fmt  .= ' T %H:%M %p';
    }
    $date = eval { Time::Piece->strptime($date, $fmt) } || '';
    warn $@ if $@;
  }
  return ($desc, $date, $delivered);
}

sub extract_weight { '' }

sub request {
  my ($self, $id, $cb) = @_;

  my $xml = Mojo::Template->new->render($self->template, $self, $id);
  warn "Request:\n$xml" if DEBUG;
  my $url = $self->api_url->clone->query({XML => $xml});

  unless ($cb) {
    my $tx  = $self->ua->get($url);
    return _handle_response($tx);
  }

  Mojo::IOLoop::Delay->new->steps(
    sub { $self->ua->get($url, shift->begin) },
    sub {
      my ($ua, $tx) = @_;
      die $tx->error->{message} if $tx->error;
      my $dom = _handle_response($tx);
      $self->$cb(undef, $dom);
    },
  )->catch(sub{ $self->$cb(pop, undef) })->wait;
}

sub _handle_response {
  my $tx = shift;
  my $dom = $tx->res->dom;
  warn "Response:\n$dom\n" if DEBUG;
  return $dom->at('TrackResponse TrackInfo');
}

1;

=head1 NAME

Webservice::Shipment::Carrier::USPS - USPS handling for Webservice::Shipment

=head1 DESCRIPTION

Implements USPS handling for L<Webservice::Shipment>.
It is a subclass of L<Webservice::Shipment::Carrier> which implements all the necessary methods.

=head1 ATTRIBUTES

L<Webservice::Shipment::Carrier::USPS> implements all of the attributes from L<Webservice::Shipment::Carrier> and implements the following new ones

=head2 template

The string template used with L<Mojo::Template> to format the request.

=head1 NOTES

The service does not provide weight information, so C<extract_weight> will always return an empty string.

