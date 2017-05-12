###########################################################################
# Copyright 2002,2004,2006 Toby Ovod-Everett.  All rights reserved.
#
# This file is distributed under the Artistic License. See
# http://www.ActiveState.com/corporate/artistic_license.htm or
# the license that comes with your perl distribution.
#
# For comments, questions, bugs or general interest, feel free to
# contact Toby Ovod-Everett at toby@ovod-everett.org
##########################################################################

use strict;

package Win32::PingICMP;

use Carp;
use Win32::API;
use Win32::Event;
use Data::BitMask;

use vars qw($VERSION);

$VERSION='0.51';

sub new {
	my $class = shift;
	my($proto, $def_timeout, $bytes) = @_;

	(defined $proto && $proto ne 'icmp') and
			croak "Win32::PingICMP::new Illegal protocol value - only 'icmp' is supported";

	my $self = {
		def_timeout => defined $def_timeout ? $def_timeout+0 : 5,
		RequestData => "\0" x (defined $bytes ? int($bytes) : 0),
	};

	$self->{IcmpHandle} = &IcmpCreateFile();
	$self->{event} = Win32::Event->new();


	bless $self, $class;
	return $self;
}

sub ping {
	my $self = shift;
	my($host, $timeout, %options) = @_;

	my $details = $self->{details} = {};

	$self->{IcmpHandle} or croak "Win32::PingICMP::ping IcmpHandle has been closed";

	$details->{host} = $host;
	if ($host =~ /^(?:\d{1,3}\.){3}(?:\d{1,3})$/) {
		$details->{ipaddr} = $host;
	} else {
		$host ne '' or croak "Win32::PingICMP::ping requires \$host parameter";
		$details->{ipaddr} = join('.', unpack('C4', (gethostbyname($host))[4]));
	}

	$details->{timeout} = (defined $timeout ? $timeout : $self->{def_timeout}) * 1000;

	my($count, $Buffer) = &IcmpSendEcho($self->{IcmpHandle}, $details->{ipaddr},
			$self->{RequestData}, (scalar(keys %options) ? \%options : undef),
			$details->{timeout});

	if (defined $Buffer) {
		$details->{buffer} = $Buffer;
		$self->parse_details($count);
	}

	return $details->{success};
}

sub ping_async {
	my $self = shift;
	my($host, $timeout, %options) = @_;

	exists $self->{details}->{pbuffer} and croak "Win32::PingICMP::ping_async called while object still waiting on ping_async";

	my $details = $self->{details} = {};

	$self->{IcmpHandle} or croak "Win32::PingICMP::ping_async IcmpHandle has been closed";

	$details->{host} = $host;
	if ($host =~ /^(?:\d{1,3}\.){3}(?:\d{1,3})$/) {
		$details->{ipaddr} = $host;
	} else {
		$host ne '' or croak "Win32::PingICMP::ping_async requires \$host parameter";
		$details->{ipaddr} = join('.', unpack('C4', (gethostbyname($host))[4]));
	}

	$details->{timeout} = (defined $timeout ? $timeout : $self->{def_timeout}) * 1000;

	$self->{event}->reset();

	my($count, $pBuffer) = &IcmpSendEcho2($self->{IcmpHandle}, ${$self->{event}},
			$details->{ipaddr}, $self->{RequestData}, (scalar(keys %options) ? \%options : undef),
			$details->{timeout});

	$details->{pbuffer} = $pBuffer if defined $pBuffer;
}

sub wait {
	my $self = shift;
	my($timeout) = @_;

	exists $self->{details}->{pbuffer} or return 1;

	if ($self->{event}->wait($timeout)) {
		$self->{event}->reset();

		my $count = &IcmpParseReplies($self->{details}->{pbuffer});
		$self->{details}->{buffer} = &CopyMemory_Read($self->{details}->{pbuffer}, 1024);
		&LocalFree($self->{details}->{pbuffer});
		delete $self->{details}->{pbuffer};

		$self->parse_details($count);

		return 1;
	} else {
		return 0;
	}
}

sub requestdata {
	my $self = shift;

	$self->{RequestData} = $_[0] if scalar(@_);
	return $self->{RequestData};
}

