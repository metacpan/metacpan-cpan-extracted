# The WebCache::ICP Perl module
# $Id: ICP.pm,v 1.1 1999/04/27 16:35:21 martin Exp $

# Copyright (c) 1999 Martin Hamilton.  All rights reserved.

# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

package WebCache::ICP;

use strict;
use vars qw($VERSION);

use Carp;
use Socket;
use vars qw($VERSION %CODES);

$VERSION = "1.00";


# ICP request and response packet opcodes
%CODES=(
    "OP_INVALID"      =>  0,
    "OP_QUERY"        =>  1,
    "OP_HIT"          =>  2,
    "OP_MISS"         =>  3,
    "OP_ERR"          =>  4,
    "UNUSED5"         =>  5,
    "UNUSED6"         =>  6,
    "UNUSED7"         =>  7,
    "UNUSED8"         =>  8,
    "UNUSED9"         =>  9,
    "OP_SECHO"        => 10,
    "OP_DECHO"        => 11,
    "UNUSED12"        => 12,
    "UNUSED13"        => 13,
    "UNUSED14"        => 14,
    "UNUSED15"        => 15,
    "UNUSED16"        => 16,
    "UNUSED17"        => 17,
    "UNUSED18"        => 18,
    "UNUSED19"        => 19,
    "UNUSED20"        => 20,
    "OP_MISS_NOFETCH" => 21,
    "OP_DENIED"       => 22,
    "OP_HIT_OBJ"      => 23,
);


sub new {
  my ($this, $that) = @_;
  my ($class) = ref($this) || $this;
  my ($self) = [];
  bless $self, $class;

  $self = $self->burst($that) if defined($that);

  unless (defined($that)) {
    # some vaguely plausible defaults
    $self->opcode("OP_QUERY");
    $self->version(2);
    $self->sequence(1);
    $self->options(0);
    $self->option_data(0);
  }

  return $self;
}


# get/set header/payload values out of a packet
sub opcode    {
  my ($self, $opcode) = @_;

  return $self->[0] unless defined($opcode);

  if ($opcode =~ /^\d+$/) {
    $self->[0] = $opcode;
  } else {
    $self->[0] = $CODES{$opcode};
  }
}
sub version     { my $self = shift; @_ ? $self->[1] = shift : $self->[1]; }
sub length      { my $self = shift; @_ ? $self->[2] = shift : $self->[2]; }
sub sequence    { my $self = shift; @_ ? $self->[3] = shift : $self->[3]; }
sub options     { my $self = shift; @_ ? $self->[4] = shift : $self->[4]; }
sub option_data { my $self = shift; @_ ? $self->[5] = shift : $self->[5]; }
sub peer_addr   { my $self = shift; @_ ? $self->[6] = shift : $self->[6]; }
sub payload     { my $self = shift; @_ ? $self->[7] = shift : $self->[7]; }


# turn an ICP object into a wire-format packet
sub assemble {
  my ($self) = @_;
  my ($payload_length);
  my ($packet_template);

  # fixed size header is 20 bytes
  if ($self->opcode == 1) {
    # OP_QUERY (1) prefixes URL with 4 byte addr
    $payload_length = length($self->payload) + 4;
    $packet_template = "CCnNNNNN";
  } else {
    $payload_length = length($self->payload) + 0;
    $packet_template = "CCnNNNN";
  }

  my ($packet) = pack($packet_template,
                    int($self->opcode),   # C opcode
                    2,                    # C protocol version
                    20 + $payload_length, # n packet length
                    int($self->sequence), # N sequence number
                    int($self->options),  # N option flags
                    0,                    # N option data
                    0);                   # N client IP addr

  $packet .= $self->payload;
  #$packet .= '\0'; # XXX URL is null-terminated?

  return $packet;
}


# burst open wire-format packet and pull out ICP object
sub burst {
  my ($self, $data) = @_;

  # XXX should be capable of using burst to unpack type 1 packets
  my ($payload_length) = length($data) - 20;
  my ($packet_template) = sprintf 'CCnNNNNa%d', $payload_length;
  return bless [ unpack($packet_template, $data) ], "WebCache::ICP";
}


