#
# Copyright (c) 2006-2011 TomTom International B.V.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
# * Neither the name of TomTom nor the names of its
#   contributors may be used to endorse or promote products derived from this
#   software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#

=head1 NAME

TomTom::WEBFLEET::Connect - A lightweight wrapper around the TomTom WEBFLEET.connect API in Perl

=head1 SYNOPSIS

  $connect = new TomTom::WEBFLEET::Connect(...);
  @objects;
  $r = $connect->showObjectReport();
  if ($r->is_success) {
      foreach my $i (@{$r->content_arrayref}) {
          push @objects, $i;
      }
  }

=head1 DESCRIPTION

=head2 Parameters

=head3 Authentication

Authentication parameters are automatically attached to the API request URL for each request.

=over

=item B<account>

required, a WEBFLEET account name

=item B<username>

required, a valid WEBFLEET user name belonging to the I<account>

=item B<password>

required, the password for the user identified by B<account> and B<username>

=back

=head3 Environment

=over

=item B<base>

The URL to use for the API. Defaults to I<http://connect.webfleet.tomtomwork.com/extern>. Needs to be changed when SSL should be used.

=item B<trace>

If B<trace> evaluates to I<true>, each request/response pair is logged to a new file in B<tracedir>.

=item B<tracedir>

The directory where log files should go to. Defaults to I</var/log/wfc>.

=item B<mockup>

The filename provided as B<mockup> is used as a response data stream. In this case, no actual request is sent to the API.

=back

=head2 Methods

API methods are autoloaded, additional parameters can be provided as a hash. No retries are being made neither if a request quota is reached nor on any other error. All methods return a generic L<TomTom::WEBFLEET::Connect::Response> object.

=cut

package TomTom::WEBFLEET::Connect;
use TomTom::WEBFLEET::Connect::Response;
use Carp;
use LWP::UserAgent;
use Data::Dumper;
use File::Temp;


BEGIN {
   our $VERSION = 2.11;
}

my %methods = (
  showObjectReport => 'showObjectReportExtern',
  showVehicleReport => 'showVehicleReportExtern',
  showContracts => 'showContracts',
  updateVehicle => 'updateVehicle',
  showObjectGroups => 'showObjectGroups',
  showObjectGroupObjects => 'showObjectGroupObjects',
  attachObjectToGroup => 'attachObjectToGroup',
  detachObjectFromGroup => 'detachObjectFromGroup',
  insertObjectGroup => 'insertObjectGroup',
  deleteObjectGroup => 'deleteObjectGroup',
  updateObjectGroup => 'updateObjectGroup',
  #showObjectGroupReport => 'showObjectGroupReportExtern', # deprecated
  #showObjectGroupObjectReport => 'showObjectGroupObjectReportExtern', # deprecated

  showDriverReport => 'showDriverReportExtern',
  insertDriver => 'insertDriverExtern',
  updateDriver => 'updateDriverExtern',
  deleteDriver => 'deleteDriverExtern',
  showOptiDriveIndicator => 'showOptiDriveIndicator',

  showAddressReport => 'showAddressReportExtern',
  insertAddress => 'insertAddressExtern',
  updateAddress => 'updateAddressExtern',
  deleteAddress => 'deleteAddressExtern',
  showAddressGroupReport => 'showAddressGroupReportExtern',
  insertAddressGroup => 'insertAddressGroupExtern',
  deleteAddressGroup => 'deleteAddressGroupExtern',
  attachAddressToGroup => 'attachAddressToGroupExtern',
  detachAddressFromGroup => 'detachAddressFromGroupExtern',
  showAddressGroupAddressReport => 'showAddressGroupAddressReportExtern',

  showTripReport => 'showTripReportExtern',
  showTripSummaryReport => 'showTripSummaryReportExtern',
  showLogbookReport => 'showLogbookReportExtern',
  showWorkingTimes => 'showWorkingTimes',
  #showObjectAccelerationEvents => 'showObjectAccelerationEvents', # deprecated
  #showObjectSpeedingEvents => 'showObjectSpeedingEvents', # deprecated
  showStandStills => 'showStandStills',
  showIdleExceptions => 'showIdleExceptions',

  showIOReport => 'showIOReportExtern',
  showAccelerationEvents => 'showAccelerationEvents',
  showSpeedingEvents => 'showSpeedingEvents',

  showOrderReport => 'showOrderReportExtern',
  sendOrder => 'sendOrderExtern',
  updateOrder => 'updateOrderExtern',
  sendDestinationOrder => 'sendDestinationOrderExtern',
  updateDestinationOrder => 'updateDestinationOrderExtern',
  cancelOrder => 'cancelOrderExtern',
  assignOrder => 'assignOrderExtern',
  reassignOrder => 'reassignOrderExtern',
  deleteOrder => 'deleteOrderExtern',
  clearOrders => 'clearOrdersExtern',
  sendTextMessage => 'sendTextMessageExtern',
  clearTextMessages => 'clearTextMessagesExtern',

  createQueue => 'createQueueExtern',
  deleteQueue => 'deleteQueueExtern',
  popQueueMessages => 'popQueueMessagesExtern',
  ackQueueMessages => 'ackQueueMessagesExtern',

  showEventReport => 'showEventReportExtern',
  acknowledgeEvent => 'acknowledgeEventExtern',
  resolveEvent => 'resolveEventExtern',

  geocodeAddress => 'geocodeAddress',
  calcRouteSimple => 'calcRouteSimpleExtern',

  showSettings => 'showSettings',
);

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my %params = @_;

  my $self = {
    access => {
      account => $params{account},
      username => $params{username},
      password => $params{password}
    },
    global => {
      lang => defined($params{lang})?$params{lang}:'en',
      apikey => $params{apikey},
      useISO8601 => (defined($params{useISO8601}) and grep(/$params{useISO8601}/i, qw(1 true yes))) ? 'true' : undef,
    },
    config => {
      trace => defined($params{trace})?$params{trace}:0,
      tracedir => defined($params{tracedir})?$params{tracedir}:'/var/log/wfc',
      base => defined($params{'url-base'}) ? $params{'url-base'} : 'http://connect.webfleet.tomtomwork.com/extern',
      mockup => $params{mockup},
    },
  };
  bless($self, $class);
  return $self;
}

