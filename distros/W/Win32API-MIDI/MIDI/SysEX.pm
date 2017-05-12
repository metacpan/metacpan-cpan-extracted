#!/usr/local/bin/perl
#
#	SysEX.pm : MIDI System Exculsive support functions
#
#	Copyright (c) 2003 Hiroo Hayashi.  All rights reserved.
#
#	This program is free software; you can redistribute it and/or
#	modify it under the same terms as Perl itself.

package Win32API::MIDI::SysEX;
my $ver = '$Id: SysEX.pm,v 1.3 2003-04-13 22:52:41-05 hiroo Exp $';

=head1 NAME

Win32API::MIDI::SysEX - Perl Module for MIDI System Exclusive Message.

=head1 SYNOPSIS

  use Win32API::MIDI::SysEX;
  $se = new Win32API::MIDI::SysEX;
  $d = $se->turnGeneralMIDISystemOff;
  $d = $se->turnGeneralMIDISystemOn;
  $d = $se->masterVolume(0xD20);

=head1 DESCRIPTION

=head2 Overview

This module is still under development and most of function are not
debugged yet.  And the this module may have to be renamed as
MIDI::SysEX in the future, since this module is dependent with
Microsoft Windows.

=cut

use Carp;
use strict;

use vars qw($VERSION @ISA @EXPORT_OK %mID);
$VERSION = $ver =~ m/\s+(\d+\.\d+)\s+/;
@ISA = qw(Exporter);
require Exporter;

# unpack* and chckSum are only for submodule and not documented
@EXPORT_OK = qw(MQF SPP SSL TRQ EOX CLK STT CNT STP ASN RST
		SOX UNM URM BRD);

########################################################################
# Utility Routines for SysEX sub-methods (ie. SysEX/*.pm).

# for MIDI Standard system exclusive message multibyte data
# LSB first
sub unpack2_7 {
    my $self = shift;
    return ($_[0] & 0x7f, ($_[0] >> 7) & 0x7f);
}
sub unpack3_7 {
    my $self = shift;
    return ($_[0] & 0x7f, ($_[0] >> 7) & 0x7f, ($_[0] >> 14) & 0x7f);
}
sub unpack4_7 {
    my $self = shift;
    return ($_[0] & 0x7f, ($_[0] >> 7) & 0x7f, ($_[0] >> 14) & 0x7f,
	    ($_[0] >> 21) & 0x7f);
}

# used by Standard MIDI
sub checkSum_XOR {
    my $self = shift;
    my $s = shift;
    $s ^= $_ foreach (@_);
    $s & 0x7F;
}

# for address/data based on number 128 (MSB first)
# Roland and Yamaha use this notation.
sub unpack2_8 {
    my $self = shift;
    return (($_[0] >> 8) & 0x7f, $_[0] & 0x7f);
}
sub unpack3_8 {
    my $self = shift;
    return (($_[0] >> 16) & 0x7f, ($_[0] >> 8) & 0x7f, $_[0] & 0x7f);
}
sub unpack4_8 {
    my $self = shift;
    return (($_[0] >> 24) & 0x7f, ($_[0] >> 16) & 0x7f,
	    ($_[0] >> 8)  & 0x7f, $_[0] & 0x7f);
}

sub conv7bto8b2B {
    my $self = shift;
    ($_[0] & 0x7f) << 8 | ($_[0] >> 7) & 0x7f;
}

sub conv7bto8b3B {
    my $self = shift;
    ($_[0] & 0x7f) << 16 | (($_[0] >> 7) & 0x7f) << 8 | ($_[0] >> 14) & 0x7f;
}

sub conv7bto8b4B {
    my $self = shift;
    ($_[0] & 0x7f) << 24 | (($_[0] >> 7) & 0x7f) << 16
	| (($_[0] >> 14) & 0x7f) << 8 | ($_[0] >> 21) & 0x7f;
}

sub checkSum {
    my $self = shift;
    my $s = 0;
    $s += $_ foreach (@_);
    -$s & 0x7F;
}

########################################################################
# MIDI Standard Constants and System Exclusive Messages

# System Excusive Message
sub SOX { 0xf0; };		# Start of System Exclusive Status

# System Common Messages
sub MQF { 0xf1; };		# MTC (MIDI Time Code) Quarter Frame
sub SPP { 0xf2; };		# Song Position Pointer
sub SSL { 0xf3; };		# Song Select
# 0xf4, 0xf5 : undefined
sub TRQ { 0xf6; };		# Tune Request
sub EOX { 0xf7; };		# EOX: End Of System Exclusive

# System Real Time Messages
sub CLK { 0xf8; };		# Timing Clock
# 0xf9 : undefined
sub STT { 0xfa; };		# Start
sub CNT { 0xfb; };		# Continue
sub STP { 0xfc; };		# Stop
# 0xfd : undefined
sub ASN { 0xfe; };		# Active Sensing
sub RST { 0xff; };		# System Reset

# Special Manufacturer's IDs
sub UNM { 0x7e; };		# Universal Non-realtime Messages
sub URM { 0x7f; };		# Universal Realtime Messages

# Special Device ID
sub BRD { 0x7f; };		# Broadcast Device ID



=head2 Manufacturer's ID Number

MIDI manufacturer's ID is distributed as follows.

    	       not used  American  European  Japanese  Other     Special
    1 byte ID: 00        01 -- 1F  20 -- 3F  40 -- 5F  60 -- 7C  7D -- 7F
    3 byte ID: 00 00 00  00 00 01  00 20 00  00 40 00  00 60 00
    			 00 1F 7F  00 3F 7F  00 5F 7F  00 7F 7F

    7D: non-commercial use (e.g. schools, research, etc.)
    7E: Non-Real Time Universal System Exclusive ID
    7F: Real Time Universal System Exclusive ID (all call device ID)


Standard MIDI System Exclusive Messages use LSB first (a kind of
little endian) notation.  By following this rule, a 3 byte ID "xxh yyh
zzh" in MIDI specification is expressed as 0xzzyyxx in this module.
By using this notation we can distinguish "01h" (Sequential: 0x01)
from "00h 00h 01h" (Time Warner Interactive: 0x010000).

The following methods are provided.

=over 4

=item manufacturer(ID)

Returns the manufacturer name for manufacturer's ID.

=item manufacturersID(name)

Returns the manufacturer ID whose manufacturer's name equals with
name.  Returns undef when no matches.

=back

=cut

sub manufacturer {
    $mID{$_[1]};
}

sub manufacturersID {
    foreach (keys %mID) {
	return $_ if $mID{$_} eq $_[1];
    }
    carp("There is no manufactureres ID matched with `$_[1]'\n");
    return undef;
}

