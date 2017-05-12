#!/usr/local/bin/perl
#
#	Yamaha.pm : Yamaha MIDI System Exculsive support functions
#
#	Copyright (c) 2003 Hiroo Hayashi.  All rights reserved.
#
#	This program is free software; you can redistribute it and/or
#	modify it under the same terms as Perl itself.
#
#	$Id: Yamaha.pm,v 1.3 2003-04-13 22:54:26-05 hiroo Exp $

# XS document
# http://www.yamaha.co.uk/xg/reading/index.html

package Win32API::MIDI::SysEX::Yamaha;
my $ver = '$Id: Yamaha.pm,v 1.3 2003-04-13 22:54:26-05 hiroo Exp $';

=head1 NAME

Win32API::MIDI::SysEX::Yamaha - Perl Module for YAMAHA MIDI System
Exclusive Message.

=head1 SYNOPSIS

  use Win32API::MIDI::SysEX::Yamaha;
  # XG Sound Module
  $se = new Win32API::MIDI::SysEX::Yamaha(modelName => 'XG'); # 'XG' can be omitted

=head1 DESCRIPTION

=head2 Overview

Win32API::MIDI::SysEX::Yamaha is submodule of Win32API::MIDI::SysEX.
Its object inherits his parents methods.

This module is still under development and most of function are not
debugged yet.  And the this module may have to be renamed as
MIDI::SysEX::Yamaha in the future, since this module is dependent with
Microsoft Windows.

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
my %fmt = (#		     model ID	2byteID	address size
	   'XG'		=> [ 0x4c,	1,	3 ],
	  );

=head2 Create an Object

=over 4

=item new Win32API::MIDI::SysEX::Yamaha([model [, device_ID]])

Currently supported C<model> are;

  'XG'

This information is used by RQ1 and DT1 method to know the size of the
model ID and address.  By default 'XG' is used.

To access XG common parameters the 'XG' object B<must> be used.  You
may have to create one or more object for a MIDI device.

=back

=cut

sub default_deviceID {
    1;				# What is proper value for Yahama?
}

sub default_manufacturersID {
    0x43;			# Yamaha
}

sub default_modelName {
    'XG';
}

sub new_hook {
    my $self = shift;
    $self->{mdlID}  = $fmt{$self->{mdlName}}->[0] unless defined $self->{mdlID};
    $self->{idSize} = $fmt{$self->{mdlName}}->[1]; # byte size of model ID
    $self->{adSize} = $fmt{$self->{mdlName}}->[2]; # byte size of adderss/data
}

########################################################################
# common routine
sub sysex {
    my ($self, $cmd, $addr, $size, $data) = @_;

    pack('C*', SOX, $self->mID2array(),
	 $cmd | ($self->{devID} - 1) & 0x0f,
	 $self->{mdlID} & 0x7f,
	 $self->unpack3_8($addr),
	 ($size == 1 ? $data & 0x7f
	  : $size == 2 ? $self->unpack2_8($data)
	  : $size == 3 ? $self->unpack3_8($data)
	  : $size == 4 ? $self->unpack4_8($data)
	  : ()),		# else null data
	 EOX);
}

########################################################################

=head2 XG System On

=over 4

=item XGSystemOn(void)

  F0H,43H,1nH,4CH,00H,00H,7EH,00H,F7H
  11110000 F0 Exclusive status
  01000011 43 YAMAHA ID
  0001nnnn 1n Device Number
  01001100 4C Model ID
  00000000 00 Address High
  00000000 00 Address Mid
  01111110 7E Address Low
  00000000 00 Data
  11110111 F7 End of Exclusive

This message switches SOUND MODULE MODE to XG and initializes all the
parameters to the XG default settings, with the exception of Master
Tune value.

=back

=cut

sub XGSystemOn {
    my $self = shift;
    $self->sysex(0x10, 0x00007e, 1, 0x00);
}

=head2 MIDI Master Tuning

=over 4

=item masterTuning(master_tune_2B)

=back

=cut

