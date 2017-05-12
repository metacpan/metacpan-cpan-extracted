
# Copyright (c) 1999-2017 Rob Fugina <robf@fugina.com>
# Distributed under the terms of the GNU Public License, Version 3.0

package X10::FireCracker;

# Perl module for communicating with an X10 FireCracker controller

use FileHandle;
use Device::SerialPort;

use strict;

use X10::Controller;

use vars qw(
	@ISA
	$cmd_prefix
	%house_codes
	%house_commands
	%unit_codes
	%unit_commands
	$cmd_suffix
	);

@ISA = qw( X10::Controller );

$cmd_prefix = 0xd5aa;

# commands will be assembled as either:
	# house_code | house_command
	# OR
	# house_code | unit_code | unit_command

%house_codes = (
	'A' => 0x6000, 'B' => 0x7000, 'C' => 0x4000, 'D' => 0x5000,
	'E' => 0x8000, 'F' => 0x9000, 'G' => 0xa000, 'H' => 0xb000,
	'I' => 0xe000, 'J' => 0xf000, 'K' => 0xc000, 'L' => 0xd000,
	'M' => 0x0000, 'N' => 0x1000, 'O' => 0x2000, 'P' => 0x3000,
	);
%house_commands = (
	'ALL OFF'    => 0x0080,
	'ALL ON'     => 0x0091,
	'LIGHTS OFF' => 0x0084,
	'LIGHTS ON'  => 0x0094,
	'DIM'        => 0x0098,
	'BRIGHT'     => 0x0088,
	);
%unit_codes = (
	1  => 0x0000, 2  => 0x0010, 3  => 0x0008, 4  => 0x0018,
	5  => 0x0040, 6  => 0x0050, 7  => 0x0048, 8  => 0x0058,
	9  => 0x0400, 10 => 0x0410, 11 => 0x0408, 12 => 0x0418,
	13 => 0x0440, 14 => 0x0450, 15 => 0x0448, 16 => 0x0458,
	);
%unit_commands = (
	'OFF'    => 0x0020,
	'ON'     => 0x0000,
	);
$cmd_suffix = 0xad;


### constructors

sub new
{
   my $type = shift;

   my $self = new X10::Controller( @_ );
   bless $self, $type;

   $self->{serial_port} = new Device::SerialPort($self->{port})
	|| die "Couldn't connect to FireCracker port ", $self->{port},
		": ", $!, "\n";

   die "Need IOCTL constants for DTR/RTS manipulation -- see docs for Device::SerialPort"
	unless $self->{serial_port}->can_ioctl;

   $self->{serial_port}->dtr_active(0);
   $self->{serial_port}->rts_active(0);

   &usleep(100000);

   return $self;
}


### public methods (most overriding parent class)

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

   my $hc = $event->house_code;
   my $uc = $event->unit_code;
   my $fn = $event->func;

   # my $house = '[a-p]';
   # my $unit = '0?\d|1[01-6]';

   if ($fn eq 'ON' || $fn eq 'OFF')
   {
      $self->send_fcword(
	$house_codes{$hc}
	| $unit_codes{$uc}
	| $unit_commands{$fn}
	);

      $self->got_event($event);
   }
   elsif ($fn eq 'DIM' || $fn eq 'BRIGHT')
   {
      $self->send_fcword(
	$house_codes{$hc}
	| $unit_codes{$uc}
	| $unit_commands{'ON'}
	);
      $self->send_fcword(
	$house_codes{$hc}
	| $house_commands{$fn}
	);

      $self->got_event($event);
   }
   elsif ( ($uc eq 'ALL' && $fn eq 'OFF')
	|| ( $uc eq 'LIGHTS' && $fn eq 'ON' ) )
   {
      $self->send_fcword(
	$house_codes{$hc}
	| $house_commands{"$uc $fn"}
	);

      $self->got_event($event);
   }
   else
   {
      warn "Unrecognized event: ", $event->as_string, "\n";
      return 0;
   }

}

### private methods -- don't call these from ouside!

sub send_fcword
{
   my $self = shift;
   my $fcword = shift;

   $self->{serial_port}->dtr_active(1);
   $self->{serial_port}->rts_active(1);
   &usleep(200000);

   $self->send_bits($cmd_prefix, 16);
   $self->send_bits($fcword, 16);
   $self->send_bits($cmd_suffix, 8);

   # again, should end up this way, but...
   $self->{serial_port}->dtr_active(1);
   $self->{serial_port}->rts_active(1);
   &usleep(200000);

   $self->{serial_port}->dtr_active(0);
   $self->{serial_port}->rts_active(0);
   &usleep(100000);
}

sub send_bits
{
   my $self = shift;

   my $word = shift;

   my $length = shift || 16;

   for (my $i = 1 << ($length-1); $i; $i = $i >> 1)
   {
      $self->send_bit($i & $word);
   }
}

sub send_bit
{
   my $self = shift;

   return 0 unless exists $self->{serial_port};

   my $boolean = shift;

   if ($boolean)
   {
      # send a 'one' bit
      $self->{serial_port}->pulse_dtr_off(2);	# milliseconds
      &usleep(1400);
   }
   else
   {
      # send a 'zero' bit
      $self->{serial_port}->pulse_rts_off(2);	# milliseconds
      &usleep(1400);
   }

   # 'clock'
   &usleep(2000);

}

### utility functions -- not called as methods

sub usleep
{
   my $usecs = shift;
   select(undef, undef, undef, $usecs / 1000000);
}

1;

