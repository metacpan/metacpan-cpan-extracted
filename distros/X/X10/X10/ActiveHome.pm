
# Copyright (c) 1999-2017 Rob Fugina <robf@fugina.com>
# Distributed under the terms of the GNU Public License, Version 3.0

package X10::ActiveHome;

# Perl module for communicating with an X10 ActiveHome interface

use Data::Dumper;
use Device::SerialPort;
use FileHandle;
use IO::Select;

use strict;

use X10::Controller;
use X10::Event;

use vars qw( @ISA %hc_bits %uc_bits %fn_bits %reverse_bits );

@ISA = qw( X10::Controller );

%hc_bits = (
	A => 0x60,
	B => 0xe0,
	C => 0x20,
	D => 0xa0,
	E => 0x10,
	F => 0x90,
	G => 0x50,
	H => 0xd0,
	I => 0x70,
	J => 0xf0,
	K => 0x30,
	L => 0xb0,
	M => 0x00,
	N => 0x80,
	O => 0x40,
	P => 0xc0,
	);

%uc_bits = (
	1 => 0x06,
	2 => 0x0e,
	3 => 0x02,
	4 => 0x0a,
	5 => 0x01,
	6 => 0x09,
	7 => 0x05,
	8 => 0x0d,
	9 => 0x07,
	10 => 0x0f,
	11 => 0x03,
	12 => 0x0b,
	13 => 0x00,
	14 => 0x08,
	15 => 0x04,
	16 => 0x0c,
	);

%fn_bits = (
	A0 => 0x00,	# all off
	L1 => 0x01,	# lights on
	ON => 0x02,	# on
	OF => 0x03,	# off
	DI => 0x04,	# dim
	BR => 0x05,	# bright
	L0 => 0x06,	# lights off
	EC => 0x07,	# extended code
	HR => 0x08,	# hail request
	HA => 0x09,	# hail acknowledge
	P1 => 0x0a,	# preset dim 1
	P2 => 0x0b,	# preset dim 2
	ED => 0x0c,	# extended data
	S1 => 0x0d,	# status on
	S0 => 0x0e,	# status off
	SR => 0x0f,	# status request
	);

%reverse_bits = (
	0 => [ 'M', 13, 'A0' ],
	1 => [ 'E', 5, 'L1' ],
	2 => [ 'C', 3, 'ON' ],
	3 => [ 'K', 11, 'OF' ],
	4 => [ 'O', 15, 'DI' ],
	5 => [ 'G', 7, 'BR' ],
	6 => [ 'A', 1, 'L0' ],
	7 => [ 'I', 9, 'EC' ],
	8 => [ 'N', 14, 'HR' ],
	9 => [ 'F', 6, 'HA' ],
	10 => [ 'D', 4, 'P1' ],
	11 => [ 'L', 12, 'P2' ],
	12 => [ 'P', 16, 'ED' ],
	13 => [ 'H', 8, 'S1' ],
	14 => [ 'B', 2, 'S0' ],
	15 => [ 'J', 10, 'SR' ],
	);


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
      $self->{serial_port}->baudrate(4800);
      $self->{serial_port}->databits(8);
      $self->{serial_port}->parity('none');
      $self->{serial_port}->stopbits(1);
      $self->{serial_port}->handshake('none');
      $self->{serial_port}->stty_echo(0);

      $self->{serial_port}->read_const_time(5000);
      $self->{serial_port}->read_char_time(5);
   }

   $self->{output_word_queue} = [];
   $self->{states} = {};
   $self->{working} = 0;	# used as a lock

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

   # get a byte
   my ($count, $byte) = $self->{serial_port}->read(1);

   return unless ($count);

   $byte = unpack("C", $byte);

   if ($byte == 0xa5)
   {
      $self->ah_settime;
   }
   elsif ($byte == 0x5a)
   {
      $self->get_ahwords;
   }
   elsif ($byte == 0x55)
   {
      $self->{logger}->('info', "Interface is ready") if $self->{debug};
      $self->{is_ready} = 1;
   }
   else
   {
      $self->{logger}->('info', "Got 0x%02X -- not doing anything with it", $byte)
	if $self->{debug};
   }

}

### mostly-private methods...

sub send_word
{
   my $self = shift;
   my $word = uc(shift);

   my $good = 0;
   my $bad = 0;

   $self->{logger}->('info', "Sending: %s", $word) if $self->{debug};

   my ($hc, $fn) = $word =~ /^(.)(..)$/;

   my $packet = '';

   if ($fn eq 'DI' || $fn eq 'BR')
   {
      $self->{logger}->('info', "Sending: %s", $word) if $self->{verbose};
      # this sends ONE DIM/BRIGHT with a Header byte of 0x16
      $packet = pack("CC", 0x16, $hc_bits{$hc} | $fn_bits{$fn});
      $self->ah_sendpacket($packet);
   }
   elsif ($fn > 0 && $fn <= 16)
   {
      $self->{logger}->('info', "Sending: %s", $word) if $self->{verbose};
      # my $uc = $fn * 1;
      $packet = pack("CC", 0x04, ($hc_bits{$hc} | $uc_bits{$fn * 1}));
      $self->ah_sendpacket($packet);
   }
   # elsif ($fn eq 'ON' || $fn eq 'OF')
   elsif (exists $fn_bits{$fn})
   {
      $self->{logger}->('info', "Sending: %s", $word) if $self->{verbose};
      $packet = pack("CC", 0x06, $hc_bits{$hc} | $fn_bits{$fn});
      $self->ah_sendpacket($packet);
   }
   else
   {
      $self->{logger}->('info', "Unsupported word: %s", $word);
   }

}