sub masterTuning {
    my ($self, $data) = @_;
    $self->sysex(0x10, 0x300000, 3, $data<<8);
}

=head2 Parameter Change

=over 4

=item ParameterChange_2B(address, data)

=item ParameterChange_4B(address, data)

  11110000 F0 Exclusive status
  01000011 43 YAMAHA ID
  0001nnnn 1n Device Number
  01001100 4C Model ID
  0aaaaaaa aa Address High
  0aaaaaaa aa Address Mid
  0aaaaaaa aa Address Low
  0ddddddd dd Data
  | |
  0ddddddd dd Data
  11110111 F7 End of Exclusive

Includes 2 or 4 bytes of data, depending on parameter size.  The
following eight types of parameter change are provided.

  1) System Data parameter change
  2) Multi Effect Data parameter change
  3) Multi EQ Data parameter change
  4) Multi Part Data parameter change
  5) Drums Setup Data parameter change
  6) System Information
  7) Display Data parameter change
  8) AD Part Data parameter change

*6) System Information is sent in response to dump requests. Received
parameter changes are ignored.

System Exclusive messages are not accepted if gRcv System Exclusiveh 
is OFF.

=back

=cut

sub ParameterChange_2B {
    my ($self, $address, $data) = @_;
    $self->sysex(0x10, $address, 2, $data);
}

sub ParameterChange_4B {
    my ($self, $address, $data) = @_;
    $self->sysex(0x10, $address, 4, $data);
}

=head2 Bulk Dump

=over 4

=item BlukDump(address, data)

  11110000 F0 Exclusive status
  01000011 43 YAMAHA ID
  0000nnnn 0n Device Number
  01001100 4C Model ID
  0bbbbbbb bb Byte Count MSB
  0bbbbbbb bb Byte Count LSB
  0aaaaaaa aa Address High
  0aaaaaaa aa Address Mid
  0aaaaaaa aa Address Low
  0ddddddd dd Data
  | |
  0ddddddd dd Data
  0ccccccc cc Checksum
  11110111 F7 End of Exclusive

For information about gAddressh and gByte Counth fields, refer to
Table 3.

Here the "Byte Count" refers to "Total Size" of Data shown on Table 3-n.
The "Address" in Bulk Dump / Dump Request refers to the address at the
beginning of each block.

The "block" refers to a unit of data stream which is enclosed by
"Total Size" on Table 3-n.

Checksum value is set such that the sum of Byte Count, Address, Data
and Checksum has value zero in its seven least significant bits.

=back

=cut

sub BulkDump {
    my ($self, $address, $data) = @_;

    my @d = ($self->unpack2_8(length $data),
	     $self->unpack3_8($address),
	     unpack('C*', $data));

    pack('C*', SOX, $self->mID2array(),
	 0x00 | ($self->{devID} - 1) & 0x0f,
	 $self->{mdlID} & 0x7f,
	 @d,
	 $self->checkSum(@d),
	 EOX);
}

=head2 Parameter Request

=over 4

=item ParameterRequest(address)

  11110000 F0 Exclusive status
  01000011 43 YAMAHA ID
  0011nnnn 3n Device Number
  01001100 4C Model ID
  0aaaaaaa aa Address High
  0aaaaaaa aa Address Mid
  0aaaaaaa aa Address Low
  11110111 F7 End of Exclusive

=cut

sub ParameterRequest {
    my ($self, $address) = @_;
    $self->sysex(0x30, $address, 0);
}

=head2 Dump Request

=over 4

=item DumpRequest(address)

  11110000 F0 Exclusive status
  01000011 43 YAMAHA ID
  0010nnnn 2n Device Number
  01001100 4C Model ID
  0aaaaaaa aa Address High
  0aaaaaaa aa Address Mid
  0aaaaaaa aa Address Low
  11110111 F7 End of Exclusive

Sending or receiving of dump request cannot be switched off except by
setting gExclusiveh to OFF.

=back

=cut

sub DumpRequest {
    my ($self, $address) = @_;
    $self->sysex(0x20, $address, 0);
}

1;