sub parse_details {
	my $self = shift;
	my($count) = @_;

	my $details = $self->{details};
	$count = $count || 1;
	my $poffset;

	foreach my $i (0..$count-1) {
		my $reply = $details->{replies}->[$i] = {};

		@{$reply}{qw(address status roundtriptime datasize
					reserved pdata ttl tos flags optionssize poptionsdata)} =
				unpack('a4LLSSLCCCCL', substr($details->{buffer}, 28 * $i, 28));

		if (!defined $poffset) {
			$poffset = $reply->{pdata} - 28 * $count;
		}

		$reply->{data} = substr($details->{buffer}, $reply->{pdata}-$poffset, $reply->{datasize});
		delete($reply->{pdata});
		delete($reply->{datasize});

		$reply->{optionsdata} = substr($details->{buffer}, $reply->{poptionsdata}-$poffset, $reply->{optionssize});
		delete($reply->{poptionsdata});
		delete($reply->{optionssize});

		delete($reply->{reserved});

		$reply->{address} = join(".", unpack('C4', $reply->{address}));

		$details->{success} ||= ($reply->{status} == 0);

		$reply->{status} = &IP_STATUS()->explain_const($reply->{status});
	}

	foreach my $i (qw(status roundtriptime)) {
		$details->{$i} = $details->{replies}->[0]->{$i};
	}

	$details->{success} = $details->{success} ? 1 : 0;
}

sub details {
	my $self = shift;

	return {%{$self->{details}}};
}

sub close {
	my $self = shift;

	if ($self->{IcmpHandle}) {
		&IcmpCloseHandle($self->{IcmpHandle});
		delete $self->{IcmpHandle};
	}
}

sub DESTROY {
	my $self = shift;

	$self->close();
}



{
my $call;
sub IcmpCreateFile {
	$call ||= Win32::API->new('icmp', 'IcmpCreateFile', [qw()], 'N') or
			Carp::croak("Unable to connect to IcmpCreateFile.");

	my $IcmpHandle = $call->Call() or Carp::croak(&_format_error('IcmpCreateFile'));
	return $IcmpHandle;
}
}

{
my($call_n, $call_p);
sub IcmpSendEcho {
	my($IcmpHandle, $DestinationAddress, $RequestData, $RequestOptions, $Timeout) = @_;

	$call_n ||= Win32::API->new('icmp', 'IcmpSendEcho', [qw(N N P I N P N N)], 'N') or
			Carp::croak("Unable to connect to IcmpSendEcho.");
	$call_p ||= Win32::API->new('icmp', 'IcmpSendEcho', [qw(N N P I P P N N)], 'N') or
			Carp::croak("Unable to connect to IcmpSendEcho.");

	$DestinationAddress = &ip_as_IPAddr($DestinationAddress);
	defined $DestinationAddress or return;

	my $pRequestOptions = ref($RequestOptions) eq 'HASH' ?
		pack('CCCCV', @{$RequestOptions}{qw(ttl tos flags)}, 0, 0) :
		undef;

	my $Buffer = "\0" x 1024;

	my $count = (defined $pRequestOptions ? $call_p : $call_n)->Call($IcmpHandle, $DestinationAddress,
			$RequestData, length($RequestData), $pRequestOptions,
			$Buffer, length($Buffer), $Timeout);
	
	return($count, $Buffer);
}
}

{
my($call_n, $call_p);
sub IcmpSendEcho2 {
	my($IcmpHandle, $Event, $DestinationAddress, $RequestData, $RequestOptions, $Timeout) = @_;

	$call_n ||= Win32::API->new('icmp', 'IcmpSendEcho2', [qw(N N N N N P I N N N N)], 'N') or
			Carp::croak("Unable to connect to IcmpSendEcho2.");
	$call_p ||= Win32::API->new('icmp', 'IcmpSendEcho2', [qw(N N N N N P I P N N N)], 'N') or
			Carp::croak("Unable to connect to IcmpSendEcho2.");

	$DestinationAddress = &ip_as_IPAddr($DestinationAddress);
	defined $DestinationAddress or return;

	my $pRequestOptions = ref($RequestOptions) eq 'HASH' ?
		pack('CCCCV', @{$RequestOptions}{qw(ttl tos flags)}, 0, 0) :
		undef;

	my $pBuffer = &LocalAlloc('LPTR', 1024);

	my $count = (defined $pRequestOptions ? $call_p : $call_n)->Call($IcmpHandle,
			$Event, 0, 0, $DestinationAddress,
			$RequestData, length($RequestData), $pRequestOptions,
			$pBuffer, 1024, $Timeout);
	
	return($count, $pBuffer);
}
}


