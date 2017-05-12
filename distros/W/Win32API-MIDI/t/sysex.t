# -*- perl -*-
#	sysex.t : test Win32API::MIDI::SysEX.pm
#
#	Copyright (c) 2003 Hiroo Hayashi.  All rights reserved.
#		hiroo.hayashi@computer.org
#
#	This program is free software; you can redistribute it and/or
#	modify it under the same terms as Perl itself.
#
#	$Id: sysex.t,v 1.4 2003-04-13 22:48:35-05 hiroo Exp $

use strict;
use Test;
BEGIN { plan tests => 83 };
use Data::Dumper;
ok(1); # If we made it this far, we're ok.

# for debug
sub datadump {
    my ($m) = @_;
    my $l = length $m;
    foreach (unpack 'C*', $m) { printf "%02x ", $_; }; print ":length $l\n";
}

sub NG {
    datadump($_[0]);
    datadump($_[1]);
    exit;
}

use Win32API::MIDI::SysEX qw(/^...$/);
use Win32API::MIDI::SysEX::Yamaha;
use Win32API::MIDI::SysEX::Roland;
use Win32API::MIDI::SysEX::MIDIbox;

########################################################################
# Exported Constant Value
# System Excusive Message
ok(SOX, 0xf0);		# Start of System Exclusive Status

# System Common Messages
ok(MQF, 0xf1);		# MTC (MIDI Time Code) Quarter Frame
ok(SPP, 0xf2);		# Song Position Pointer
ok(SSL, 0xf3);		# Song Select
# 0xf4, 0xf5 : undefined
ok(TRQ, 0xf6);		# Tune Request
ok(EOX, 0xf7);		# EOX: End Of System Exclusive

# System Real Time Messages
ok(CLK, 0xf8);		# Timing Clock
# 0xf9 : undefined
ok(STT, 0xfa);		# Start
ok(CNT, 0xfb);		# Continue
ok(STP, 0xfc);		# Stop
# 0xfd : undefined
ok(ASN, 0xfe);		# Active Sensing
ok(RST, 0xff);		# System Reset

# Special Manufacturer's IDs
ok(UNM, 0x7e);		# Universal Non-realtime Messages
ok(URM, 0x7f);		# Universal Realtime Messages

# Special Device ID
ok(BRD, 0x7f);		# Broadcast Device ID

########################################################################
my $se;
$se = new Win32API::MIDI::SysEX;
ok($se->{devID}, BRD() + 1);
ok($se->{mdlID}, undef);
ok($se->{mdlName}, undef);

$se = new Win32API::MIDI::SysEX(manufacturersID => 0x44);
ok($se->{mID}, 0x44);
ok($se->{mName}, 'Casio');

$se = new Win32API::MIDI::SysEX(mID => 0x04, devID => 13);
ok($se->{mID}, 0x04);
ok($se->{mName}, 'Moog');
ok($se->{devID}, 13);

$se = new Win32API::MIDI::SysEX(mName => 'Akai');
ok($se->{mID}, 0x47);
ok($se->{mName}, 'Akai');

# error checking test
$se = new Win32API::MIDI::SysEX(mID => 0x44, mName => 'Akai');
ok($se, undef);

$se = new Win32API::MIDI::SysEX(mID => 0x80);
ok($se, undef);
$se = new Win32API::MIDI::SysEX(mID => 0x8000);
ok($se, undef);
$se = new Win32API::MIDI::SysEX(mID => 0x800000);
ok($se, undef);
$se = new Win32API::MIDI::SysEX(mID => 0x1000000);
ok($se, undef);

$se = new Win32API::MIDI::SysEX(deviceID => -1);
ok($se, undef);
$se = new Win32API::MIDI::SysEX(deviceID => 0);
ok($se, undef);
$se = new Win32API::MIDI::SysEX(deviceID => 256+1);
ok($se, undef);

$se = new Win32API::MIDI::SysEX();
ok(1);
print Dumper($se);

########################################################################
# Manufacturer's ID
{
    ok($se->{devID}, 128);
    ok($se->{mID}, 0x7d);

    ok($se->manufacturer(0x00), 'reserved');
    ok($se->manufacturer(0x01), 'Sequential');
    ok($se->manufacturer(0x40), 'Kawai');
    ok($se->manufacturer(0x41), 'Roland');

    ok($se->manufacturersID('Korg'), 0x42);
    ok($se->manufacturersID('Yamaha'), 0x43);

    ok($se->manufacturer(0x7d), 'non-commercial use');
    ok($se->manufacturer(0x7e), 'Non-Real Time Universal System Exclusive ID');
    ok($se->manufacturer(0x7f), 'Real Time Universal System Exclusive ID');
    ok($se->manufacturer(0x010000), 'Time Warner Interactive');
    ok($se->manufacturer(0x002000), 'Dream');
    ok($se->manufacturersID('IBM'), 0x3a0000);
}