# dump out header/payload from an ICP object in human readable form
sub dump {
  my ($self) = @_;

  printf "Opcode: %0x\n", $self->opcode;
  printf "Version: %0x\n", $self->version;
  printf "Packet length: %d\n", $self->length;
  printf "Sequence number: %d\n", $self->sequence;
  printf "Option flags: %0x\n", $self->options;
  printf "Option data: %0x\n", $self->option_data;
  printf "Peer address: %0x\n", $self->peer_addr;
  printf "Payload: %s\n", $self->payload;
}


# dump out ICP object in hex
sub hex_dump {
  my ($self) = @_;
  my ($packet_template) = sprintf 'CCnNNNNa%d', ($self->length - 20);
  my ($packet) = pack($packet_template, $self->opcode, $self->version,
                        $self->length, $self->sequence, $self->options,
                        $self->option_data, $self->peer_addr, $self->payload);
  print unpack("H*", $packet) . "\n";
}


# send ICP packet to peer
sub send {
  my ($self, %args) = @_;
  my ($sock, $flags, $iaddr, $sin, $request);

  if (defined($args{fd})) {
    $sock = $args{fd};
    $sin = $args{sin};
  } else {
    my $proto = getprotobyname('udp');
    socket(SOCK, PF_INET, SOCK_DGRAM, $proto);
    $sock = *SOCK{IO};
    $iaddr = gethostbyname($args{host} || "localhost");
    $sin = sockaddr_in(($args{port} || 3130), $iaddr);
  }

  $request = $args{packet} || $self->assemble;
  return -3 unless send($sock, $request, 0, $sin);
  close(SOCK) unless defined($args{fd});
}


# receive ICP packet from peer
sub recv {
  my ($self, %args) = @_;
  my ($flags, $iaddr, $sin, $response);
  my ($sock, $flags, $iaddr, $sin, $request);
  my ($their_sin);

  if (defined($args{fd})) {
    $sock = $args{fd};
  } else {
    my $proto = getprotobyname('udp');
    socket(SOCK, PF_INET, SOCK_DGRAM, $proto);
    $sock = *SOCK{IO};
    $sin = sockaddr_in(($args{port} || 3130), pack("N", 0));
    bind($sock, $sin) || croak "$0: couldn't bind: $!";;
  }

  ($their_sin = recv($sock, $response, 1024, 0))
                                          || croak "$0: couldn't recv: $!";
  close(SOCK) unless defined($args{fd});
  return $response;
}


# implements an ICP server
sub server {
  my ($self, %args) = @_;
  my ($flags, $iaddr, $sin, $response);
  my($their_sin,$rin,$rout,$nfound,$timeleft);
  my ($sock, $flags, $iaddr, $sin, $request);
  my ($their_sin);
  my ($callback);

  if (defined($args{fd})) {
    $sock = $args{fd};
  } else {
    my $proto = getprotobyname('udp');
    socket(SOCK, PF_INET, SOCK_DGRAM, $proto) || croak "$0: socket: $!";
    $sock = *SOCK{IO};
    $sin = sockaddr_in(($args{port} || 3130), pack("N", 0));
    bind($sock, $sin) || croak "$0: couldn't bind: $!";;
  }

  if (defined($args{callback})) {
    $callback = $args{callback};
  } else {
    $callback = \&server_stub;
  }

  while(1) {
    ($their_sin = recv($sock, $request, 1024, 0))
                                      || croak "$0: couldn't recv: $!";
    $self->$callback($sock, $their_sin, $request);
  }
}


# default callback for server
sub server_stub {
  my ($self, $fd, $sin, $request) = @_;

  $self = $self->burst($request);
  $self->dump;
  $self->opcode("OP_HIT");
  $self->send ( fd => $fd, sin => $sin );
  print "---------------------------------------------------------\n";
}


1;
__END__


=head1 NAME

B<WebCache::ICP> - Internet Cache Protocol client and server