{
my $call;
sub IcmpParseReplies {
	my($pBuffer) = @_;

	$call ||= Win32::API->new('icmp', 'IcmpParseReplies', [qw(N N)], 'I') or
			Carp::croak("Unable to connect to IcmpParseReplies.");

	my $count = $call->Call($pBuffer, 1024);
	return $count;
}
}


{
my $call;
sub IcmpCloseHandle {
	my($IcmpHandle) = @_;

	$call ||= Win32::API->new('icmp', 'IcmpCloseHandle', [qw(N)], 'I') or
			Carp::croak("Unable to connect to IcmpCloseHandle.");

	$call->Call($IcmpHandle) or Carp::croak(&_format_error('IcmpCloseHandle'));
}
}

{
my $call;
sub CopyMemory_Read {
	my($pSource, $Length) = @_;

	$call ||= Win32::API->new('kernel32',
				'RtlMoveMemory', [qw(P I I)], 'V') or
			Carp::croak("Unable to connect to RtlMoveMemory.");

	my $Destination = "\0"x$Length;
	$call->Call($Destination, $pSource, $Length);
	return $Destination;
}
}

{
my $call;
sub CopyMemory_Write {
	my($string, $pDest) = @_;

	$call ||= Win32::API->new('kernel32',
				'RtlMoveMemory', [qw(I P I)], 'V') or
			Carp::croak("Unable to connect to RtlMoveMemory.");
	$call->Call($pDest, $string, length($string));
}
}

{
my $call;
sub LocalAlloc {
	my($uFlags, $uBytes) = @_;

	$uFlags = &LMEM_FLAGS->build_mask($uFlags);

	$call ||= Win32::API->new('kernel32',
				'LocalAlloc', [qw(I I)], 'I') or
			Carp::croak("Unable to connect to LocalAlloc.");

	my $ptr = $call->Call($uFlags, $uBytes);
	$ptr or Carp::croak("Unable to LocalAlloc $uBytes.");
	return $ptr;
}
}

{
my $call;
sub LocalFree {
	my($pObject) = @_;

	$call ||= Win32::API->new('kernel32',
				'LocalFree', [qw(I)], 'I') or
			Carp::croak("Unable to connect to LocalFree.");

	$call->Call($pObject);
}
}

sub _format_error {
	my($func, $retval) = @_;

	(my $msg = $func.": ".Win32::FormatMessage($retval || Win32::GetLastError()))
			=~ s/[\r\n]+$//;
	return $msg;
}

sub ip_as_IPAddr {
	my($value) = @_;

	if ($value =~ /^(?:\d{1,3}\.){3}(?:\d{1,3})$/) {
		my(@values) = split(/\./, $value);
		scalar(grep {$_ > 255} @values) and croak("Unable to parse '$value' as an IP address.");
		return unpack('V', pack('N', 16777216*$values[0]+65536*$values[1]+256*$values[2]+$values[3]));
	} elsif (length($value) == 4) {
		return unpack('V', $value);
	} elsif ($value =~ /^\d+$/) {
		return unpack('V', pack('N', int($value)));
	} else {
		return;
	}
}

{
my $cache;
sub IP_STATUS {
	$cache ||= Data::BitMask->new(
			IP_SUCCESS =>                   0,
			IP_BUF_TOO_SMALL =>         11001,
			IP_DEST_NET_UNREACHABLE =>  11002,
			IP_DEST_HOST_UNREACHABLE => 11003,
			IP_DEST_PROT_UNREACHABLE => 11004,
			IP_DEST_PORT_UNREACHABLE => 11005,
			IP_NO_RESOURCES =>          11006,
			IP_BAD_OPTION =>            11007,
			IP_HW_ERROR =>              11008,
			IP_PACKET_TOO_BIG =>        11009,
			IP_REQ_TIMED_OUT =>         11010,
			IP_BAD_REQ =>               11011,
			IP_BAD_ROUTE =>             11012,
			IP_TTL_EXPIRED_TRANSIT =>   11013,
			IP_TTL_EXPIRED_REASSEM =>   11014,
			IP_PARAM_PROBLEM =>         11015,
			IP_SOURCE_QUENCH =>         11016,
			IP_OPTION_TOO_BIG =>        11017,
			IP_BAD_DESTINATION =>       11018,
		);
}
}

