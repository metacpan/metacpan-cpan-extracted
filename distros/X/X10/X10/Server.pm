
# Copyright (c) 1999-2017 Rob Fugina <robf@fugina.com>
# Distributed under the terms of the GNU Public License, Version 3.0

package X10::Server;

# this is a network server object that accepts connections via a TCP
# socket and relays the 'event requests' to an
# X10::Controller-type object

use File::Basename;
use FileHandle;
use IO::Socket;
use Storable qw(thaw);

use strict;

use X10::Event;
use X10::EventList;

sub new
{
   my $type = shift;

   my $self = bless { @_ }, $type;

   return undef unless ( $self->{controller} );

   $self->{server_port} ||= 2020;
   $self->{logger} ||= sub { $self->syslog(@_) };

   $self->{logger}->('info', "Using TCP port %s", $self->{server_port})
	if $self->{debug};

   $self->{listen_socket} = new IO::Socket(
        Domain => &AF_INET,
        Proto => 'tcp',
        LocalPort => $self->{server_port},
        Listen => 5,
        Reuse => 1,
        MultiHomed => 1,
        );

   unless ($self->{listen_socket})
   {
      warn "Problem listening on socket: ", $!;
      return undef;
   }

   $self->{connected_sockets} = [];

   $self->{controller}->register_listener($self->event_callback);

   $SIG{PIPE} = sub {};		# Ignore SIGPIPE

   return $self;
}

sub select_fds
{
   my $self = shift;

   @{$self->{connected_sockets}} =
	grep {$_}
	@{$self->{connected_sockets}};

   return
	map { $_->fileno }
	($self->{listen_socket}, @{$self->{connected_sockets}});
}

sub handle_input
{
   my $self = shift;

   my $allfd = '';
   foreach ($self->select_fds) { vec($allfd, $_, 1) = 1; }

   my $reads;
   my $errors;

   my $fdcount = select($reads=$allfd, undef, $errors=$allfd, 0);

   return unless ($fdcount);

   FILEHANDLE:
   foreach (@{$self->{connected_sockets}})
   {
      # if ( ord($reads) & (1 << $_->fileno) )
      if ( vec($reads, $_->fileno, 1) )
      {
         my $size;
         my $bytes_read = $_->sysread($size, 1);

         unless ($bytes_read == 1)
         {
            $self->{logger}->('info',
		"Disconnecting socket %s", $_->fileno) if $self->{debug};
            undef $_;
            next FILEHANDLE;
         }

         $size = ord($size);

         my $packet = '';
         $bytes_read = $_->sysread($packet, $size);

         unless ($bytes_read == $size)
         {
            warn "Error reading packet on socket %s", $_->fileno;
            undef $_;
            next FILEHANDLE;
         }

         my $event = thaw($packet);

         next FILEHANDLE unless $event;

         if ($event->isa('X10::Event') || $event->isa('X10::EventList'))
         {
            $self->{logger}->('info', "From %s: %s",
		gethostbyaddr($_->peeraddr, AF_INET) || $_->peerhost,
		$event->as_string
		);
            $self->{controller}->send($event);
         }
         else
         {
            $self->{logger}->('info', "Unknown packet type: %s", ref $event);
         }
      }
   }

   if ( ord($reads) & (1 << $self->{listen_socket}->fileno) )
   {
      my $newsocket = $self->{listen_socket}->accept;
      $self->{logger}->('info', "New connection on %s", $newsocket->fileno) if $self->{debug};
      push @{$self->{connected_sockets}}, $newsocket;
   }

}

sub event_callback
{
   my $self = shift;
   return sub { $self->handle_event(shift) };
}

sub handle_event
{
   my $self = shift;
   my $event = shift;
   my $packet = $event->nfreeze;

   foreach (@{$self->{connected_sockets}})
   {
      $_->syswrite(chr(length($packet)), 1);
      $_->syswrite($packet, length($packet));
   }
}


###

sub syslog
{
   my $level = shift;
   my $format = shift;
   my $message = sprintf($format, @_);

   my $facility = "local5";
   my $tag = sprintf "%s[%s]",
        basename($0, ".pl"),
        $$,
        ;

   my $fh = new FileHandle;
   $fh->open("|/usr/bin/logger -p $facility.$level -t $tag");

   $fh->print($message);

   $fh->close;
}




1;