=head1 SYNOPSIS

  use WebCache::ICP;

  $i = new WebCache::ICP;
  $i->opcode("OP_QUERY");
  $i->payload("http://www.w3.org/");
  $i->send(host => $host, port => $port);
  $i->recv;
  $i->dump;
  $i->hex_dump;

  $j = new WebCache::ICP($packet);
  $j->dump;

  $k = new WebCache::ICP;
  $k->server(callback => \&not_so_stubby);

  # sample callback, just prints URLs requested
  sub not_so_stubby {
    my ($self, $fd, $sin, $request) = @_;
    $self = $self->burst($request);
    print "url: " . $self->payload . "\n";
    $self->opcode("OP_MISS_NOFETCH");
    $self->send(fd => $fd, sin => $sin);
  }

=head1 DESCRIPTION

This Perl module implements client and server side support for the
Internet Cache Protocol, as defined in RFCs 2186 and 2187.  It provides
methods for creating ICP packets, breaking the contents of ICP packets
out into a Perl object, sending and receiving ICP packets, plus a simple
ICP server which you can bolt your own callback functions onto.

NB This is just a first release, so expect the unexpected!  Many features
either don't work properly, or don't exist yet :-)

=head1 METHODS

ICP objects can either be created anew:

  $i = new WebCache::ICP;

Or created based on the contents of a variable, which it's assumed is a
raw ICP packet, fresh off the wire:

  $i = new WebCache::ICP($packet);

If you don't supply a variable from which the ICP object should be
created, we try to set you up with some sensible defaults - creating
a query packet (opcode 2 or "OP_QUERY"), protocol version 2, a
sequence number of 1, and no options.

Note that you can re-use a WebCache::ICP object over and over again, so
as to avoid incurring the overheads of object creation and destruction
with high volume client/server applications.

The following methods may be used on ICP objects to get or (with
optional parameter) set the corresponding fields in the ICP packet:

=over 4

=item $i->opcode

This method fetches the ICP opcode from the object.  This is normally
a number between 0 and 23.  With a numeric parameter, the opcode for
the object is set to this number.  You can also supply one of the
following strings as an alternative to the numeric parameter:

    "OP_INVALID"
    "OP_QUERY"
    "OP_HIT"
    "OP_MISS"
    "OP_ERR"
    "UNUSED5"
    "UNUSED6"
    "UNUSED7"
    "UNUSED8"
    "UNUSED9"
    "OP_SECHO"
    "OP_DECHO"
    "UNUSED12"
    "UNUSED13"
    "UNUSED14"
    "UNUSED15"
    "UNUSED16"
    "UNUSED17"
    "UNUSED18"
    "UNUSED19"
    "UNUSED20"
    "OP_MISS_NOFETCH"
    "OP_DENIED"
    "OP_HIT_OBJ"

Each of these will be interpolated into the appropriate ICP opcode
internally by the WebCache::ICP module.  We don't check the opcode
number is valid, so if you wanted to, you could put opcodes greater
than 23 in here...

=item $i->version

This method lets you set or fetch the ICP protocol version number.
Currently this is set to 2 for most/all real world applications of ICP,
but you could put the version number of your choice in here.

=item $i->length

This method lets you fetch the packet length of an ICP object when
it's expressed as an on-the-wire packet.  This may get a bit confused
if you manipulate the contents of an ICP object, but it's 'guaranteed'
to be correct if you create a new ICP object based on a raw packet.

=item $i->sequence

This method lets you fetch (or, with an optional parameter: set), the
ICP sequence number.

=item $i->options

This method lets you fetch or set the options field for the ICP object.
At the moment we simply expect you to supply a plausible value for this.
In future there will probably be a more sophisticated way to set a
particular option by name.

=item $i->option_data

This method lets you fetch or set the supplementary data associated with
the options set for the ICP object.  Again we assume that you know what
you want to put in here!

=item $i->peer_addr

This method lets you fetch or set the source address associated with
the ICP packet once sent/received down the wire.  In practice this is
normally set to all zeroes.

=item $i->payload

This method lets you fetch or set the payload proper of the ICP packet.

=item $i->assemble