{
my $cache;
sub LMEM_FLAGS {
	unless ($cache) {

		$cache = Data::BitMask->new(
				LMEM_FIXED          => 0x0000,
				LMEM_MOVEABLE       => 0x0002,
				LMEM_NOCOMPACT      => 0x0010,
				LMEM_NODISCARD      => 0x0020,
				LMEM_ZEROINIT       => 0x0040,
				LMEM_MODIFY         => 0x0080,
				LMEM_DISCARDABLE    => 0x0F00,
				LMEM_VALID_FLAGS    => 0x0F72,
				LMEM_INVALID_HANDLE => 0x8000,
			);

		$cache->add_constants(
				LHND        => $cache->build_mask('LMEM_MOVEABLE LMEM_ZEROINIT'),
				LPTR        => $cache->build_mask('LMEM_FIXED LMEM_ZEROINIT'),
				NONZEROLHND => $cache->build_mask('LMEM_MOVEABLE'),
				NONZEROLPTR => $cache->build_mask('LMEM_FIXED'),
			);
	}
	return $cache;
}
}

1;

__END__

=head1 NAME

Win32::PingICMP - ICMP Ping support for Win32 based on ICMP.DLL

=head1 SYNOPSIS

  use Win32::PingICMP;
  use Data::Dumper;

  my $p = Win32::PingICMP->new();

  if ($p->ping(@ARGV)) {
    print "Ping took ".$p->details->{roundtriptime}."\n";
  } else {
    print "Ping unsuccessful: ".$p->details->{status}."\n";
  }
  print Data::Dumper->Dump([$p->details()]);



  $p->ping_async(@ARGV);

  until ($p->wait(0)) {
    Win32::Sleep(10);
    print "Waiting\n";
  }

  if ($p->details()->{status} eq 'IP_SUCCESS') {
    print "Ping took ".$p->details()->{roundtriptime}."\n";
  } else {
    print "Ping unsuccessful: ".$p->details()->{status}."\n";
  }
  print Data::Dumper->Dump([$p->details()]);

=head1 DESCRIPTION

C<Win32::PingICMP> is designed to mimic the ICMP ping functionality of
C<Net::Ping>, but because C<Win32::PingICMP> uses C<ICMP.DLL> instead of raw
sockets, it will work without local Administrative privileges under Windows
NT/2000/XP.  In addition, it supports:

=over

=item *

access to the C<ICMP_ECHO_REPLY> data structure, making it possible to get more 
accurate timing values from pings

=item *

setting the TTL, TOS, and IP Header Flags fields

=item *

operation in an asynchronous mode

=back


=head2 Installation instructions

This module requires Aldo Calpini's C<Win32::API>, available from CPAN and
via PPM, C<Win32::Event>, included with the ActivePerl distribution, and
C<Data::BitMask>, available from CPAN.


=head1 AUTHOR

Toby Ovod-Everett, toby@ovod-everett.org

=head1 ACKNOWLEDGEMENTS

Some of the documentation is copied from that for C<Net::Ping> 2.02.  Since I
was attempting to make this a replacement for that module, similarity in
documentation struck me as a Good Thing(TM).

I would never have done this if I hadn't seen
http://perlmonks.thepen.com/42739.html.  I would never have attempted this if
C<Win32::API> didn't bring the Win32 API within the reach of mere mortals
like me.

I would never have seen that if Christopher Elkin hadn't tried using
C<Win32::ProcFarm> on his web server to do monitoring via pings and asked
me why things weren't working when the code ran without admin privs.

=head1 METHODS

=over 4

=item new

  Win32::PingICMP->new([$proto [, $def_timeout [, $bytes]]]);

Create a new ping object.  All of the parameters are optional.  C<$proto>
specifies the protocol to use when doing a ping.  The only currently
supported choice is 'C<icmp>'.

If a default timeout (C<$def_timeout>) in seconds is provided, it is used
when a timeout is not given to the C<ping()> method (below).  It is
recommended that the timeout be greater than C<0> and the default, if not
specified, is C<5> seconds. Fractional values are permitted.

If the number of data bytes (C<$bytes>) is given, that many data bytes
are included in the ping packet sent to the remote host.  The default is C<0>
bytes.  The maximum is C<996>.


=item ping

  $p->ping($host [, $timeout [, %options]]);