# Sample Dump
ok($se->sampleDumpACK(0x35),	"\xf0\x7e\x7f\x7f\x35\xf7");
ok($se->sampleDumpNAK(0x7f),	"\xf0\x7e\x7f\x7e\x7f\xf7");
ok($se->sampleDumpCANCEL(0xff),	"\xf0\x7e\x7f\x7d\x7f\xf7");
$se = new Win32API::MIDI::SysEX(deviceID => 0x3a);
print Dumper($se);
ok(1);
ok($se->sampleDumpWAIT(0x2a),	"\xf0\x7e\x39\x7c\x2a\xf7");
ok($se->sampleDumpEOF(0x55),	"\xf0\x7e\x39\x7b\x55\xf7");

ok($se->sampleDumpHeader(128, 8, int(1000000000/24000), 1024,
			 0, 512, 0x7f),
   "\xf0\x7e\x39\x01\x00\x01\x08\x42\x45\x02\x00\x08\x00\x00\x00\x00\x00\x04\x00\x7f\xf7");

ok($se->sampleDumpRequest(0xff), "\xf0\x7e\x39\x03\x7f\x01\xf7");

#sampeDataPacket !!!FIXIT!!!

#  ok($se->sampleDumpLoopPointTransmission(0xff),
#     "\xf0\x7e\x39\x03\x7f\x01\xf7");
#  ok($se->sampleDumpLoopPointRequest(0xff,),
#     "\xf0\x7e\x39\x03\x7f\x01\xf7");

# Sample Dump Extensions
# Device Inquiry
my $idata;
$idata = $se->identityReply(1, 2, 3, 4);
datadump($idata);
print Dumper($se->parseIdentityReply($idata));

$idata = $se->identityReply(0x002345, 256, 1024, 10000);
datadump($idata);
print Dumper($se->parseIdentityReply($idata));

# File Dump
my ($d8_old, $d7, $d8_new);
$d8_old = "\x80\x44\xf8\xb3\x3f\x12\x9a\xbb\xdc\x77";
datadump($d8_old);
$d7 = $se->fileDumpEncode8to7($d8_old);
datadump($d7);
$d8_new = $se->fileDumpEncode7to8($d7);
datadump($d8_new);
ok($d8_old, $d8_new);

# to be implemented !!!FIXIT!!!
# Request Header
# Data Packet (for File Dump)
# Handshaking Flags
# MIDI Tuning
# Bulk Tuning Dump Request
# Bulk Tuning Dump
# Single Note Tuning Change (Real-Time)
# General MIDI System Messages
# Turn General MIDI System On
# Turn General MIDI System Off
# Notation Information
# Bar Maker
# Time Signature
# Device Control
# Master Volume and Master Balance

########################################################################
gs_sysex();
td6_sysex();
xg_sysex();
midibox_sysex();
exit;

########################################################################
sub gs_sysex {
    # defautl device ID
    my $se = new Win32API::MIDI::SysEX::Roland();
    print Dumper($se);
    # broadcast (all call) device ID
    my $se_brd = new Win32API::MIDI::SysEX::Roland(deviceID => 256);
    print "GS Reset\n";
    datadump($se->GSReset);
    ok($se->GSReset, "\xf0\x41\x10\x42\x12\x40\x00\x7f\x00\x41\xf7");
#    print "Turn General MIDI System Off\n";
#    datadump($se->GMSystemOff);
#    ok($se->GMSystemOff, "\xf0\x7e\x7f\x09\x02\xf7");
    print "Turn General MIDI System On\n";
    datadump($se->GM1SystemOn);
    ok($se->GM1SystemOn, "\xf0\x7e\x7f\x09\x01\xf7");
    print "Set Master Volume\n";
    datadump($se_brd->masterVolume(0xD20));
    ok($se_brd->masterVolume(0xD20), "\xf0\x7f\x7f\x04\x01\x20\x1a\xf7");
    print "example 2 (manual P.104): Request the level for a drum note.\n";
    datadump($se->RQ1(0x41024b, 0x01));
    ok($se->RQ1(0x41024b, 0x01),
       "\xf0\x41\x10\x42\x11\x41\x02\x4b\x00\x00\x01\x71\xf7");
    print "bulk dump: system parameter and all patch parameter\n";
    datadump($se->RQ1(0x480000, 0x1D10));
    ok($se->RQ1(0x480000, 0x1d10),
       "\xf0\x41\x10\x42\x11\x48\x00\x00\x00\x1d\x10\x0b\xf7");
    print "bulk dump: system parameter\n";
    datadump($se->RQ1(0x480000, 0x10));
    ok($se->RQ1(0x480000, 0x10),
       "\xf0\x41\x10\x42\x11\x48\x00\x00\x00\x00\x10\x28\xf7");
    print "bulk dump: common patch parameter\n";
    datadump($se->RQ1(0x480010, 0x100));
    ok($se->RQ1(0x480010, 0x100),
       "\xf0\x41\x10\x42\x11\x48\x00\x10\x00\x01\x00\x27\xf7");
    print "bulk dump: drum map1 all\n";
    datadump($se->RQ1(0x490000, 0xe18));
    ok($se->RQ1(0x490000, 0xe18),
       "\xf0\x41\x10\x42\x11\x49\x00\x00\x00\x0e\x18\x11\xf7");
}