# Returns a array of byte data from manufacturers ID.
# if parameter is omitted, $self->{mID} is used.

# When a function generate System Exclusive message, by using this
# function it can support both 1 and 3 byte message.  The function can
# be reused for MIDI devcies from other manufacturer.
sub mID2array {
    my ($self, $id) = @_;
    $id = $self->{mID} unless defined $id;
    if ($id <= 0xff) {
	return ($id);
    } else {
	return ($id & 0x7f, ($id >> 8) & 0x7f, ($id >> 16) & 0x7f);
    }
}

# =head2 Universal System Exclusive

=head2 Device ID

The value for device ID option (argument) should be a number from 1 to
16 (not 0 to 15).

=head1 Create an Object

=over 4

=item new Win32API::MIDI::SysEX([param => value,]...)

	deviceID [devID]:
		Device ID.  If device_ID is omitted, BRD+1 broadcast,
		all call, 127+1) is used.  The device ID is used on
		every method calls.  You can create any numbers of
		object with different device ID.

	manufacturersID [mID]:
		manufacturers ID.  If omitted, 0x7d (Non-commercail
		use) is used.

	manufacturerName [mName]:
		manufacturers name. It must be one of key of
		%Win32API::MIDI::mID

	modelID [mdlID]:
		MIDI device model ID

	modelName [mdlName]:
		MIDI device model name.

=back

=cut

# Subclass can override the following function
sub default_deviceID {
    1+BRD;			# all call
}

sub default_manufacturersID {
    0x7d;			# Non-commercial use
}

sub default_modelName {
    undef;
}

sub new_hook {}			# for ancestor

sub new {
    my $type = shift;
    my %params = @_;
    my $self = {};
    bless $self, $type;

    # long parameter name has higher precedence.
    # short paramter name is actually used.
    $params{mID} = $params{manufacturersID}
	if defined $params{manufacturersID};
    $params{mName} = $params{manufacturerName}
	if defined $params{manufacturerName};
    $params{mdlID} = $params{modelID} if defined $params{modelID};
    $params{mdlName} = $params{modelName} if defined $params{modelName};
    $params{devID} = $params{deviceID} if defined $params{deviceID};

    # manufacturer's ID and name
    if (defined $params{mID}) {
	if (defined $params{mName}
	    && $self->manufacturer($params{mID}) ne $params{mName}) {
	    carp(sprintf("new: inconsistent paramter `mID' (0x%x) and `mName' (%s)\n",
		 $params{mID}, $params{mName}));
	    return undef;
	}
	if ($params{mID} & (~0x7f7f7f)) {
	    carp(sprintf("new: illegal manufacturer's ID: 0x%x\n",
			 $params{mID}));
	    return undef;
	}
	$self->{mID}= $params{mID};
	$self->{mName} = $self->manufacturer($params{mID});
    } elsif (defined $params{mName}) {
	$self->{mName} = $params{mName};
	$self->{mID}= $self->manufacturersID($params{mName});
    } else {
	$self->{mID} = $self->default_manufacturersID;
	$self->{mName} = $self->manufacturer($self->{mID});
    }

    if (defined $params{devID}) {
	if ($params{devID} < 1 ||  $params{devID} > 256) {
	    carp("new : illegal device ID : $params{devID}\n");
	    return undef;
	}
	$self->{devID} = $params{devID};
    } else {
	$self->{devID} = $self->default_deviceID;
    }

    $self->{mdlName} = $params{mdlName} || $self->default_modelName;;
    $self->{mdlID} = $params{mdlID};

    # subclass can override any if he wants.
    $self->new_hook(%params);
    return $self;
}



=head1 Sample Dump Standard

=head2 Generic Handshaking Messages

=over 4

=item sampleDumpACK(pp_1B)

=item sampleDumpNAK(pp_1B)

=item sampleDumpCANCEL(pp_1B)

=item sampleDumpWAIT(pp_1B)

=item sampleDumpEOF(pp_1B)

  pp_1B:packet number (1 byte)

=back

=cut

sub sampleDumpACK {
    my ($self, $pp) = @_;
    my $dev = $self->{devID} - 1;
    pack('C*', SOX, UNM, $dev & 0x7f, 0x7f, $pp & 0x7f, EOX);
}

sub sampleDumpNAK {
    my ($self, $pp) = @_;
    my $dev = $self->{devID} - 1;
    pack('C*', SOX, UNM, $dev & 0x7f, 0x7e, $pp & 0x7f, EOX);
}

sub sampleDumpCANCEL {
    my ($self, $pp) = @_;
    my $dev = $self->{devID} - 1;
    pack('C*', SOX, UNM, $dev & 0x7f, 0x7d, $pp & 0x7f, EOX);
}

sub sampleDumpWAIT {
    my ($self, $pp) = @_;
    my $dev = $self->{devID} - 1;
    pack('C*', SOX, UNM, $dev & 0x7f, 0x7c, $pp & 0x7f, EOX);
}

sub sampleDumpEOF {
    my ($self, $pp) = @_;
    my $dev = $self->{devID} - 1;
    pack('C*', SOX, UNM, $dev & 0x7f, 0x7b, $pp & 0x7f, EOX);
}

=head2 Dump Header

=over 4

=item sampleDumpHeader(sample_number_2B, sample_format,
		       sample_period_3B, sample_length_3B,
		       sustain_loop_start_point_word_number_3B,
		       sustain_loop_end_point_word_number_3B,
		       loop_type)

  sample_format: # of significant bits from 8-28
  sample_period_3B: 1/sample_rate in nanosecond
  loop_type: 00=forward only, 01=backward/forward, 7f=loop off

=back

=cut

sub sampleDumpHeader {
    my ($self, $ss, $ee, $ff, $gg, $hh, $ii, $jj) = @_;
    my $dev = $self->{devID} - 1;
    pack('C*', SOX, UNM, $dev & 0x7f, 0x01,
	 $self->unpack2_7($ss), $ee & 0x7f,
	 $self->unpack3_7($ff), $self->unpack3_7($gg),
	 $self->unpack3_7($hh), $self->unpack3_7($ii),
	 $jj & 0x7f, EOX);
}

=head2 Dump Request

=over 4

=item sampleDumpRequest(requested_sample_2B)

=back

=cut

sub sampleDumpRequest {
    my ($self, $ss) = @_;
    my $dev = $self->{devID} - 1;
    pack('C*', SOX, UNM, $dev & 0x7f, 0x03, $self->unpack2_7($ss), EOX);
}

=head2 Data Packet (for Sample Data)

=over 4

=item sampleDataPacket(running_packet_count_1B, data)

  running_packet_count_1B: 0-127
  data: 120 bytes of data

