package VMPS::Packet;
use strict;
use warnings;
use base qw[ Exporter ];

our $VERSION = '0.04';

use Net::MAC;
use Storable qw[ dclone ];

=head1 NAME

VMPS::Packet - Handle VMPS request/response packets.

=cut

our %CONSTANTS;
BEGIN {
    %CONSTANTS = (
        VMPS_REQ_JOIN => 0x1,
        VMPS_RESP_JOIN => 0x2,
        VMPS_REQ_RECONFIRM => 0x3,
        VMPS_RESP_RECONFIRM => 0x4,

        VMPS_ERROR_NONE => 0x0,
        VMPS_ERROR_ACCESS_DENIED => 0x3,
        VMPS_ERROR_SHUTDOWN => 0x4,
        VMPS_ERROR_WRONG_DOMAIN => 0x5,

        VMPS_DATA_CLIENT_IP   => 0xc01,
        VMPS_DATA_PORT_NAME   => 0xc02,
        VMPS_DATA_VLAN_NAME   => 0xc03,
        VMPS_DATA_VTP_DOMAIN  => 0xc04,
        VMPS_DATA_PACKET      => 0xc05,
        VMPS_DATA_MAC_DYNAMIC => 0xc06,
        VMPS_DATA_UNK7        => 0xc07,
        VMPS_DATA_MAC_STATIC  => 0xc08,
    );
}

use constant \%CONSTANTS;
use constant VMPS_HEADER_SIZE => 8;
use constant VMPS_TLV_HLEN => 6;

our @EXPORT_OK = keys %CONSTANTS;
our %EXPORT_TAGS = (
    'constants' => [keys %CONSTANTS],
);

#################################################################

sub _decode {
    my ($this, $dgram) = @_;

    die "Short packet!" if length($dgram) < VMPS_HEADER_SIZE;

    ## parse the header
    my ($one, $type, $err, $num_rec, $seq)
        = unpack('C4 N', substr($dgram, 0, VMPS_HEADER_SIZE, ''));

    ## sanity check
    die "Packet must start with 0x01" unless ($one == 0x1);
    die "Unknown request type: $type"
        unless ($type == VMPS_REQ_JOIN or $type == VMPS_REQ_RECONFIRM);

    my %pkt_data;

    ## decode TLVs
    while ($num_rec > 0)
    {
        $dgram or die "Short packet (expecting $num_rec more records)";
        $num_rec--;
        my ($typ, $len, $val);

        ($typ, $len) = unpack('Nn', substr($dgram, 0, VMPS_TLV_HLEN, ''));

        $val = substr($dgram, 0, $len, '');

        $pkt_data{$typ} = $val;
    }

    $dgram and die "Extra data at end of packet!";

    bless { TYPE => $type,
            ERR  => $err,
            SEQ  => $seq,
            DATA => \%pkt_data }, $this;
}

###################################

sub _encode {
    my ($this) = @_;

    ###################################
    ## encode packet header

    ## leading byte always 1
    my $pkt = pack('C', 1);

    die "Unknown response type ($this->{TYPE})!"
        unless (   $this->{TYPE} == VMPS_RESP_JOIN
                or $this->{TYPE} == VMPS_RESP_RECONFIRM);

    my $num_rec = $this->{ERR} == VMPS_ERROR_NONE ? 2 : 0;

    $pkt .= pack('C3 N', $this->{TYPE}, $this->{ERR}, $num_rec, $this->{SEQ});

    ###################################
    ## encode contents

    if ($this->{ERR} == VMPS_ERROR_NONE)
    {
        $pkt .= $this->_encode_data(VMPS_DATA_VLAN_NAME);
        $pkt .= $this->_encode_data(VMPS_DATA_MAC_STATIC, $this->_first_mac());
    }

    return $pkt;
}

###################################

sub _encode_data {
    my $this = shift;
    my $type = shift;

    my $val = @_ ? $_[0] : $this->{DATA}{$type};
    my $len = length($val);

    return pack ('N n a*', $type, $len, $val);
}

#################################################################
## accessor functions

=head1 FUNCTIONS

=head2 client_ip()

Return the IP address encoded in the request.  NB: this may be different
from the source IP in the UDP header.

=cut

sub client_ip { join '.', unpack('C4', shift->{DATA}{+VMPS_DATA_CLIENT_IP}) }

=head2 port()

The switch port name in the request.

=cut

sub port { shift->{DATA}{+VMPS_DATA_PORT_NAME} }

=head2 vlan()

Return the VLAN name from the request.  With arg, sets the VLAN name in
replies:

    $reply->vlan('your_vlan');

=cut

sub vlan {
    my $this = shift;

    if (@_)
    {
        $this->{DATA}{+VMPS_DATA_VLAN_NAME} = $_[0];
    }

    return $this->{DATA}{+VMPS_DATA_VLAN_NAME};
}

=head2 domain()

Returns the VTP domain from the request.

=cut

sub domain { shift->{DATA}{+VMPS_DATA_VTP_DOMAIN} }

=head2 packet()

Returns the "first packet" that may be encoded in the request.

=cut

sub packet { shift->{DATA}{+VMPS_DATA_PACKET} }

=head2 mac_addr()

Returns a L<Net::MAC> object with the MAC address from the request.  This
searches the dynamic mac address (0xc06), then the static mac address
(0xc08).  Returns undef if none can be found.

=cut

sub mac_addr {
    my ($this) = @_;

    my $mac = $this->_first_mac() || return undef;
    my $str = join ':', map { sprintf("%02x", $_) } unpack ('C6', $mac);

    return Net::MAC->new(mac => $str);
}

sub _first_mac {
    my $this = shift;

    for my $req (VMPS_DATA_MAC_DYNAMIC, VMPS_DATA_MAC_STATIC)
    {
        return $this->{DATA}{$req} if exists $this->{DATA}{$req};
    }

    ## pick the MAC out of the first packet!
    if (defined $this->{DATA}{+VMPS_DATA_PACKET})
    {
        return substr($this->{DATA}{+VMPS_DATA_PACKET}, 6, 6);
    }

    return undef;
}

#################################################################
## craft a response packet

=head1 GENERATING REPLIES

=head2 reply()

Create a request object with the specified error code and vlan.  Vlan may
be omitted for error codes other than VLAN_ERROR_NONE.

    my $reply = $request->reply($err_code, $vlan);

=cut

sub reply {
    my ($req, $err, $vlan) = @_;
    my $rep = dclone($req);

    $req->{TYPE}++;  # reply packet types are req type + 1
    $req->{ERR} = $err || 0;
    $req->{DATA}{+VMPS_DATA_VLAN_NAME} = $vlan || '';

    return $req;
}

###################################

=head1 GENERATING REPLIES MADE EASY

=head2 reject

Create a response object that rejects the request.

    my $reply = $request->reject();

=cut

sub reject { shift->reply(VMPS_ERROR_ACCESS_DENIED) }

###################################

=head2 accept

Accept the request, assign the user to the specified VLAN name.

    my $reply = $request->accept($vlan);

=cut

sub accept { shift->reply(VMPS_ERROR_NONE, shift) }

###################################

=head2 shutdown

Reject the request; instruct the switch to shutdown the port.

    my $reply = $request->shutdown();

=cut

sub shutdown { shift->reply(VMPS_ERROR_SHUTDOWN) }

###################################

=head2 wrong_domain

Reject the request because it is from the wrong domain.

    my $reply = $request->wrong_domain();

=cut

sub wrong_domain { shift->reply(VMPS_ERROR_WRONG_DOMAIN) }

#################################################################

1;
