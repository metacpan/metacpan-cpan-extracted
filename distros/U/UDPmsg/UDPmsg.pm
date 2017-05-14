# IPC::UDPmsg.pm

package IPC::UDPmsg;
use Socket;


#  new takes a single parm:  the port# we will listen on
sub new {
   shift;                  # first parm is package name
   my $port = shift;       # get the number of the port we listen on
   my $self = {};          # create an empty object
   my $proto  = getprotobyname('udp') ||  die "getprotobyname: cannot get proto : $!";
   $self->{PORT} = $port;
   $self->{IADDR} = Socket::inet_aton('127.0.0.1');
   socket($self->{SOCK}, AF_INET, SOCK_DGRAM, $proto)	|| die "socket: $!";
   my $servaddr = Socket::sockaddr_in( $port, $self->{IADDR} );
   bind($self->{SOCK}, $servaddr ) || die "bind: $!";
   bless $self;
   return $self;
   }


#  read will return a packet, if available, or undef.  read is non-blocking
sub read {
   my $self = shift;
   if( $self->canread() == 0 )  {
       return undef;
       }
   my $message;
   my $from = recv ($self->{SOCK}, $message, 320, 0);
   my $i = $! + 0; 
   if( $! && $i != 10054 )  {
        die "error receiving message: $i $!\n"; 
        }
   if( $i == 10054 ) { return undef; }
   my ($p, $adr) = Socket::sockaddr_in( $from );
   $self->{FROM} = $p;
   return $message;
   }


#  canread will test to see if a packet is available.  return >0 if yes
sub canread {
   my $self = shift;
   my ($rin, $win, $ein) = ('','','');
   vec($rin, fileno($self->{SOCK}), 1 ) = 1;
   $ein = $rin | $win;
   my $i = select( $rin, $win, $ein, 0);
   if( $i < 0 )  {
        my $j = $! + 0;        
        print "error receiving message: $j $!\n"; 
        next; 
        }
   return $i;
   }


# write will send a packet to another process, the parm is the port to send the packet to
sub write {
   my $self = shift;
   my $port = shift;
   my $xmsg = shift;
   my $servaddr = Socket::sockaddr_in($port, $self->{IADDR} );
   send ($self->{SOCK}, $xmsg, 0, $servaddr) || die "error sending message: $!";
   }


# from return the port number of who sent the last read packet
sub from {
   my $self = shift;
   return $self->{FROM};
   }
1;


__END__

=head1 NAME

IPC::UDPmsg - UDP Interprocess Communication Module

=head1 SYNOPSIS

The purpose of this package is to provide non-blocking message passing between
two or more processes running on the same machine, in such a way that it will
run on Win32 as well as Linux machines. 

=head1 OPERATING SYSTEMS

This module has been tested on:

=over 4

=item *
Windows 2000

=item *
Windows 98 (2nd edition)

=item *
Linux (Fedora Core 1)

=back

=head1 DESCRIPTION

The underlying structure is based on UPD packets passed thru address 127.0.0.1
and is expected to be reliable, although this may not be true on every OS.
The most important motivation for this module is have a single solution that works
under Linux and Win32.

Each process is assigned a
port.  Each process creates an object using that port number.  Passing a message
from one process to another is just a matter of providing the destination port
number.  A process can receive messages from any other process using
just the one object.  So there is only one input to monitor, no matter how many
other processes may be sending messages. The from() method will tell who sent the message, if that
information is needed, for example to send a reply.  Most important, is that the read() 
method is non-blocking, and returns immediately if no data is available.



Methods included are:

   $msg = IPC::Msg->new($listen_port);    # returns a new, ready to use, object
   $data = $msg->read();                  # returns the next message, or undef if none
   $msg->write($dest_port, $data);        # sends $data to the process assigned $dest_port
                                          #   If the $dest_port has not been created, the
                                          #   data will be silently lost.
   $port = $msg->from();                  # returns the port number of the process that
                                          #   sent the last message read.
   $stat = $msg->canread();               # returns true if data is available to read.
                                          #   Will sometimes return true even if no data.
                                          #   For example, if an error occurred. In this
                                          #   case, read() will still correctly return undef.
                                          #   Generally, there is no need to call this method,
                                          #   simply call the read() method instead.

Object Variables are:


    $self->{PORT}  = integer, the port we listen on
    $self->{IADDR} = packed, the internet address of local & remote
    $self->{SOCK}  = our UDP socket
    $self->{FROM}  = integer, the port of sender of the last message received

=head1 WARNINGS

This module provides no security.  Any process within a machine could send a message to
an open UDP port, and any machine in the Internet can send a packet to an open UDP port
unless the port is otherwise blocked by another mechanism, for example a firewall.
Therefore this module is best suited for machines that either stand along, and are not networked
or machines that are behind firewalls.  Security could be added, and will be perhaps in some
future release.

=head1 AUTHOR

Robert Laughlin ( robert@galaxysys.com )

=head1 VERSIONS

=over 4

=item *
IPC::UDPmsg version 0.11, 22 Jan 2005  Documentation improved slightly, renamed

=item *
IPC::UdpMsg version 0.10, 11 Jan 2005  Initial release

=back

=head1 COPYRIGHT

Copyright (c) 20005 Robert Laughlin <robert@galaxysys.com>. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


