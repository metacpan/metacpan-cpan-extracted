# -*- perl -*-
#	midiin.t : test Win32API::MIDI::In
#
#	Copyright (c) 2003 Hiroo Hayashi.  All rights reserved.
#		hiroo.hayashi@computer.org
#
#	This program is free software; you can redistribute it and/or
#	modify it under the same terms as Perl itself.
#
#	$Id: midiin.t,v 1.8 2003-04-13 22:44:22-05 hiroo Exp $

=pod

This test sends Identity Request message (GS request level message if
`-g' option is applied) to a MIDI device and waits for reply for one
second and show the data received.

eg/midisysexin.pl and eg/td6 demonstrates dual buffering method to
receive large bulk dump data and event driven method using Tie::Watch
distrubuted with Perl/Tk.

=cut

use strict;
use vars qw($ntest $opt_i $opt_g);
use Getopt::Std;
use Data::Dumper;
use Test;
BEGIN { $ntest = 18; plan tests => $ntest; };

use Win32API::MIDI qw( /^(MIM_)/ );
ok(1); # If we made it this far, we're ok.

my $midi = new Win32API::MIDI;
ok(1);

use Win32API::MIDI::Out;
ok(1);

use Win32API::MIDI::SysEX;
use Win32API::MIDI::SysEX::Roland;
ok(1);

getopts('ig');

if (!$opt_i && ! -f 't/devinfo') {
    print STDERR "midiin.t: Try \`$^X -Mblib t/midiin.t -i\', if you have MIDI input device.\n";
    skip('skip, run with -i option', 'skipping t/midiin.t') for (1..$ntest-4);
    exit 0;
}
ok(1);

if ($midi->InGetNumDevs() == 0){
    skip('need MIDI Input device', 'skipping t/midiin.t') for (1..$ntest-3);
    exit 0;
}
ok(1);

if ($midi->OutGetNumDevs() == 0){
    skip('need MIDI Output device', 'skipping t/midiin.t') for (1..$ntest-2);
    exit 0;
}
ok(1);

# for debug
sub datadump {
    my ($m) = @_;
    my $l = length $m;
    foreach (unpack 'C*', $m) { printf "%02x ", $_; }; print ":length $l\n";
}

# set 1 to enable debug message in callback routine
my $cb_debug = 0;

########################################################################
midi_in_test(get_midi_dev_info($opt_i), $opt_g);
exit 0;

########################################################################
sub midi_in_test {
    my ($midev, $modev, $devid, $use_gs) = @_;
    print "MIDI::API::In\n";
    my $mi = new Win32API::MIDI::In($midev, \&midiincallback, 0x1234)
	or die $midi->InGetErrorText();
    ok(1);

    my $buf = "\0" x 1024;
    # make a pointer to MIDIHDR data structure
    # cf. perlpacktut in Perl 5.8.0 or later
    #     (http://www.perldoc.com/)
    my $midihdr = pack ("PLLLLPLL",
			$buf,	# lpData
			length $buf, # dwBufferLength
			0,	# dwBytesRecorded
			0xBEEF,	# dwUser
			0,	# dwFlags
			undef,	# lpNext
			0,	# reserved
			0);	# dwOffset
    my $lpMidiInHdr = unpack('L!', pack('P', $midihdr));
    printf("lpMidiInHdr: 0x%08x, buf: 0x%08x\n",
	   $lpMidiInHdr, unpack('L!', pack('P', $buf)));

    $mi->PrepareHeader($lpMidiInHdr)	or die $mi->GetErrorText(); ok(1);
    $mi->AddBuffer($lpMidiInHdr)	or die $mi->GetErrorText(); ok(1);
    $mi->Start				or die $mi->GetErrorText(); ok(1);

    my $mo = new Win32API::MIDI::Out($modev) or die $midi->OutGetErrorText();
    ok(1);

    my $se;
    if ($use_gs) {		# for GS sound module
	$se = new Win32API::MIDI::SysEX::Roland(deviceID => $devid);
	print "Sending 'Request the level for a drum note'.\n";
	datadump($se->RQ1(0x41024b, 0x01));
	$mo->SysEX($se->RQ1(0x41024b, 0x01)) or die $mo->GetErrorText(); ok(1);
    } else {			# use MIDI standard indentity request message
	$se = new Win32API::MIDI::SysEX(deviceID => $devid);
	# Indentity Request
	print "Sending `Indentity Request' which old MIDI device may not support.\n";
	datadump($se->identityRequest);
	$mo->SysEX($se->identityRequest)	or die $mo->GetErrorText(); ok(1);
    }
    print "Waiting...";
    sleep 1;
    print "done (sleep)\n";
    $mo->Close				or die $mo->GetErrorText(); ok(1);
    $mi->Stop				or die $mi->GetErrorText(); ok(1);
    $mi->Reset				or die $mi->GetErrorText(); ok(1);
    $mi->UnprepareHeader($lpMidiInHdr)	or die $mi->GetErrorText(); ok(1);
    $mi->Close				or die $mi->GetErrorText(); ok(1);

    my $bytesrecorded = (unpack('LL4LL2', $midihdr))[2];
    my $data = unpack("P$bytesrecorded", $midihdr);

    datadump($data);
    if ($use_gs) {
	printf ("Returned data: %02x\n", (unpack('C*', $data))[8]);
    } else {
	my @d = $se->parseIdentityReply($data);
	if (@d) {
	    printf "device ID:\t\t\t%02x\n", $d[0];
	    printf("manufactures ID:\t\t%06x\n", $d[1]);
	    printf "manufacutre:\t\t\t%s\n", $se->manufacturer($d[1]);
	    printf "device family code:\t\t%04x (%04x)\n",
		$d[2], $se->conv7bto8b2B($d[2]);
	    printf "device family member code:\t%04x (%04x)\n",
		$d[3], $se->conv7bto8b2B($d[3]);
	    printf "software revision:\t\t%08x (%08x)\n",
		$d[4], $se->conv7bto8b4B($d[4]);
	} else {
	    print "No identity Reply\n";
	}
    }
}

