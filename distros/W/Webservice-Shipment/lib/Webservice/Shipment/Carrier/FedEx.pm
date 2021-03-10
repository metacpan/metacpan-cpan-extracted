package Webservice::Shipment::Carrier::FedEx;

use Mojo::Base 'Webservice::Shipment::Carrier';

use constant DEBUG =>  $ENV{MOJO_SHIPMENT_DEBUG};

use Mojo::IOLoop;
use Mojo::IOLoop::Delay;
use Mojo::JSON;
use Mojo::URL;
use Time::Piece;

has api_url => sub { Mojo::URL->new('https://www.fedex.com/trackingCal/track') };
has carrier_description => sub { 'FedEx' };
has validation_regex => sub {    qr/(\b96\d{20}\b)|(\b\d{15}\b)|(\b\d{12}\b)/ };

sub human_url {
  my ($self, $id, $doc) = @_;
  return Mojo::URL->new('https://www.fedex.com/apps/fedextrack/')->query(
    action => 'track',
    locale => 'en_US',
    cntry_code => 'us',
    language => 'english',
    tracknumbers => $id,
  );
}

sub extract_destination {
  my ($self, $id, $doc, $target) = @_;

  my %targets = (
    postal_code => 'destZip',
    state => 'destStateCD',
    city => 'destCity',
    country => 'destCntryCD',
  );

  my $t = $targets{$target} or return;
  my $addr = $doc->{$t} or return;
  return $addr;
}

sub extract_service {
  my ($self, $id, $doc) = @_;
  my $class = $doc->{serviceDesc};
  my $service = $class =~ /fedex/i ? $class : 'FedEx ' . $class;
  return $service;
}

sub extract_status {
  my ($self, $id, $doc) = @_;

  my $summary = $doc->{scanEventList}[0];
  return unless $summary;

  my $delivered = $doc->{isDelivered} ? 1 : 0;

  my $desc = $doc->{statusWithDetails};
  unless ($summary->{date}) {
    $desc = 'No information found for <a href="' . $self->human_url($id) . '">' . $id . '</a>';
    return ($desc, undef, $delivered);
  }

  my $timestamp = join(' ', $summary->{date}, $summary->{time});
  eval{
    $timestamp = Time::Piece->strptime($summary->{date} . ' T ' . $summary->{time}, '%Y-%m-%d T %H:%M:%S');
  };

  $desc = $summary->{date} ? join(' ', $desc , $summary->{date}, $summary->{time}) : $desc;
  return ($desc, $timestamp, $delivered);
}

sub extract_weight { '' }

sub request {
  my ($self, $id, $cb) = @_;

  my $tx = $self->ua->build_tx(
    POST => $self->api_url.
    {Accept => 'application/json'},
    form => {
      action => 'trackpackages',
      locale => 'en_US',
      version => '1',
      format => 'json',
      data => Mojo::JSON::encode_json({
        TrackPackagesRequest => {
          appType => 'WTRK',
          uniqueKey => '',
          processingParameters => {},
          trackingInfoList => [
            {
              trackNumberInfo => {
                trackingNumber => $id,
                trackingQualifier => '',
                trackingCarrier => '',
              }
            }
          ]
        }
      })
    }
  );

  unless ($cb) {
    $self->ua->start($tx);
    return _handle_response($tx);
  }

  Mojo::IOLoop::Delay->new->steps(
    sub { $self->ua->start($tx, shift->begin) },
    sub {
      my ($ua, $tx) = @_;
      die $tx->error->{message} if $tx->error;
      my $json = _handle_response($tx);
      $self->$cb(undef, $json);
    },
  )->catch(sub { $self->$cb(pop, undef) })->wait;
}

sub _handle_response {
  my $tx = shift;
  my $json = $tx->res->json;
  warn "Response:\n" . $tx->res->body . "\n" if DEBUG;
  return $json->{TrackPackagesResponse}{packageList}[0];
}

1;

=head1 NAME

Webservice::Shipment::Carrier::FedEx - FedEx handling for Webservice::Shipment

=head1 DESCRIPTION

Implements FedEx handling for L<Webservice::Shipment>.
It is a subclass of L<Webservice::Shipment::Carrier> which implements all the necessary methods.

=head1 NOTES

The service does not provide weight information, so C<extract_weight> will always return an empty string.
