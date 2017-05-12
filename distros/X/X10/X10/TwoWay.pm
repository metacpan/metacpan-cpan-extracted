
# Copyright (c) 1999-2017 Rob Fugina <robf@fugina.com>
# Distributed under the terms of the GNU Public License, Version 3.0

package X10::TwoWay;

# Perl module for communicating with a TwoWay/TW523 combination

use Data::Dumper;
use Device::SerialPort;
use FileHandle;
use IO::Select;

use strict;

use X10::Controller;

use vars qw( @ISA );

@ISA = qw( X10::Controller );

### constructors

sub new
{
   my $type = shift;

   my $self = new X10::Controller( @_ );
   bless $self, $type;

   unless ($self->{test})
   {
      return undef unless $self->{port};

      $self->{serial_port} = new Device::SerialPort($self->{port});
      $self->{serial_port}->baudrate(2400);
      $self->{serial_port}->databits(8);
      $self->{serial_port}->parity('none');
      $self->{serial_port}->stopbits(1);
      $self->{serial_port}->handshake('none');
      $self->{serial_port}->stty_echo(0);

      $self->{serial_port}->read_const_time(2000);
      $self->{serial_port}->read_char_time(5);
   }

   return $self;
}


### public methods (most overriding parent class)

sub select_fds
{
   my $self = shift;

   if ($self->{test})
   {
      return ();
   }
   else
   {  
      return ($self->{serial_port}->{FD});
   }
}

sub handle_input
{
   my $self = shift;

   return if $self->{test};

   $self->get_word;
}

### mostly-private methods...

sub send_word
{
   my $self = shift;
   my $word = shift;

   my $good = 0;
   my $bad = 0;

   while ($bad < 5 && !$good)
   {
      write_paced($self->{serial_port}, 100, $word, "\r") unless $self->{test};

      if ($self->get_ack($word))
      {
         $good = 1;
      }
      else
      {
         $bad++;
      }
   }

   if ($bad >= 5)
   {
      warn "Too many bad -- aborting!";
   }

}

sub get_ack
{
   my $self = shift;
   my $word = shift;

   return 0 unless $word;

   # this is done so we can fake out the event handlers when we're in test mode
   if ($self->{test})
   {
      $self->got_words($word);
      return 1;
   }
   else
   {
      my $got = $self->get_word;
      return ($got eq $word);
   }
}

sub get_word
{
   my $self = shift;
   my $buf = '';
   my $word;

   READ_BYTE:
   while (my ($count, $char) = $self->{serial_port}->read(1) )
   {
      $buf .= $char;

      if ($buf =~ /!([a-p](\d\d|on|of|l1|a0|br|di))\r\n/is)
      {
         $word = $1;
         last READ_BYTE;
      }
   }

   # NOTE: data in $buf is discarded if we timeout before finding a word

   $self->{logger}->('info', "Word: %s", $word) if $self->{verbose};

   $self->got_words($word) if $word;

   return $word;
}

sub DESTROY
{
   my $self = shift;
   $self->{serial_port}->close;
}

### utility functions -- not called as methods

sub write_paced
{
   my $serial_port = shift;
   my $pace = shift;

   foreach ( map { split(//) } @_ )
   {
      select(undef, undef, undef, $pace/2000);
      $serial_port->write($_);
      select(undef, undef, undef, $pace/2000);
   }
}

sub usleep
{
   my $usecs = shift;
   select(undef, undef, undef, $usecs / 1000000);
}

1;

