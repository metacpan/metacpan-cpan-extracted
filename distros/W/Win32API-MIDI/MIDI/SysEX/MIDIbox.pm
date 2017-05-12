#!/usr/local/bin/perl
#
#	MIDIbox.pm : MIDIbox System Exculsive support functions
#
#	Copyright (c) 2003 Hiroo Hayashi.  All rights reserved.
#
#	This program is free software; you can redistribute it and/or
#	modify it under the same terms as Perl itself.
#
#	$Id: MIDIbox.pm,v 1.2 2003-04-13 22:54:26-05 hiroo Exp $

# http://www.uCApps.de/
# Free MIDI DIY Projects by Thorsten Klose

package Win32API::MIDI::SysEX::MIDIbox;
my $ver = '$Id: MIDIbox.pm,v 1.2 2003-04-13 22:54:26-05 hiroo Exp $';

=head1 NAME

Win32API::MIDI::SysEX::MIDIbox - Perl Module for MIDIbox System
Exclusive Message.

=head1 SYNOPSIS

  use Win32API::MIDI::SysEX::MIDIbox;
  # by default 'MIDIbox16E'
  $se = new Win32API::MIDI::SysEX::MIDIbox(modelName => 'MIDIbox64');

=head1 DESCRIPTION

=head2 Overview

Win32API::MIDI::SysEX::MIDIbox is submodule of Win32API::MIDI::SysEX.
Its object inherits his parents methods.

This module is still under development and most of function are not
debugged yet.  And the this module may have to be renamed as
MIDI::SysEX::MIDIbox in the future, since this module is dependent
with Microsoft Windows.

=cut

use Carp;
use strict;

#BEGIN { $Exporter::Verbose=1 }
use vars qw($VERSION @ISA);
$VERSION = $ver =~ m/\s+(\d+\.\d+)\s+/;
@ISA = qw(Win32API::MIDI::SysEX);
use Win32API::MIDI::SysEX qw(SOX EOX);

# The following data is gathered by WWW searching.
# Report to author if you know about other models.
my %fmt = (#			   model ID	writeDump data size
	   'MIDIbox Plus'	=> [0x2,	1024],
	   'MIDIbox64'		=> [0x3,	4096],
	   'MIDIIO128'		=> [0x4,	4096], # ?
	   'MIDIbox16E'		=> [0x5,	4096],
	  );

=head2 Create an Object

=over 4

=item new Win32API::MIDI::SysEX::MIDIbox([model [, device_ID]])

Currently supported C<model> are;

		 readRequest writeDump writePartialDump Request Bank Acknowledge/Ping
  'MIDIbox Plus'	x	x (1024)				X
  'MIDIbox64'		x	x (4096)	X		X	X
  'MIDIIO128'		x	x (?)					X
  'MIDIbox16E'		x	x (4096)	X		X	X

By default 'MIDIbox16E' is used.

=back

=cut

sub default_deviceID {
    5;
}

sub default_manufacturersID {
    #0x7e0000;			# Otari???
    0x7D,			# non-commercial use
}

sub default_modelName {
    'MIDIbox16E';		# TBD
}

sub new_hook {
    my $self = shift;
    $self->{mdlID}  = $fmt{$self->{mdlName}}->[0] unless defined $self->{mdlID};
    # manufacturers ID for 'Otari' was used accidentally on old machines.
    $self->{mID} = 0x7e0000
	if ($self->{mdlName} eq 'MIDIbox Plus'
	    || $self->{mdlName} eq 'MIDIbox64'
	    || $self->{mdlName} eq 'MIDIIO128'
	    || $self->{mdlName} eq 'MIDIbox16E');

    # data size for writeDump()
    $self->{_WDSize} = $fmt{$self->{mdlName}}->[1];
}

########################################################################

=head2 Read Request

=over 4

=item readRequest(void)

=back

=cut

#    F0 00 00 7E 45 01 F7                - Read Request
sub  readRequest {
    my $self = shift;

    pack('C*', SOX, $self->mID2array(),
	 ((($self->{devID} - 1) & 7) << 4) | $self->{mdlID} & 0xf,
	 0x01,
	 EOX);
}

=head2 Write Dump