=back

=cut

sub sampleDataPacket {
    my ($self, $kk, $data) = @_;
    my $dev = $self->{devID} - 1;
    my $len = length $data;
    # make data length 120 byte
    $data = substr($data, 0, 120) if $len > 120;
    $data = $data . "\000" x (120 - $len) if $len < 120;
    my $checksum = $self->checkSum_XOR(UNM, $dev & 0x7f, 0x02, $kk & 0x7f,
				       unpack('C*', $data));

    pack('C5a120C*', SOX, UNM, $dev & 0x7f, 0x02, $kk & 0x7f,
	 $data,
	 $checksum, EOX);
}

=head2 Sample Dump Extensions

=over 4

=item sampleDumpLoopPointTransmission(sample_number_2B, loop_number_2B,
			loop_type,
			loop_start_address_3B, loop_end_address_3B);

  loop_type:
	00 = Forwards Only (unidirectional)
	01 = Backwards/Forwards (bi-directional)
	7F = Off

=item sampleDumpLoopPointRequest(sample_number_2B, loop_number_2B)

=back

=cut

sub sampleDumpLoopPointTransmission {
    my ($self, $ss, $bb, $cc, $dd, $ee) = @_;
    my $dev = $self->{devID} - 1;
    pack('C*', SOX, UNM, $dev & 0x7f,
	 0x05,			# Sample Dump Extensions (sub-ID#1)
	 0x01,			# Multiple Loop Message (sub-ID#2)
	 $self->unpack2_7($ss), $self->unpack2_7($bb), $cc & 0x7f,
	 $self->unpack3_7($dd), $self->unpack3_7($ee), EOX);
}

sub sampleDumpLoopPointRequest {
    my ($self, $ss, $bb) = @_;
    my $dev = $self->{devID} - 1;
    pack('C*', SOX, UNM, $dev & 0x7f,
	 0x05,			# Sample Dump Extensions (sub-ID#1)
	 0x02,			# Loop Point Request (sub-ID#2)
	 $self->unpack2_7($ss), $self->unpack2_7($bb), EOX);
}



=head1 Device Inquiry

=over 4

=item identityRequest(void)

=item identityReply(manufacturer's_ID,
		   device_family_code_2B, device_family_member_code_2B,
		   software_revision_level_4B)

    manufacturer's_ID : 1 or 3 byte ID


=item parseIdentityReply(identity_reply_data)

parseIdentityReply() returns list of;

	device ID (1 byte)
	manufactures ID (1 byte or 3 byte)
	device family code (2 byte)
	device family member code (2 byte)
	software revision level (4 byte)

Or returns NULL list if data format of C<identity_reply_data> is illegal.

=back

=cut

sub identityRequest {
    my $self = shift;
    my $dev = $self->{devID} - 1;
    pack('C*', SOX, UNM, $dev & 0x7f,
	 0x06,			# General Information (sub-ID #1)
	 0x01,			# Indentity Request (sub-ID #2)
	 EOX);
}

sub identityReply {
    my ($self, $mid, $family, $fmember, $rev) = @_;
    my $dev = $self->{devID} - 1;
    pack('C*', SOX, UNM, $dev & 0x7f,
	 0x06,			# General Information (sub-ID #1)
	 0x01,			# Indentity Reply (sub-ID #2)
	 $self->mID2array($mid), # Manufacturers System Exclusive id code
	 $self->unpack2_7($family), # Device family code
	 $self->unpack2_7($fmember), # Device family member code
	 $self->unpack4_7($rev), # Software revision level:Format device spcific
	 EOX);
}

