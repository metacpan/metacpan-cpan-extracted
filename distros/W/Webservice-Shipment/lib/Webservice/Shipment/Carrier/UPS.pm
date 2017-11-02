package Webservice::Shipment::Carrier::UPS;

use Mojo::Base 'Webservice::Shipment::Carrier';

use Mojo::Template;
use Mojo::URL;
use Mojo::IOLoop;
use Time::Piece;
use Carp;

use constant DEBUG => $ENV{MOJO_SHIPMENT_DEBUG};

has api_key => sub { croak 'api_key is required' };
has api_url => sub { Mojo::URL->new('https://wwwcie.ups.com/ups.app/xml/Track') };

has template => <<'TEMPLATE';
% my ($self, $id) = @_;
<?xml version="1.0" ?>
<AccessRequest xml:lang='en-US'>
  <AccessLicenseNumber><%== $self->api_key %></AccessLicenseNumber>
  <UserId><%== $self->username %></UserId>
  <Password><%== $self->password %></Password>
</AccessRequest>
<?xml version="1.0" ?>
<TrackRequest>
  <Request>
    <TransactionReference>
      <CustomerContext><%== $id %></CustomerContext>
    </TransactionReference>
    <RequestAction>Track</RequestAction>
  </Request>
  <TrackingNumber><%== $id %></TrackingNumber>
</TrackRequest>
TEMPLATE

has validation_regex => sub { qr/\b(1Z ?[0-9A-Z]{3} ?[0-9A-Z]{3} ?[0-9A-Z]{2} ?[0-9A-Z]{4} ?[0-9A-Z]{3} ?[0-9A-Z]|[\dT]\d\d\d ?\d\d\d\d ?\d\d\d)\b/i };

sub extract_destination {
  my ($self, $id, $dom, $target) = @_;

  my %targets = (
    postal_code => 'PostalCode',
    state => 'StateProvinceCode',
    city => 'City',
    country => 'CountryCode',
    address1 => 'AddressLine1',
    address2 => 'AddressLine2',
  );

  my $t = $targets{$target} or return;
  my $addr = $dom->at("Shipment ShipTo Address $t") or return;
  return $addr->text;
}

sub extract_service {
  my ($self, $id, $dom) = @_;
  my $service = $dom->at('Shipment Service Description') or return;
  my $text = $service->text;
  $text = "UPS $text" unless $text =~ /UPS/;
  return $text;
}

sub extract_status {
  my ($self, $id, $dom) = @_;

  my $activity = $dom->find('Shipment Package Activity');
  my ($status, $date, $delivered);

  my $to_date = sub {
    my $dom = shift;
    return Time::Piece->strptime(
      $dom->at('Date')->text . ' T ' . $dom->at('Time')->text,
      '%Y%m%d T %H%M%S'
    );
  };

  my $d = $activity->first(sub{ $_->at('Status StatusType Code')->text eq 'D' });
  if ($d) {
    $status = $d->at('Status StatusType Description')->text;
    $date   = $d->$to_date();
    $delivered = 1;
  } else {
    my $current = $activity
      ->map(sub{ [$_, $_->$to_date()] })
      ->sort(sub{ $b->[1] <=> $a->[1] })
      ->[0];

    $status = $current->[0]->at('Status StatusType Description');
    $status = $status ? $status->text : '';
    $date   = $current->[1];
  }

  return($status, $date, $delivered);
}

sub extract_weight {
  my ($self, $id, $dom) = @_;

  my $weight = $dom->at('Shipment ShipmentWeight') or return '';
  return $weight->at('Weight')->text . ' ' . $weight->at('UnitOfMeasurement Code')->text;
}

sub human_url {
  my ($self, $id, $dom) = @_;
  return Mojo::URL->new('http://wwwapps.ups.com/WebTracking/track')->query(trackNums => $id, 'track.x' => 'Track');
}

sub request {
  my ($self, $id, $cb) = @_;

  my $xml = Mojo::Template->new->render($self->template, $self, $id);
  warn "Request:\n$xml" if DEBUG;

  unless ($cb) {
    my $tx = $self->ua->post($self->api_url, $xml);
    return _handle_response($tx);
  }

  Mojo::IOLoop->delay(
    sub { $self->ua->post($self->api_url, $xml, shift->begin) },
    sub {
      my ($ua, $tx) = @_;
      die $tx->error->{message} unless $tx->success;
      my $dom = _handle_response($tx);
      $self->$cb(undef, $dom);
    },
  )->tap(on => error => sub{ $self->$cb($_[1], undef) })->wait;
}

sub _handle_response {
  my $tx = shift;
  my $dom = $tx->res->dom;
  warn "Response:\n$dom\n" if DEBUG;
  $dom = $dom->at('TrackResponse');

  return undef unless $dom->at('Response ResponseStatusCode')->text; # "1" on success
  return $dom;
}

1;

=head1 NAME

Webservice::Shipment::Carrier::UPS - UPS handling for Webservice::Shipment

=head1 DESCRIPTION

Implements UPS handling for L<Webservice::Shipment>.
It is a subclass of L<Webservice::Shipment::Carrier> which implements all the necessary methods.

=head1 ATTRIBUTES

L<Webservice::Shipment::Carrier::UPS> implements all of the attributes from L<Webservice::Shipment::Carrier> and implements the following new ones

=head2 api_key

Your api key for the UPS API.
The default implementation dies if used without being specified.

=head2 template

The string template used with L<Mojo::Template> to format the request.