sub td6_sysex {
    my $se = new Win32API::MIDI::SysEX::Roland(modelName => 'TD-6');
    print Dumper($se);
    print "example 1 (manual P.146)\n";
    datadump($se->DT1(0x01000326, "\x20"));
    ok($se->DT1(0x01000326, "\x20"),
       "\xf0\x41\x10\x00\x3f\x12\x01\x00\x03\x26\x20\x36\xf7");
    print "example 2 (manual P.146)\n";
    datadump($se->RQ1(0x01000015, 0x1));
    ok($se->RQ1(0x01000015, 0x1),
       "\xf0\x41\x10\x00\x3f\x11\x01\x00\x00\x15\x00\x00\x00\x01\x69\xf7");
    print "bulk dump: all user song\n";
    datadump($se->RQ1(0x10000000, 0x0));
    print "bulk dump: Setup\n";
    datadump($se->RQ1(0x40000000, 0x0));
    print "bulk dump: drum kit 3\n";
    datadump($se->RQ1(0x41030000, 0x0));
    print "bulk dump: all drum kit\n";
    datadump($se->RQ1(0x417f0000, 0x0));
}

sub xg_sysex {
    # defautl device ID
    my $se = new Win32API::MIDI::SysEX::Yamaha();
    print Dumper($se);
    # for masterTune (For which model 0x27 is?)
    my $se_27 = new Win32API::MIDI::SysEX::Yamaha(modelID => 0x27);
    ok($se_27->{mdlID}, 0x27);
    # broadcast (all call) device ID
    my $se_brd = new Win32API::MIDI::SysEX::Yamaha(deviceID => 256);
    print "XG System On\n";
    datadump($se->XGSystemOn);
    ok($se->XGSystemOn,
       "\xf0\x43\x10\x4c\x00\x00\x7e\x00\xf7");
    print "Turn General MIDI System On\n";
    datadump($se->GM1SystemOn);
    ok($se->GM1SystemOn, "\xf0\x7e\x7f\x09\x01\xf7");
    print "Set Master Volume\n";
    datadump($se_brd->masterVolume(0xD20));
    ok($se_brd->masterVolume(0xD20), "\xf0\x7f\x7f\x04\x01\x20\x1a\xf7");
    print "Set Master Tuning\n";
    datadump($se_27->masterTuning(0xD20));
    ok($se_27->masterTuning(0xD20),
       "\xf0\x43\x10\x27\x30\x00\x00\x0d\x20\x00\xf7");
    print "Parameter Change\n";
    datadump($se->ParameterChange_2B(0x12345, 0x55A8));
    ok($se->ParameterChange_2B(0x12345, 0x55A8),
       "\xf0\x43\x10\x4c\x01\x23\x45\x55\x28\xf7");
    datadump($se->ParameterChange_4B(0x678ab, 0xfedcba98));
    ok($se->ParameterChange_4B(0x678ab, 0xfedcba98),
       "\xf0\x43\x10\x4c\x06\x78\x2b\x7e\x5c\x3a\x18\xf7");
    print "Bulk Dump\n";
    datadump($se->BulkDump(0x3f7f7f, "abcde\x7e"));
    ok($se->BulkDump(0x3f7f7f, "abcde\x7e"),
       "\xf0\x43\x00\x4c\x00\x06\x3f\x7f\x7f\x61\x62\x63\x64\x65\x7e\x50\xf7");
    print "Parameter Request\n";
    datadump($se->ParameterRequest(0x2f3318));
    ok($se->ParameterRequest(0x2f3318),
       "\xf0\x43\x30\x4c\x2f\x33\x18\xf7");
    print "Dump Request\n";
    datadump($se->DumpRequest(0x33183f));
    ok($se->DumpRequest(0x33183f),
       "\xf0\x43\x20\x4c\x33\x18\x3f\xf7");
}

sub midibox_sysex {
    my $se = new Win32API::MIDI::SysEX::MIDIbox();
    print Dumper($se);
    ok($se->readRequest(), "\xf0\x00\x00\x7e\x45\x01\xf7");
    ok($se->writeDump(''),
       "\xf0\x00\x00\x7e\x45\x02" . "\x00" x 4096 . "\xf7");
    ok($se->writePartialDump(0x1234, 0x5678),
       "\xf0\x00\x00\x7e\x45\x04\x12\x1a\x56\x3c\xf7");
    ok($se->requestBank(7, 3),
       "\xf0\x00\x00\x7e\x45\x08\x73\xf7");
    ok($se->acknowledgePing(),
       "\xf0\x00\x00\x7e\x45\x0f\xf7");
#      ok($se->dumpProgramData(0x8000, "\x80\x44\xf8\xb3\x3f\x12\x9a\xbb\xdc\x77"),
#         "\xf0\x00\x00\x7e\xf7");
}