# From MSDN:
#	Applications should not call any system-defined functions from
#	inside a callback function, except for EnterCriticalSection,
#	LeaveCriticalSection, midiOutLongMsg, midiOutShortMsg,
#	OutputDebugString, PostMessage, PostThreadMessage, SetEvent,
#	timeGetSystemTime, timeGetTime, timeKillEvent, and
#	timeSetEvent.

# This means that we cannot use print() in the callback function.
# But print() is still useful for initial debugging.
sub midiincallback {
    my ($self, $msg, $instance, $param1, $param2) = @_;
    printf "<<<0x%x,0x%x,0x%x,0x%x>>>\n", $msg, $instance, $param1, $param2
	if $cb_debug;
    if ($msg == MIM_OPEN) {
	print "MIM_OPEN\n" if $cb_debug;
    } elsif ($msg == MIM_CLOSE) {
	print "MIM_CLOSE\n" if $cb_debug;
    } elsif ($msg == MIM_ERROR) {
	print "MIM_ERROR\n" if $cb_debug;
    } elsif ($msg == MIM_DATA) {
	print "MIM_DATA\n" if $cb_debug;
    } elsif ($msg == MIM_LONGDATA) {
	print "MIM_LONGDATA\n" if $cb_debug;
	my $midiHdr = unpack('P32', pack('L!', $param1));
	my @d = unpack('LL4LL2', $midiHdr);
	printf "lpData:%x,Buflen:%x,bytesrecorded:%d,dwUser:%x,dwFlags:%d\n",
	    @d[0..4] if $cb_debug;
	datadump(unpack("P$d[2]", $midiHdr)) if $cb_debug;
    } elsif ($msg == MIM_LONGERROR) {
	print "MIM_LONGERROR\n" if $cb_debug;
    } else {
	print "unknown message type\n" if $cb_debug;
    }
}

########################################################################
# get_midi_dev_info
# Returns
#   $midev : MIDI Input Device (Port) Number
#   $modev : MIDI Output Device (Port) Number
#   $devid : MIDI Device ID
sub get_midi_dev_info {
    my $interactive = shift;
    my ($midev, $modev, $devid);
    # create 't/devinfo' if you run this script often.
    if (!$interactive && -f 't/devinfo') {
	my $midi = new Win32API::MIDI;
	open(F, 't/devinfo') or die "cannot open 't/dev/info': $!\n";
	chomp(my $iname = <F>);
	chomp(my $oname = <F>);
	chomp($devid = <F>);
	close F;
	$midev = $midi->InGetDevNum($iname);
	$modev = $midi->OutGetDevNum($oname);
    } else {
	$midev = choose_midiin_dev();
	$modev = choose_midiout_dev();
	$devid = choose_device_id();
    }
    die "No MIDI In Device\n"  unless defined $midev;
    die "No MIDI Out Device\n" unless defined $modev;
    print "$midev, $modev, $devid\n";
    return ($midev, $modev, $devid);
}

sub choose_midiin_dev {
    my $midi = new Win32API::MIDI;
    # MIDI In Devs
    my $InNumDevs  = $midi->InGetNumDevs();
    return undef if $InNumDevs < 0;
    while (1) {
	print STDERR "Choose MIDI Input Device.\n";
	for (0..$InNumDevs-1) {
	    my $c = $midi->InGetDevCaps($_)
		or warn $midi->InGetErrorText(), "\n";
	    printf STDERR "%2d: $c->{szPname}\n", $_;
	}
	print STDERR "[0]> ";
	chomp($_ = <>);
	return $_ if (0 <= $_ && $_ < $InNumDevs);
	return 0 if $_ eq '';
    }
}

sub choose_midiout_dev {
    my $midi = new Win32API::MIDI;
    # MIDI Out Devs
    my $OutNumDevs  = $midi->OutGetNumDevs();
    return undef if $OutNumDevs < 0;
    while (1) {
	print STDERR "Choose MIDI Output Device.\n";
	for (-1..$OutNumDevs-1) {
	    my $c = $midi->OutGetDevCaps($_)
		or warn $midi->OutGetErrorText(), "\n";
	    printf STDERR "%2d: $c->{szPname}\n", $_;
	}
	print STDERR "[-1]> ";
	chomp($_ = <>);
	return $_ if (-1 <= $_ && $_ < $OutNumDevs);
	return -1 if $_ eq '';
    }
}

sub choose_device_id {
    while (1) {
	print STDERR "Choose Device ID (see your MIDI device manual.) [1-256]\n";
	print STDERR "[17]> ";
	chomp($_ = <>);
	return $_ if (1 <= $_ && $_ <= 256);
	# Roland uses `17' for the default value.
	return 17 if $_ eq '';
    }
}