sub AUTOLOAD {
  my $self = shift;
  my %params = @_;
  my $name = $AUTOLOAD;
  $name =~ s/.*://;
  if (exists $methods{$name}){
    $self->make_call(action=>$methods{$name}, query=>\%params);
  } else {
    croak("unsupported method: $name");
  }
}

sub DESTROY {
}

sub make_call {
  my $self = shift;
  my %params = @_;

  my $resp;

  my $tmpf;
  if ($self->{config}{trace}) {
    $tmpf = new File::Temp(UNLINK => 0, TEMPLATE => "$params{action}-XXXXXX",
      DIR => $self->{config}{tracedir});
  }

  if ($self->{config}{mockup}) {
    $resp = TomTom::WEBFLEET::Connect::Response->new(duration=>0, mockup=>$self->{config}{mockup});
  } else {
    my ($qs, $base);

    $base = $self->{config}{base}.'?';
    my $qsh = {
      %{$self->{access}},
      lang => $self->{global}{lang},
      action => $params{action},
      %{$params{query}}
    };
    $qsh->{apikey} = $self->{global}{apikey} if defined $self->{global}{apikey};
    $qsh->{useISO8601} = $self->{global}{useISO8601} if defined $self->{global}{useISO8601};
    $qs .= join('&', map($_.'='.$qsh->{$_},sort keys(%$qsh)));

    my $ua = LWP::UserAgent->new;
    $ua->env_proxy;
    $ua->timeout($params{timeout}) if ($params{timeout});
    my $req = HTTP::Request->new(GET => "$base$qs");
    if ($self->{config}{trace}) {
      print $tmpf "\n--- request ---\n", $req->as_string;
    }
    my $start = time;
    my $res = $ua->request($req);
    my $stop = time;
    if ($self->{config}{trace}) {
      print $tmpf
        "\n--- raw response ---\n",
        $res->content;
    }
    $resp = TomTom::WEBFLEET::Connect::Response->new(response=>$res, duration=>$stop-$start);
  }
  if ($self->{config}{trace}) {
    print $tmpf
      "\n--- stats ---\n",
      "duration=", $resp->duration, "s, ",
      "code=", $resp->code, ", ",
      "msg=", $resp->message,
      "\n--- parsed response ---\n",
      Dumper($resp->content_arrayref), "\n---\n";
  }
  return $resp;
}

1;

=head1 SEE ALSO

L<TomTom::WEBFLEET::Connect::Response>

=head1 COPYRIGHT

Copyright 2006-2010 TomTom International B.V.

All rights reserved.

=cut

__END__