sub parseIdentityReply {
    my @d = unpack('C17', $_[1]);
    return () unless ($#d == 14 || $#d == 16);
    return () if ($d[0] != SOX or $d[1] != UNM
		  or $d[3] != 0x06 or $d[4] != 0x02);
    if ($d[5] != 0) {
	# 1 byte manufacturer's ID
	return ($d[2],		# device ID
		$d[5],		# Manufacturer;s ID
		$d[6]  | ($d[7]  << 7),
		$d[8]  | ($d[9]  << 7),
		$d[10] | ($d[11] << 7) | ($d[12] << 14) | ($d[13] << 21));
    } else {
	# 3 byte manufacturer's ID
	return ($d[2],		# device ID
		($d[7] << 16) | ($d[6] << 8) | $d[5], # Manufacturer;s ID
		$d[8]  | ($d[9]  << 7),
		$d[10] | ($d[11] << 7),
		$d[12] | ($d[13] << 7) | ($d[14] << 14) | ($d[15] << 21));
    }
}



=head1 File Dump

=head2 Request

=over 4

=item fileDumpRequest(receiver_ID_1B, type [,file_name])

  type:
	"MIDI" : MIDI File
	"MIEX" : MIDIEX File
	"ESEQ" : ESQ File
	"TEXT" : 7-bit ASCII Text File
	"BIN " : binary file
	"MAC " : Macintosh file (with MacBinary header)

Returns undef if C<type> or C<file_name> is illegal value.

=back

=cut

sub fileDumpRequest {
    my ($self, $ss, $type, $name) = @_;
    my $dev = $self->{devID} - 1;
    # check file type
    return undef if $type =~ /^(MIDI|MIEX|ESEQ|TEXT|BIN |MAC )$/;
    # check file name : null string means "whatever is curerntly loaded
    $name = '' unless defined $name;
    return undef if $name =~ /^[\x20-\x7e]*$/;
    pack('C6a4', SOX, UNM, $dev & 0x7f,
	 0x07,			# File Dump (sub-ID #1)
	 0x03,			# Request (sub-ID #2)
	 ($ss - 1) & 0x7f,	# device ID of requester
	 $type)
	. $name			# variable length
	    . chr(EOX);
}

=head2 Header

=over 4

=item fileDumpHeader(sender_ID, type, length [,file_name])

  type: see fileDumpRequest().

=back

=cut

sub fileDumpHeader {
    my ($self, $ss, $type, $length, $name) = @_;
    my $dev = $self->{devID} - 1;
    # check file type
    return undef if $type =~ /^(MIDI|MIEX|ESEQ|TEXT|BIN |MAC )$/;
    # check file name : null string means "whatever is curerntly loaded
    $name = '' unless defined $name;
    return undef if $name =~ /^[\x20-\x7e]*$/;
    pack('C6a4C4', SOX, UNM, $dev & 0x7f,
	 0x07,			# File Dump (sub-ID #1)
	 0x01,			# Header (sub-ID #2)
	 ($ss - 1) & 0x7f,	# device ID of requester
	 $type, $self->unpack4_7($length))
	. $name			# variable length
	    . chr(EOX);
}


=head2 Data Packet (for File Dump)

=over 4

=item fileDumpDataPacket(pp_1B, data)

Maximum data length is 112 byte.

=back

=cut

sub fileDumpDataPacket {
    my ($self, $npkt, $data8) = @_;
    my $dev = $self->{devID} - 1;
    # 112 = 128 * 7/8 : MAX data length
    $data8 = substr($data8, 0, 112);
    my $data7 = $self->fileDumpEncode8to7($data8);
    my $len = length $data7;
    my $checksum = $self->checkSum_XOR(UNM, $dev & 0x7f, 0x07, 0x02,
				       $npkt & 0x7f,
				       $len, unpack('C*', $data7));

    pack("C7a${len}C2", SOX, UNM, $dev & 0x7f, 0x07, 0x02,
	 $npkt & 0x7f, $len,
	 $data7, $checksum, EOX);
}

sub fileDumpEncode8to7 {
    my $data8 = $_[1];
    my $data7 = '';
    foreach ($data8 =~ /(.{7})/g, $') {
	my ($m, $p, $d7) = (0x40, 0, '');
	foreach my $c (unpack('C*', $_)) {
	    ($c &= 0x7f, $p |= $m) if $c > 0x7f;
	    $d7 .= chr $c;
	    $m >>= 1;
	}
	$data7 .= chr($p) . $d7;
    }
    return $data7;
}

sub fileDumpEncode7to8 {
    my $data7 = $_[1];
    my $data8 = '';
    foreach ($data7 =~ /(.{8})/g, $') {
	my ($p, @s) = unpack('C*', $_);
	my $m = 0x40;
	foreach my $c (@s) {
	    $data8 .= chr(($p & $m) ? $c | 0x80 : $c);
	    $m >>= 1;
	}
    }
    return $data8;
}

=head2 Handshaking Flags

=over 4

=item fileDumpNAK(pp_1B)

=item fileDumpACK(pp_1B)

=item fileDumpWAIT(pp_1B)

=item fileDumpCANCEL(pp_1B)

=item fileDumpEOF(pp_1B)

  pp_1B:packet number (1 byte)

=back

=cut

sub fileDumpHandshake {
    my ($self, $subid, $npkt) = @_;
    my $dev = $self->{devID} - 1;
    pack('C*', SOX, UNM, $dev & 0x7f, $subid, $npkt & 0x7f, EOX);
}

sub fileDumpNAK {
    my ($self, $npkt) = @_;
    # handshake message: NAK (sub-ID #1)
    $self->fileDumpHandshake(0x7E, $npkt);
}
sub fileDumpACK {
    my ($self, $npkt) = @_;
    # handshake message: ACK (sub-ID #1)
    $self->fileDumpHandshake(0x7F, $npkt);
}
sub fileDumpWAIT {
    my ($self, $npkt) = @_;
    # handshake message: WAIT (sub-ID #1)
    $self->fileDumpHandshake(0x7C, $npkt);
}
sub fileDumpCANCEL {
    my ($self, $npkt) = @_;
    # handshake message: CANCEL (sub-ID #1)
    $self->fileDumpHandshake(0x7D, $npkt);
}
sub fileDumpEOF {
    my ($self, $npkt) = @_;
    # handshake message: End of File (sub-ID #1)
    $self->fileDumpHandshake(0x7B, $npkt);
}



=head1 MIDI Tuning

=head2 Bulk Tuning Dump Request

=over 4

=item bulkTuningDumpRequest(pn_1B)

    pn: tuning program number (0-127)

=back

=cut

sub bulkTuningDumpRequest {
    my ($self, $pn) = @_;
    my $dev = $self->{devID} - 1;
    pack('C*', SOX, UNM, $dev & 0x7f,
	 0x08,			# sub-ID#1 = MIDI Tuning Standard
	 0x00,			# sub-ID#2 = bulk dump request
	 $pn & 0x7f,
	 EOX);
}

=head2 Bulk Tuning Dump

=over 4

=item bulkTuningDump(pn_1B, tuning_name, data)

    pn: tuning program number (0-127)
    tuning_name: 16 ASCII characters
    data: 3 x 128 bytes frequency data

=back

=cut

sub bulkTuningDump {
    my ($self, $pn, $name, $data) = @_;
    my $dev = $self->{devID} - 1;
    return undef if (length $data != 128*3);

    my $checksum = $self->checkSum_XOR(UNM, $dev & 0x7f, 0x08, 0x01,
				       $pn & 0x7f,
				       unpack('C*', pack('a16', $name)),
				       unpack('C*', $data));

    pack('C6a16a384C2', SOX, UNM, $dev & 0x7f, 0x08, 0x01, $pn & 0x7f,
	 $data, $checksum, EOX);
}

=head2 Single Note Tuning Change (Real-Time)

=over 4

=item singleNoteTuningChange(pn_1B, nc_1B, data)

    pn: tuning program number (0-127)
    nc: number of changes
    data: 4 x nc bytes data

=back

=cut

sub singleNoteTuningChange {
    my ($self, $pn, $nc, $data) = @_;
    my $dev = $self->{devID} - 1;
    return undef if (length $data != 128*3);

    $nc &= 0x7f;
    my $len = 4 * $nc;

    pack("C7a${len}C1", SOX, URM, # Real time message
	 $dev & 0x7f, 0x08, 0x02, $pn & 0x7f, $nc,
	 $data, EOX);
}



=head1 General MIDI System Messages

=head2 Turn General MIDI System On

=over 4

=item GM1SystemOn(void)

=item GM2SystemOn(void)

=back

=cut

sub GM1SystemOn {
    my $self = shift;
    pack('C*', SOX, UNM,
	 BRD,			# Using 'All Call' is suggested.
	 0x09,			# sub-ID #1 = General MIDI message
	 0x01,			# sub-ID #2 = General MIDI On
	 EOX);
}

sub GM2SystemOn {
    my $self = shift;
    pack('C*', SOX, UNM,
	 BRD,			# Using 'All Call' is suggested.
	 0x09,			# sub-ID #1 = General MIDI message
	 0x02,			# sub-ID #2 = General MIDI 2 On
	 EOX);
}

=head2 Turn General MIDI System Off

=over 4

=item  GMSystemOff(void)

=back

=cut

sub GMSystemOff {
    my $self = shift;
    pack('C*', SOX, UNM,
	 BRD,			# Using 'All Call' is suggested.
	 0x09,			# sub-ID #1 = General MIDI message
	 0x02,			# sub-ID #2 = General MIDI Off
	 EOX);
}



=head1 Notation Information

=head2 Bar Maker

=over 4

=item notationInfoBarMarker(bar_number_2B)

    bar_number:
	0x2000			not running
	0x2001 - 0x0000		count-in
	0x0001 - 0x1FFE		bar number in song
	0x1FFF			running: bar number unknown

=back

=cut

sub notationInfoBarMarker {
    my ($self, $bn) = @_;
    my $dev = $self->{devID} - 1;
    pack('C*', SOX, URM, $dev & 0x7f,
	 0x03,			# sub-ID#1 = Notation information
	 0x01,			# sub-ID#2 = Bar Number Message
	 $self->unpack2_7($bn),
	 EOX);
}

=head2 Time Signature

=over 4

=item notationInfoTimeSignatureImmediate(nb0_1B, bd0_1B, nc_1B, nn_1B [,nb1_1B, bd1_1B]...)

=item notationInfoTimeSignatureDelayed(nb0_1B, bd0_1B, nc_1B, nn_1B [,nb1_1B, bd1_1B]...)

   nbn : number of beats (numerator) of time signature
   bdn : beat value (denominator) of time signature (negative power of 2)
   nc  : number of MIDI clocks in a metronome click
   nn  : number of notated 32nd notes in a MIDI quarter note

   Example
     3/4       : nb0 = 3, bd0 = 2
     4/4 + 3/8 : nb0 = 4, bd0 = 2, nb1 = 3, bd1 = 3

=back

=cut

sub notationInfoTimeSignature {
    my $self = shift;
    my $subid = shift;
    my $ln = $#_ + 1;
    return undef if (($ln < 4) || ($ln % 2)); # return if less than 4 or odd
    my $dev = $self->{devID} - 1;
    pack('C*', SOX, URM, $dev & 0x7f,
	 0x03,			# sub-ID#1 = Notation information
	 $subid,
	 $ln,
	 @_,
	 EOX);
}

sub notationInfoTimeSignatureImmediate {
    my $self = shift;
    # sub-ID#2 = 0x02 : Time Signature - Immediate
    $self->notationInfoTimeSignature(0x02, @_);
}

sub notationInfoTimeSignatureDelayed {
    my $self = shift;
    # sub-ID#2 = 0x42 : Time Signature - Delayed
    $self->notationInfoTimeSignature(0x42, @_);
}



=head1 Device Control

=head2 Master Volume and Master Balance

=over 4

=item masterVolume(volume_2B)

    volume :
      0x0000 = volume off
      0x3FFF = maximum volume

=item masterBalance(balance_2B)

    balance :
      0x0000 = hard left
      0x2000 = center
      0x3fff = hard right

=cut

sub masterVolume {
    my $self = shift;
    my $dev = $self->{devID} - 1;
    pack('C*', SOX, URM, $dev & 0x7f,
	 0x04,			# sub-ID #1 : Device Control
	 0x01,			# sub-ID #2 : Master Volume
	 $self->unpack2_7($_[0]),	# volume; 00 00 = volume off
	 EOX);
}

sub masterBalance {
    my $self = shift;
    my $dev = $self->{devID} - 1;
    pack('C*', SOX, URM, $dev & 0x7f,
	 0x04,			# sub-ID #1 : Device Control
	 0x02,			# sub-ID #2 : Master Balance
	 $self->unpack2_7($_[0]), # volume; 00 00 = hard left; 7f 7f = hard right
	 EOX);
}

#
# GM2 (General MIDI 2)
#
sub globalParameter {
    my ($self, $effect, $pp, $vv) = @_;
    my $dev = $self->{devID} - 1;
    pack('C*', SOX, URM, $dev & 0x7f,
	 0x04,			# sub-ID #1 : Device Control
	 0x05,			# sub-ID #2 : Global Parameter Control
	 0x01,			# slot path legnth
	 0x01,			# parameter ID width
	 0x01,			# value width
	 $self->unpack2_8($effect), # slot path (effect)
	 $pp & 0x7f,		# parameter
	 $vv & 0x7f,		# value
	 EOX);
}

=item globalParameterReverb(parameter_1B, value_1B) (GM2)

    parameter = 0: Reverb Type
	0: small room
	1: medium room
	2: large room
	3: medium hall
	4: large hall (default)
	5: plate

    parameter = 1: Reverb Time
	0: 44 (1.1s)
	1: 50 (1.3s)
	2: 56 (1.5s)
	3: 64 (1.8s)
	4: 64 (1.8s)
	8: 50 (1.3s)

=cut

sub globalParameterReverb {
    my ($self, $pp, $vv) = @_;
    $self->globalParameter(0x0101, $pp, $vv);
}

=item globalParameterChorus(parameter_1B, value_1B) (GM2)

    parameter = 0: Chorus Type
	0: Chorus 1
	1: Chorus 2
	2: Chorus 3
	3: Chorus 4
	4: FB Chorus
	5: Flanger

    parameter = 1: Modulation Rate
	MR = value * 0.122 (MR: modulation frequency in Hz)

    parameter = 2: Modulation Depth
	MD = (value+1) / 3.2 (MD: peak-to-peak swing of modulation in ms)

    parameter = 3: Feedback
	FB = value * 0.763 (FB: amount of feedback from Chorus output in percent)

    parameter = 4: Send to Reverb
	CTR = value * 0.787 (CTR: send level from Chorus to Reverb in percent)

=cut

sub globalParameterChorus {
    my ($self, $pp, $vv) = @_;
    $self->globalParameter(0x0102, $pp, $vv);
}

=item channelPressure(channel_1B, pp_1B, rr_1B [,pp_1B, rr_1B]...) (GM2)

Controller Destination Setting, Channel Pressure (Aftertouch)

  pp				rr		description
  00 Pitch Control		0x28-0x58	-24 - +24 semitones
  01 Filter Cutoff Control	0x00-0x7f	-9600 - +9450 cents
  02 Amplitude Control		0x00-0x7f	0 - (127/64)*10 percent
  03 LFO Pitch Depth		0x00-0x7f	0 - 600 cents
  04 LFO Filter Depth		0x00-0x7f	0 - 2400 cents
  05 LFO Amplitude Depth	0x00-0x7f	0 - 100 percent

=cut

sub channelPressure {
    my ($self, $channel, @p) = @_;
    my $dev = $self->{devID} - 1;
    pack('C*', SOX, URM, $dev & 0x7f,
	 0x09,			# sub-ID #1 : Controller Destination Setting
	 0x01,			# sub-ID #2 : channel pressure
	 ($channel-1) & 0x0f,	# channel
	 @p,
	 EOX);
}

=item controlChange(channel_1B, cc_1B, pp_1B, rr_1B [,pp_1B, rr_1B]...) (GM2)

Controller Destination Setting, Controller (Control Change)

  cc : controller number 0x01 - 0x1f, 0x40 - 0x5f

  pp				rr		description
  00 Pitch Control		0x28-0x58	-24 - +24 semitones
  01 Filter Cutoff Control	0x00-0x7f	-9600 - +9450 cents
  02 Amplitude Control		0x00-0x7f	0 - (127/64)*10 percent
  03 LFO Pitch Depth		0x00-0x7f	0 - 600 cents
  04 LFO Filter Depth		0x00-0x7f	0 - 2400 cents
  05 LFO Amplitude Depth	0x00-0x7f	0 - 100 percent

=cut

sub controlChange {
    my ($self, $channel, @p) = @_;
    my $dev = $self->{devID} - 1;
    pack('C*', SOX, URM, $dev & 0x7f,
	 0x09,			# sub-ID #1 : Controller Destination Setting
	 0x03,			# sub-ID #2 : control change
	 ($channel-1) & 0x0f,	# channel
	 @p,
	 EOX);
}

=back

=cut


########################################################################
# System Exclusive Manufacturer's ID Numbers
# MIDI Spec. 1.0 Detailed Specification 4.2, Feb.1996,  TABLE VIIb
# http://www.midi.org/about-mma/mfr_id.shtml
%mID =
    (
     0x00, 'reserved',		# 3 byte ID

     # American Group
     0x01, 'Sequential',
     0x02, 'IDP',
     #0x03, 'Voyetra Technologies',
     0x03, 'Voyetra/Octave-Plateau',
     0x04, 'Moog',
     0x05, 'Passport Designs',
     0x06, 'Lexicon',
     0x07, 'Kutzweil',
     0x08, 'Fender',
     0x09, 'Gulbransen',
     0x0A, 'AKG Acoustics',
     0x0B, 'Voyce Music',
     0x0C, 'Waveframe Corp',
     0x0D, 'ADA Signal Processors',
     0x0E, 'Garfield Electronics',
     0x0F, 'Ensoniq',
     #0x10, 'Oberheim / Gibson Labs',
     0x10, 'Oberheim',
     0x11, 'Apple Computer',
     0x12, 'Grey Matter Response',
     0x13, 'Digidesign',
     0x14, 'Palmtree Instruments',
     0x15, 'JLCooper Electronics',
     #0x16, 'Lowrey Organ Company',
     0x16, 'Lowrey',
     0x17, 'Adams-Smith',
     0x18, 'Emu Systems',
     0x19, 'Harmony Systems',
     0x1A, 'ART',
     0x1B, 'Baldwin',
     0x1C, 'Eventide',
     0x1D, 'Inventronics',
     0x1F, 'Clarity',

     # European Group
     0x20, 'Passac',
     0x21, 'SIEL',
     0x22, 'Synthaxe',
     0x23, 'Stepp',		# ?
     0x24, 'Hohner',
     0x25, 'Twister',
     0x26, 'Solton',
     0x27, 'Jellinghaus MS',
     0x28, 'Southworth Music Systems',
     0x29, 'PPG',
     0x2A, 'JEN',
     #0x2B, 'Solid State Logic Organ Systems',
     0x2B, 'SSL Limited',
     0x2C, 'Audio Veritrieb',
     0x2D, 'Neve',
     0x2E, 'Soundtracs Ltd.',	# ?
     0x2F, 'Elka',
     0x30, 'Dynacord',
     #0x31, 'Intercontinental Electronics SpA',
     0x31, 'Viscount',
     0x32, 'Drawmer',		# ?
     0x33, 'Clavia Digital Instruments',
     0x34, 'Audio Architecture',
     0x35, 'GeneralMusic Corp.',
     0x36, 'Cheetah Marketing',	# ?
     0x37, 'C.T.M.',		# ?
     0x38, 'Simmons UK',	# ?
     0x39, 'Soundcraft Electronics',
     0x3A, 'Steinberg GMBH c/o', # ?
     0x3B, 'Wersi',
     #0x3C, 'AVAB Niethammer AB',
     0x3C, 'Avab Electronik Ab',
     0x3D, 'Digigram',
     0x3E, 'Waldorf Electronics',
     0x3F, 'Quasimidi',

     # Japanese Group
     0x40, 'Kawai',
     0x41, 'Roland',
     0x42, 'Korg',
     0x43, 'Yamaha',
     0x44, 'Casio',
     0x46, 'Kamiya Studio',
     0x47, 'Akai',
     0x48, 'Japan Victor',
     0x49, 'Mesosha',
     0x4A, 'Hoshino Gakki',
     0x4B, 'Fujitsu Elect',
     0x4C, 'Sony',
     0x4D, 'Nisshin Onpa',
     0x4E, 'TEAC',
     0x50, 'Matsushita Electric',
     0x51, 'Fostex',
     0x52, 'Zoom',
     0x53, 'Midori Electronics',
     0x54, 'Matsushita Communication Industrial',
     0x55, 'Suzuki Musical Instruments Mfg.',
     0x56, 'Fuji Sound Corporation Ltd.',
     0x57, 'Acoustic Technical Laboratory,Inc',

     # Special
     0x7D, 'non-commercial use', # e.g. schools, research, etc.
     0x7E, 'Non-Real Time Universal System Exclusive ID',
     0x7F, 'Real Time Universal System Exclusive ID', # (all call device ID)

     #
     # 3 byte ID

     #   Express the ID which is expressed as "xxh yyh zzh" in MIDI
     #   specification as 0xzzyyxx.  By using this expression we can
     #   distinguish "01h" (Sequential: 0x01) from "00h 00h h01h"
     #   (Time Warner Interactive: 0x010000).  Standard MIDI System
     #   Exclusive Messages use LSB first (a kind of little endian)
     #   notation.  This is consistent with it.
     #0x000000, 'reserved',

     # American Group
     0x010000, 'Time Warner Interactive',
     0x020000, 'Advanced Gravis Comp.',	# ?
     0x030000, 'Media Vision',	# ?
     0x040000, 'Dornes Research Group',	# ?
     0x050000, 'K-Muse',	# ?
     0x060000, 'Stypher',	# ?
     0x070000, 'Digital Music Corp.',
     0x080000, 'IOTA Systems',
     0x090000, 'New England Digital',
     0x0A0000, 'Artisyn',
     0x0B0000, 'IVL Technologies',
     0x0C0000, 'Southern Music Systems',
     0x0D0000, 'Lake Butler Sound Company',
     0x0E0000, 'Alesis',
     0x0F0000, 'Sound Creation', # ?
     0x100000, 'DOD Electronics',
     0x110000, 'Studer-Editech',
     0x120000, 'Sonus',		# ?
     0x130000, 'Temporal Acuity Products', # ?
     0x140000, 'Perfect Fretworks',
     0x150000, 'KAT',
     0x160000, 'Opcode',
     0x170000, 'Rane Corp.',
     0x180000, 'Anadi Inc.',
     0x190000, 'KMX',
     0x1A0000, 'Allen & Heath Brenell',
     0x1B0000, 'Peavey Electronics',
     0x1C0000, '360 System',
     0x1D0000, 'Spectrum Design and Development',
     0x1E0000, 'Marquis Music',
     0x1F0000, 'Zeta Systems',
     0x200000, 'Axxes',
     0x210000, 'Orban',
     0x220000, 'Indian Valley Mfg.', # ?
     0x230000, 'Triton',	# ?
     0x240000, 'KTI',
     0x250000, 'Breakaway Technologies',
     0x260000, 'CAE',
     0x270000, 'Harrison Systems Inc.',	# ?
     0x280000, 'Future Lab/Mark Kuo', # ?
     0x290000, 'Rocktron Corp.',
     0x2A0000, 'PianoDisc',
     0x2B0000, 'Cannon Research Group',
     0x2D0000, 'Rodgers Instrument Corp.',
     0x2E0000, 'Blue Sky Logic',
     0x2F0000, 'Encore Electronics',
     0x300000, 'Uptown',
     0x310000, 'Voce',
     0x320000, 'CTI Audio, Inc. (Music. Intel Dev.)',
     0x330000, 'S&S Research',
     0x340000, 'Broderbund Software, Inc.',
     0x350000, 'Allen Organ Co.',
     0x370000, 'Music Quest',
     0x380000, 'APHEX',
     0x390000, 'Gallien Krueger',
     0x3A0000, 'IBM',
     0x3B0000, 'Mark of the Unicorn', # ?
     0x3C0000, 'Hotz Instruments Technologies',
     0x3D0000, 'ETA Lighting',
     0x3E0000, 'NSI Corporation',
     0x3F0000, 'Ad Lib, Inc.',
     0x400000, 'Richmond Sound Design',
     0x410000, 'Microsoft',
     0x420000, 'The Software Toolworks',
     #0x430000, 'Russ Jones / Niche',
     0x430000, 'Niche/RJMG',
     0x440000, 'Intone',
     0x450000, 'Advanced Remote Tech.',	# ?
     0x470000, 'GT Electronics/Groove Tubes',
     0x490000, 'Timeline Vista',
     0x4A0000, 'Mesa Boogie',
     0x4C0000, 'Sequoia Development',
     0x4D0000, 'Studio Electronics',
     0x4E0000, 'Euphonix',
     0x4F0000, 'InterMIDI',
     0x500000, 'MIDI Solutions',
     0x510000, '3DO Company',
     0x520000, 'Lightwave Research',
     0x530000, 'Micro-W',
     0x540000, 'Spectral Synthesis',
     0x550000, 'Lone Wolf',
     0x560000, 'Studio Technologies',
     #0x570000, 'Peterson Electro-Musical',
     0x570000, 'Peterson EMP',
     0x580000, 'Atari',
     0x590000, 'Marion Systems',
     0x5A0000, 'Design Event',
     0x5B0000, 'Winjammer Software',
     0x5C0000, 'AT&T Bell Labs',
     0x5E0000, 'Symetrix',
     0x5F0000, 'MIDI the World',
     0x600000, 'Desper Products',
     0x610000, 'Micros \'N MIDI',
     0x620000, 'Accordians Intl',
     0x630000, 'EuPhonics',
     0x640000, 'Musonix',
     0x650000, 'Turtle Beach Systems',
     0x660000, 'Mackie Designs',
     0x670000, 'Compuserve',
     #0x680000, 'BEC Technologies',
     0x680000, 'BES Technologies',
     0x690000, 'QRS Music Rolls',
     0x6A0000, 'P G Music',
     0x6B0000, 'Sierra Semiconductor',
     0x6C0000, 'EpiGraf Audio Visual',
     0x6D0000, 'Electronics Diversified',
     0x6E0000, 'Tune 1000',
     0x6F0000, 'Advanced Micro Devices',
     0x700000, 'Mediamation',
     0x710000, 'Sabine Music',
     0x720000, 'Woog Labs',
     0x730000, 'Micropolis',
     0x740000, 'Ta Horng Musical Inst.',
     0x750000, 'eTek (Forte)',
     0x760000, 'Electrovoice',
     0x770000, 'Midisoft',
     0x780000, 'Q-Sound Labs',
     0x790000, 'Westrex',
     0x7A0000, 'Nvidia',
     0x7B0000, 'ESS Technology',
     0x7C0000, 'MediaTrix Peripherals',
     0x7D0000, 'Brooktree',
     0x7E0000, 'Otari',
     0x7F0000, 'Key Electronics',
     0x000100, 'Shure Incorporated',
     #0x010100, 'AuraSound',
     0x010100, 'Crystalake Multimedia',
     0x020100, 'Crystal Semiconductor',
     #0x030100, 'Conexant (Rockwell)',
     0x030100, 'Rockwell Semiconductor',
     0x040100, 'Silicon Graphics',
     0x050100, 'Midiman',
     0x060100, 'PreSonus',
     0x080100, 'Topaz Enterprises',
     0x090100, 'Cast Lighting',
     0x0A0100, 'Microsoft Consumer Division',
     0x0B0100, 'Sonic Foundry',
     0x0C0100, 'Line 6 (Fast Forward)',
     0x0D0100, 'Beatnik Inc',
     0x0E0100, 'Van Koevering Company',
     0x0F0100, 'Altech Systems',
     0x100100, 'S & S Research',
     0x110100, 'VLSI Technology',
     0x120100, 'Chromatic Research',
     0x130100, 'Sapphire',
     0x140100, 'IDRC',
     0x150100, 'Justonic Tuning',
     0x160100, 'TorComp Research Inc',
     0x170100, 'Newtek Inc',
     0x180100, 'Sound Sculpture',
     0x190100, 'Walker Technical',
     0x1A0100, 'Digital Harmony (PAVO)',
     0x1B0100, 'InVision Interactive',
     0x1C0100, 'T-Square Design',
     0x1D0100, 'Nemesys Music Technology',
     0x1E0100, 'DBX Professional (Harman Intl)',
     0x1F0100, 'Syndyne Corporation',
     0x200100, 'Bitheadz',
     0x210100, 'Cakewalk Music Software',
     0x220100, 'Staccato Systems',
     0x230100, 'National Semiconductor',
     0x240100, 'Boom Theory / Adinolfi Alternative Percussion',
     0x250100, 'Virtual DSP Corporation',
     0x260100, 'Antares Systems',
     0x270100, 'Angel Software',
     0x280100, 'St Louis Music',
     0x290100, 'Lyrrus dba G-VOX',
     0x2A0100, 'Ashley Audio Inc',
     0x2B0100, 'Vari-Lite Inc',
     0x2C0100, 'Summit Audio Inc',
     0x2D0100, 'Aureal Semiconductor Inc',
     0x2E0100, 'SeaSound LLC',
     0x2F0100, 'U. S. Robotics',
     0x300100, 'Aurisis Research',
     0x310100, 'Nearfield Multimedia',
     0x320100, 'FM7 Inc',
     0x330100, 'Swivel Systems',
     0x340100, 'Hyperactive Audio Systems',
     0x350100, 'MidiLite (Castle Studios Productions)',
     0x360100, 'Radikal Technologies',
     0x370100, 'Roger Linn Design',
     0x380100, 'Helicon Vocal Technologies',
     0x390100, 'Event Electronics',
     0x3A0100, 'Sonic Network Inc',
     0x3B0100, 'Realtime Music Solutions',
     0x3C0100, 'Apogee Digital',
     0x3D0100, 'Classical Organs, Inc.',
     0x3E0100, 'Microtools Inc',
     0x3F0100, 'Numark Industries',

     # European Group
     0x002000, 'Dream',
     0x012000, 'Strand Lighting',
     0x022000, 'Amek Systems',
     0x032000, 'Casa Di Risparmio Di Loreto', # ?
     0x042000, 'Bohm electronic',
     0x052000, 'Syntec Digital Audio', # ?
     0x062000, 'Trident Audio',
     0x072000, 'Real World Studio',
     0x082000, 'Evolution Synthesis', # ?
     0x092000, 'Yes Technology',
     0x0A2000, 'Audiomatica',
     0x0B2000, 'Bontempi/Farfisa',
     0x0C2000, 'F.B.T. Elettronica',
     0x0D2000, 'MidiTemp',
     0x0E2000, 'LA Audio (Larking Audio)',
     0x0F2000, 'Zero 88 Lighting Limited',
     0x102000, 'Micon Audio Electronics GmbH',
     0x112000, 'Forefront Technology',
     0x122000, 'Studio Audio and Video Ltd.', # ?
     0x132000, 'Kenton Electronics',
     0x142000, 'Celco Division of Electrosonic', # ?
     0x152000, 'ADB',
     0x162000, 'Marshall Products',
     0x172000, 'DDA',
     0x182000, 'BSS',
     0x192000, 'MA Lighting Technology',
     0x1A2000, 'Fatar',
     0x1B2000, 'QSC Audio',
     0x1C2000, 'Artisan Clasic Organ',
     0x1D2000, 'Orla Spa',
     0x1E2000, 'Pinnacle Audio',
     0x1F2000, 'TC Electronics',
     0x202000, 'Doepfer Musikelektronik',
     0x212000, 'Creative Technology Pte',
     0x222000, 'Minami/Seiyddo',
     0x232000, 'Goldstar',
     0x242000, 'Midisoft s.a.s. di M. Cima',
     0x252000, 'Samick',
     0x262000, 'Penny and Giles',
     0x272000, 'Acorn Computer',
     0x282000, 'LSC Electronics',
     0x292000, 'Novation EMS',
     0x2A2000, 'Samkyung Mechatronics',
     0x2B2000, 'Medeli Electronics',
     0x2C2000, 'Charlie Lab SRL',
     0x2D2000, 'Blue Chip Music Tech',
     0x2E2000, 'BEE OH Corp',
     0x2F2000, 'LG Semicon America',
     0x302000, 'TESI',
     0x312000, 'EMAGIC',
     0x322000, 'Behringer GmbH',
     0x332000, 'Access Music Electronics',
     0x342000, 'Synoptic',
     0x352000, 'Hanmesoft Corp',
     0x362000, 'Terratec Electronic GmbH',
     0x372000, 'Proel SpA',
     0x382000, 'IBK MIDI',
     0x392000, 'IRCAM',
     0x3A2000, 'Propellerhead Software',
     0x3B2000, 'Red Sound Systems Ltd',
     0x3C2000, 'Elektron ESI AB',
     0x3D2000, 'Sintefex Audio',
     0x3E2000, 'MAM (Music and More)',
     0x3F2000, 'Amsaro GmbH',
     0x402000, 'CDS Advanced Technology BV',
     0x412000, 'Touched By Sound GmbH',
     0x422000, 'DSP Arts',
     0x432000, 'Phil Rees Music Tech',
     0x442000, 'Stamer Musikanlagen GmbH',
     0x452000, 'Soundart (Musical Muntaner)',
     0x462000, 'C-Mexx Software',
     0x472000, 'Klavis Technologies',
     0x482000, 'Noteheads AB',
     0x492000, 'Algorithmix',
     0x4A2000, 'Skrydstrup R&D',
     0x4B2000, 'Professional Audio Company',
     0x4C2000, 'DBTECH',
     0x4D2000, 'Vermona',
     0x4E2000, 'Nokia',
    );

=head1 EXPORT

None by default.  The following constant values can be exported.

=over 4

=item System Exclusive Message

  SOX = 0xf0	# Start of System Exclusive Status

=item System Common Messages

  MQF = 0xf1	# MTC (MIDI Time Code) Quarter Frame
  SPP = 0xf2	# Song Position Pointer
  SSL = 0xf3	# Song Select
  TRQ = 0xf6	# Tune Request
  EOX = 0xf7	# EOX: End Of System Exclusive

=item System Real Time Messages

  CLK = 0xf8	# Timing Clock
  STT = 0xfa	# Start
  CNT = 0xfb	# Continue
  STP = 0xfc	# Stop
  ASN = 0xfe	# Active Sensing
  RST = 0xff	# System Reset

=item Special Manufacturer's IDs

  UNM = 0x7e	# Universal Non-realtime Messages
  URM = 0x7f	# Universal Realtime Messages

=item Special Device ID

  BRD = 0x7f	# Broadcast Device ID (all call)

=back

=head1 AUTHOR

Hiroo Hayashi, E<lt>hiroo.hayashi@computer.orgE<gt>

=head1 SEE ALSO

=over 4

=item Win32API::MIDI

=item Win32API::MIDI::SysEX::Roland.pm, Win32API::MIDI::SysEX::Yamaha.pm,  etc

=back

=head1 TODO

=over 4

=item Add more Subclasses other than Roland or Yamaha.  Contributions
are welcome.

=item More test and debug.

=item Implement MTC (MIDI Time Control), MSC (MIDI Show Control), and
MMC (MIDI Machine Control) functions.

=back

=head1 BUGS

If you find bugs, report to the author.

=cut

1;
