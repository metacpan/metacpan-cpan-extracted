
# Copyright (c) 1999-2017 Rob Fugina <robf@fugina.com>
# Distributed under the terms of the GNU Public License, Version 3.0

package X10::Network;
use vars qw(@ISA);
@ISA = qw(X10::Controller);

# this is an X10::Controller-type object, used to control X10 devices
# via a process running an X10::Server object somewhere else

use Storable qw(thaw);
use IO::Socket;

use strict;

use X10::Controller;

### constructors

sub new
{
   my $type = shift;

   my $self = new X10::Controller( @_ );
   bless $self, $type;

   $self->{socket} = new IO::Socket(
        Domain => &AF_INET,
        Proto => 'tcp',
        PeerAddr => $self->{server} || 'x10',
        PeerPort => $self->{server_port} || 2020,
        );

   unless ($self->{socket})
   {
      warn "Problem connecting socket: ", $!;
      return undef;
   }

   return $self;
}


### public methods (most overriding parent class)

sub select_fds
{
   my $self = shift;
   return ($self->{socket}->fileno);
}

sub handle_input
{
   my $self = shift;

   $self->get_event;
}

sub send
{
   my $self = shift;
   foreach (@_)
   {
      $self->send_one($_);
   }
}

sub send_one
{
   my $self = shift;
   my $event = shift;
   my $packet = $event->nfreeze;
   $self->{socket}->syswrite(chr(length($packet)), 1);
   $self->{socket}->syswrite($packet, length($packet));
}

sub get_event
{
   my $self = shift;

   my $size;
   my $bytes_read = $self->{socket}->sysread($size, 1);

   unless ($bytes_read == 1)
   {
      $self->{socket}->close;
      die "Lost connection to X10 server: ", $!;
   }

   $size = ord($size);

   my $packet = '';
   $bytes_read = $self->{socket}->sysread($packet, $size);

   unless ($bytes_read == $size)
   {
      $self->{socket}->close;
      die "Lost connection to X10 server: ", $!;
   }

   my $event = thaw($packet);

   next undef unless $event;

   unless ($event->isa('X10::Event'))
   {
      warn "Unknown packet type: ", ref $event;
      return undef;
   }

   $self->got_event($event);

   return $event;
}

### mostly-private methods...

sub DESTROY
{
   my $self = shift;
   $self->{socket}->close;
}

### utility functions -- not called as methods



1;

