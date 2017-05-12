#!/usr/local/bin/perl
#
#	Roland.pm : Roland MIDI System Exculsive support functions
#
#	Copyright (c) 2003 Hiroo Hayashi.  All rights reserved.
#
#	This program is free software; you can redistribute it and/or
#	modify it under the same terms as Perl itself.

# GS document (in Japanese)
#   http://www.b-sharp.com/midi/spec1/pdf/2-5.pdf

package Win32API::MIDI::SysEX::Roland;
my $ver = '$Id: Roland.pm,v 1.3 2003-04-13 22:54:26-05 hiroo Exp $';

=head1 NAME

Win32API::MIDI::SysEX::Roland - Perl Module for Roland MIDI System Exclusive Message.

=head1 SYNOPSIS

  use Win32API::MIDI::SysEX::Roland;
  # SC-55mkII GS Sound Module
  $se = new Win32API::MIDI::SysEX::Roland(mdlName => 'GS'); # 'GS' can be omitted
  # GS Reset
  $d = $se->GSReset;
  # Turn General MIDI System Off
  $d = $se->turnGeneralMIDISystemOff;
  # Turn General MIDI System On
  $d = $se->turnGeneralMIDISystemOn;
  # Set Master Volume
  $d = $se->masterVolume(0xD20);
  # example 2 (manual P.104): Request the level for a drum note.
  $d = $se->RQ1(0x41024b, 0x01);
  # bulk dump: system parameter and all patch parameter
  $d = $se->RQ1(0x480000, 0x1D10);
  # bulk dump: system parameter
  $d = $se->RQ1(0x480000, 0x10);
  # bulk dump: common patch parameter
  $d = $se->RQ1(0x480010, 0x100);
  # bulk dump: drum map1 all
  $d = $se->RQ1(0x490000, 0xe18);

=head1 DESCRIPTION

=head2 Overview

Win32API::MIDI::SysEX::Roland is submodule of Win32API::MIDI::SysEX.
Its object inherits his parents methods.

This module is still under development and most of function are not
debugged yet.  And the this module may have to be renamed as
MIDI::SysEX::Roland in the future, since this module is dependent with
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
	   'S-10'	=> [ 0x10,	1,	3 ],
	   'GS'		=> [ 0x42,	1,	3 ],
	   'SC-88'	=> [ 0x42,	1,	3 ],
	   'SC-55'	=> [ 0x45,	1,	3 ],
	   'SC-155'	=> [ 0x45,	1,	3 ],
	   'JV-1010'	=> [ 0x6a,	1,	4 ],
	   'VS-880'	=> [ 0x7c,	1,	3 ],
	   'GR-30'	=> [ 0x0007,	2,	4 ],
	   'TD-6'	=> [ 0x003f,	2,	4 ],
	  );

=head2 Create an Object

=over 4

=item new Win32API::MIDI::SysEX::Roland([param => value,]...)

Currently supported C<modelName> are;

  'S-10', 'GS', 'SC-88', 'SC-55', 'SC-155',
  'JV-1010', 'VS-880', 'GR-30', 'TD-6'

This information is used by RQ1 and DT1 method to know the size of the
model ID and address.  By default 'GS' is used.

To access GS common parameters the 'GS' object B<must> be used.  You
may have to create one or more object for a MIDI device.

=back

=cut

sub default_deviceID {
    17;				# my all of my 3 Roland devices use 17.
}

sub default_manufacturersID {
    0x41;			# Roland
}

sub default_modelName {
    'GS';
}

sub new_hook {
    my ($self, %params) = @_;
    # Roland Specific
    $self->{mdlID} = $fmt{$self->{mdlName}}->[0] unless defined $self->{mdlID};
    # byte size of model ID
    $self->{idSize} = $fmt{$self->{mdlName}}->[1];
    # byte size of adderss/data for RQ1/DT1 message
    $self->{adSize} = $fmt{$self->{mdlName}}->[2];
}

########################################################################

=head2 Request Data

=over 4

=item RQ1(address, size)

=back

=cut

sub RQ1 {
    my ($self, $addr, $size) = @_;
    my @mdlID = ($self->{idSize} == 1 ? ($self->{mdlID} & 0x7f)
		 : $self->unpack2_8($self->{mdlID}));
    my @addr  = ($self->{adSize} == 3
		 ? $self->unpack3_8($addr) : $self->unpack4_8($addr));
    my @size  = ($self->{adSize} == 3
		 ? $self->unpack3_8($size) : $self->unpack4_8($size));

    pack('C*', SOX, $self->mID2array(),
	 $self->{devID} - 1,
	 @mdlID,
	 0x11,			# command ID: RQ1
	 @addr,
	 @size,
	 $self->checkSum(@addr, @size),
	 EOX);
}

=head2 Data Transfer

=over 4

=item DT1(address, data)

=back

=cut

sub DT1 {
    my ($self, $addr, $data) = @_;
    my $dev   = $self->{devID} - 1;
    my @mdlID = ($self->{idSize} == 1
		 ? ($self->{mdlID} & 0x7f) : $self->unpack2_8($self->{mdlID}));
    my @addr  = ($self->{adSize} == 3
		 ? $self->unpack3_8($addr) : $self->unpack4_8($addr));

    pack('C*', SOX, $self->mID2array(),
	 $self->{devID} - 1,
	 @mdlID,
	 0x12,			# command ID: DT1
	 @addr)
	. $data
	    . pack('C*', $self->checkSum(@addr, unpack('C*', $data)), EOX);
}

=head2 GS Reset

=over 4

=item GSReset(void)

=cut

sub GSReset {
    my $self = shift;
    # The model ID 0x42 (GS) is required.
    my $save_mdlID = $self->{mdlID};
    $self->{mdlID} = 0x42;	# GS
    my $d = $self->DT1(0x40007f, "\x00"); # GS reset
    $self->{mdlID} = $save_mdlID;
    $d;
}

=head2 Exit GS Mode

=over 4

=item ExitGSMode(void)

=cut

sub ExitGSMode {
    my $self = shift;
    # The model ID 0x42 (GS) is required.
    my $save_mdlID = $self->{mdlID};
    $self->{mdlID} = 0x42;	# GS
    my $d = $self->DT1(0x40007f, "\x7f"); # exit GS mode
    $self->{mdlID} = $save_mdlID;
    $d;
}

=head2 System Mode Set

=over 4

=item SystemModeSet(mode)

  mode:
    0 : mode-1
    1 : mode-2

=cut

sub SystemModeSet {
    my ($self, $mode) = @_;
    # The model ID 0x42 (GS) is required.
    my $save_mdlID = $self->{mdlID};
    $self->{mdlID} = 0x42;	# GS
    my $d = $self->DT1(0x00007f, $mode);
    $self->{mdlID} = $save_mdlID;
    $d;
}

1;