This method turns an ICP object into an on-the-wire format packet, which
is returned as its result.  Note that it adds a 4 byte null filled prefix
to the payload of ICP query packets.  This is normally used in ICP to
record the IP address of the machine which is causing the ICP query to
be sent.

=item $i->burst

This method takes a raw ICP packet and turns it into an ICP object.  It's
used behind the scenes by the 'new' method when constructing an ICP object
from an on-the-wire packet, but you can also call it directly.

=item $i->dump

This method dumps out the contents of the various ICP header fields and
the payload, as interpreted by the WebCache::ICP module, to STDOUT.  It's
intended for use in debugging.

=item $i->hex_dump

This method tries to create an ICP on-the-wire format packet and then dump
it out to STDOUT, based on the WebCache::ICP object being operated on.

=item $i->send

This method causes an ICP wire format packet to be sent.  It can be used
in a variety of ways depending on the options which it's called with, viz.

If you already have the packet you want to send, you can supply the
'packet' parameter:

  $i->send(packet => $p);

If not, the packet will be generated from the WebCache::ICP object being
operated on, using the 'assemble' method.

If you already have an active socket for talking to the server, you can
supply its file handle and packed IP address/port using the 'fd' and
'sin' parameters:

  $i->send(fd => \*SOCK, sin => $s);

If not, you'll need to supply the 'host' and 'port' parameters - the
socket will automatically be created, and then destroyed after the packet
is sent.

=item $i->recv

This method waits for an ICP packet to arrive, and then returns the raw
packet for further processing.  You can either pass the file handle of a
socket which is already bound to the port:

  $i->recv(fd => \*SOCK);

or you can supply the port number yourself:

  $i->recv(port => 3131);

in which case the 'recv' method will take care of getting you a socket
and destroying it later.

=item $i->server

This method uses pretty much all of the other code to implement a simple
ICP server with user defined callbacks to be executed on receipt of an
incoming ICP packet.  Once it is called, the flow of execution will pass
here, and the program will block waiting for packets to arrive...

You can either pass the file handle of a socket which is already bound
to the port you want to listen on:

  $i->server(fd => \*SOCK);

or you can supply the port number yourself:

  $i->server(port => 3131);

in which case the 'server' method will take care of getting you a socket
and destroying it later.

The ICP server comes with a simple built-in callback function, which
always returns an ICP hit ("OP_HIT") response using the 'send' method, and
logs the packet received to STDOUT using the 'dump' method.  This default
callback will be invoked if you run the server without nominating an
alternative.

If you supply a reference to a function in the 'callback' parameter, the
'server' method will try to pass this the packet contents and peer info
on receipt of each packet, e.g.

  $i->server(callback => \&not_so_stubby);

The return code from the callback function isn't used in the 'server'
method.  The callback function will be supplied with three parameters:

  1) the file descriptor which the packet was received on
  2) the packed IP address/port number from which it was received
  3) the raw on-the-wire ICP packet which was received

=back

=head1 TODO

Need to factor in an opcode for ICP referrals.

Should have ability to get/set options by name.

Should be possible to run ICP over TCP - cf. HTCP, though.

Should allow for holding connection open when running over TCP.

Should be possible to have the ICP server running in non-blocking mode,
possibly as part of a larger set of file handles using select.

=head1 BUGS

This is just a first release, so expect the unexpected!

The hex_dump method doesn't take account of the 4 byte client IP address
prefix to the payload of ICP query packets.

We currently bind to INADDR_ANY when listening for incoming ICP packets,
but we should probably let the luser choose which interface(s) to use.

Timeouts and corrupted packets aren't handled gracefully yet.

There's no way with the 'recv' method to find out the peer's IP address
and port number, since we only return the raw packet contents.

Originally used IO::Socket, but stopped because it seemed to leak memory.

=head1 COPYRIGHT

Copyright (c) 1999, Martin Hamilton E<lt>martinh@gnu.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

It was developed by the JANET Web Cache Service, with funding from the
Joint Information Systems Committee (JISC) of the UK Higher Education
Funding Councils and TERENA, the Trans-European Research and Education
Networking Association.

=head1 AUTHOR

Martin Hamilton E<lt>martinh@gnu.orgE<gt>