### private methods -- don't call these from ouside!

sub work
{
   my $self = shift;

   return if $self->{working};

   $self->{working} = 1;
   while (my $word = shift @{$self->{output_word_queue}})
   {
      $self->send_word($word);

      $self->got_words($word);	# AH interface doesn't feed back
   }
   $self->{working} = 0;
}

sub get_ahwords
{
   my $self = shift;

   $self->{working} = 1;

   $self->{logger}->('info', "Sending 'gimme events' byte") if $self->{debug};
   $self->{serial_port}->write(chr(0xc3));

   my ($count, $bytes_to_read) = $self->{serial_port}->read(1);

   return 0 unless $count;

   $bytes_to_read = unpack("C", $bytes_to_read);

   return 0 if $bytes_to_read > 10;

   ($count, my $mask) = $self->{serial_port}->read(1);
   $mask = unpack("C", $mask);
   $bytes_to_read--;

   my @words = ();

   # foreach (1..$bytes_to_read)
   for (my $i = 0; $i < $bytes_to_read; $i++)
   {
      my $char;
      ($count, $char) = $self->{serial_port}->read(1);
      $char = unpack("C", $char);

      my $fabit = (1 << $i) & $mask;

      if ($fabit)	# function
      {
         my $hc = $reverse_bits{($char & 0xf0) >> 4}->[0];
         my $fn = $reverse_bits{$char & 0x0f}->[2];

         push @words, sprintf("%1s%2s", $hc, $fn);

         if ($fn eq 'BR' || $fn eq 'DI')
         {
            # discard dim amount for now
            my ($j1, $j2) = $self->{serial_port}->read(1);
            $i++;
         }
      }
      else		# address
      {
         my $hc = $reverse_bits{($char & 0xf0) >> 4}->[0];
         my $uc = $reverse_bits{$char & 0x0f}->[1];

         push @words, sprintf("%1s%02s", $hc, $uc);
      }
   }

   $self->got_words($self->optimize_wordlist(@words)) if @words;

   $self->{working} = 0;
   $self->work;

}

sub ah_settime
{
   my $self = shift;

   $self->{working} = 1;

   my $sum_ok = 0;
   my $bad_sums = 0;

   my @time = localtime;

   my $seconds = $time[0];
   my $minutes = $time[2] * 60 + $time[1];
   my $hours = int($minutes / 12);
   $minutes %= 120;
   my $yday = $time[7];
   my $wday = $time[6] % 7;

   $self->{logger}->('info', "Setting interface time/date...") if $self->{verbose};

   $self->{serial_port}->write(chr(0x9b));

   my $packet = pack("CCCCCC",
	0,
	$minutes,
	$hours,
	$yday / 2,
	(($yday % 1) << 7) & (1 << $wday),
	0x90,
	);

   $self->ah_sendpacket($packet);

   $self->{working} = 0;
   $self->work;
}

sub ah_sendpacket
{
   my $self = shift;
   my $packet = shift;

   my $checksum = 0;
   foreach (split(//, $packet))
   {
      $checksum += ord($_);
   }
   $checksum &= 0xff;

   my $sum_ok = 0;
   my $bad_sums = 0;

   TRY:
   while ($bad_sums < 3 && !$sum_ok)
   {
      $self->{logger}->('info', "Sending %s-byte packet: %s",
	length($packet),
	join(", ", map { sprintf("0x%02X", ord($_)) } split(//, $packet) ),
	) if $self->{debug};
      $self->{serial_port}->write($packet);

      my ($count, $sum_from_device) = $self->{serial_port}->read(1);

      if ($count == 0)
      {
         $self->{logger}->('info', "Got nothing back from the device...")
		if $self->{debug};
         $bad_sums++;
      }
      else
      {

         $sum_from_device = unpack("C", $sum_from_device);

         if ($checksum == $sum_from_device)
         {
            $self->{logger}->('info', "Good send, sending 0x00 as OK")
		if $self->{debug};
            $self->{serial_port}->write(chr(0x00));

            ($count, my $readybyte) = $self->{serial_port}->read(1);
            if ($count != 1)
            {
               $self->{logger}->('info', "Didn't get ready byte")
		if $self->{debug};
               $bad_sums++;
            }
            elsif (ord($readybyte) != 0x55)
            {
               $self->{logger}->('info', "Expected ready 0x55, got 0x%02X", $readybyte)
		if $self->{debug};
               $bad_sums++;
            }
            else
            {
               $self->{is_ready} = 1;
               $sum_ok = 1;
            }
         }
         else
         {
            $self->{logger}->('info', "Expected checksum 0x%02X, got 0x%02X",
		$checksum, $sum_from_device) if $self->{debug};
            $bad_sums++;
         }
      }
   }

   if ($sum_ok)
   {
      $self->{logger}->('info', "Packet send successful") if $self->{debug};
   }
   else
   {
      $self->{logger}->('info', "Aborting send: too many bad checksums") if $self->{debug};
   }

   return $sum_ok;
}

sub ah_ring_signal
{
   my $self = shift;
   my $bool = shift || 0;

   $self->ah_sendpacket(chr($bool ? 0xeb : 0xdb));
}

sub DESTROY
{
   my $self = shift;

   $self->{serial_port}->close;
}

### utility functions -- not called as methods



1;