=over 4

=item writeDump(data)

=back

=cut

#    F0 00 00 7E 45 02 ..dump.. F7       - Write Dump
sub  writeDump {
    my ($self, $data) = @_;

    my $size = $self->{_WDSize};
    pack('C*', SOX, $self->mID2array(),
	 ((($self->{devID} - 1) & 7) << 4) | $self->{mdlID} & 0xf,
	 0x02)
	. pack("a${size}C1", $data, EOX);
}

=head2 Write Partial Dump

=over 4

=item writePartialDump(address, data)

=back

=cut

#    F0 00 00 7E 45 04 AH AL ..dump.. F7 - Write Partial Dump

sub  writePartialDump {
    my ($self, $address, $data) = @_;

    pack('C*', SOX, $self->mID2array(),
	 ((($self->{devID} - 1) & 7) << 4) | $self->{mdlID} & 0xf,
	 0x04,
	 ($address >> 8) & 0x7f,
	 ($address >> 1) & 0x7f,
	 ($data >> 8) & 0x7f,
	 ($data >> 1) & 0x7f,
	 EOX);
}

=head2 Reqeust Bank

=over 4

=item requestBank(m, n)

	m = 0 to 7 (SubBank - set of Banks with a BankStick Bank)
	n = 0 to 3 (BankStick Bank)

=back

=cut

#    F0 00 00 7E 45 08 0n F7             - Request Bank
sub  requestBank {
    my ($self, $m, $n) = @_;

    pack('C*', SOX, $self->mID2array(),
	 ((($self->{devID} - 1) & 7) << 4) | $self->{mdlID} & 0xf,
	 0x08,
	 (($m & 7) << 4) | $n & 0xf,
	 EOX);
}

=head2 Acknowledge/Ping

=over 4

=item acknowledgePing(void)

=back

=cut

#    F0 00 00 7E 45 0F F7                - Acknowledge/Ping
sub acknowledgePing {
    my $self = shift;

    pack('C*', SOX, $self->mID2array(),
	 ((($self->{devID} - 1) & 7) << 4) | $self->{mdlID} & 0xf,
	 0x0f,
	 EOX);
}

=head2 Dump Program/Data

=over 4

=item dumpProgramData(address, data)

=back

=cut

#    F0 00 00 7E 40 <device-id> 02 <AH> <AL> <CH> <CL> <dump> <checksum> F7
#
#    <AH>/<AL>: address calculated with following formula:
#       AH = (address >> 10) & 0x7f
#       AL = (address >> 3)  & 0x7f
#       address = (AH << 10) | (AL << 3)
#       if address <  0x8000: program memory
#       if address >= 0x8000: data EEPROM
#
#    <CH>/<CL>: byte counter * 8
#       CH = (counter >> 10) & 0x7f
#       CL = (counter >> 3) & 0x7f
#       counter = (CH << 10) | (CL << 3)
#
#    <dump>: the data which has to be written, scrambled to a sequence
#    of 7-bit values
#
#    <checksum>: the checksum, from <AH> to last byte of the dump
#                -(sum of bytes) & 0x7f
sub dumpProgramData {
    my ($self, $address, $data8) = @_;
    # MIDI spec recommends max data size should be 128 bytes.
    # 112 = 128 * 7/8 : MAX data length
    #$data8 = substr($data8, 0, 112);
    # 8 bit -> 7 bit encoding
    my $data7 = $self->fileDumpEncode8to7($data8);
    my $len = length $data7;
    my $checksum = $self->checkSum_XOR(($address >> 10) & 0x7f,
				       ($address >> 3) & 0x7f,
				       ($len >> 10) & 0x7f,
				       ($len >> 3) & 0x7f,
				       unpack('C*', $data7));

    pack('C*', SOX, $self->mID2array(),
	 ($self->{mdlID} << 4) & 0x7f,
	 ($self->{devID} - 1) & 0x7f,
	 0x02,
	 ($address >> 10) & 0x7f,
	 ($address >> 3) & 0x7f,
	 ($len >> 10) & 0x7f,
	 ($len >> 3) & 0x7f)
	. pack("a${len}C2", $data7, $checksum, EOX);
}

1;