Ping the remote host and wait for a response.  C<$host> can be either the
hostname or the IP number of the remote host.  The optional timeout should be
greater than 0 seconds and defaults to whatever was specified when the ping
object was created.  Fractional values are permitted for the timeout.  The
C<%options> hash accepts values for C<ttl>, C<tos>, and C<flags>.  If any of
the values are specified, the other values default to C<0>, so you may want
to specify them as well (especially C<ttl>!).  If none are specified, then they
default to whatever the Windows defaults are (I don't have a packet sniffer or
the expertise to determine them).

Hostname resolution is done via gethostbyname.  If the hostname cannot be found
or there is a problem with the IP number, C<undef> is returned.  Otherwise,
C<1> is returned if the host is reachable and C<0> if it is not.  For all
practical purposes, C<undef> and C<0> and can be treated as the same case.


=item ping_async

  $p->ping_async($host [, $timeout [, %options]]);

Initiates an asynchronous ping to a remote host.  Only one asynchronous ping
can be run at a time per C<Win32::PingICMP> object, but you can have multiple
C<Win32::PingICMP> objects to enable parallel pinging.  See C<ping> for an
overview of the parameters.


=item wait

  $p->wait([$timeout]);

Used in conjunction with C<ping_async> to wait for a response.  Pass the timeout 
for which the C<Win32::PingICMP> object should wait for the response during this 
call.  Multiple calls to C<wait> are permissible, as is a timeout value of 0.  
The call will return 0 if the ping is still outstanding and 1 is a response has 
been received or the ping timeout exceeded.  Once a 1 has been returned from a
call to C<wait>, you can call C<details> to get the response information.  Use
C<< $p->details()->success() >> to get a value that mirrors the return value
from C<ping>.


=item close

  $p->close();

Close the network connection for this ping object.  The network connection is
also closed by "C<undef $p>".  The network connection is automatically closed
if the ping object goes out of scope.


=item requestdata

  $p->requestdata([$requestdata]);

Get and/or set the request data to be used in the packet.


=item details

  $p->details();

Returns the gory details of the last ping attempted by the object.  This is a
reference to an anonymous hash and contains:

=over 4

=item replies

This is a reference to an anonymous array containing anonymous hash
references with the gory details of the replies to the ping.  In certain
pathological cases, it I<might> be possible for there to be multiple replies,
which is why this is an array. This would be the case if the C<IcmpSendEcho>
call returned a value greater than 1, indicating that more than one packet
was received in response.  Of course, the first packet received should cause
C<IcmpSendEcho> to return, so I'm not quite sure how this would happen.  The
Microsoft documentation is incomplete on this point - they clearly state
"Upon return, the buffer contains an array of C<ICMP_ECHO_REPLY> structures
followed by options and data."  This would seem to indicate that multiple
C<ICMP_ECHO_REPLY> structures might reasonably be expected, as does the
comment "The call returns when the time-out has expired or the reply buffer
is filled."  However, the functions appears to return as soon as there is one
entry in the reply buffer, even when there is copious space left in the reply
buffer and the time-out has yet to expire.  My best guess is that there will
never be more than one C<ICMP_ECHO_REPLY> structure returned, but I have
written the code to deal with the multiple structure case should it occur.

The anonymous hashes consist of the following elements:

=over 4

=item address

Address from which the reply packet was sent.

=item data

Data present in the reply packet.

=item flags

IP header flags from the reply packet.

=item optionsdata

Bytes from the options area following the IP header.

=item roundtriptime

Round trip time.  This appears to be inaccurate if there is no actual reply
packet (as in the case of a 'C<IP_REQ_TIMED_OUT>').

=item status

The per reply status returned by the C<IcmpSendEcho>, returned as a text
string constant.

=item tos

The type-of-service for the reply packet.

=item ttl

The time-to-live for the reply packet.

=back

=item host

The originally specified IP address or DNS name from the C<ping> call.

=item ipaddr

The IP address used for the actual ping.

=item roundtriptime

The C<roundtriptime> value for the first reply.

=item status

The C<status> value for the first reply.

=item success

The same value returned by the C<ping> call.  This is absent if an IP address
could not be determined for the host, C<1> if there were one or more replies
with a status value of 'C<IP_STATUS>', and C<0> if there were none.

=item timeout

The specified timeout value in milliseconds.

=back

=back

=cut
