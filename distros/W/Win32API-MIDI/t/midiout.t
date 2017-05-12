# -*- perl -*-
#	midiout.t : test Win32API::MIDI::Out
#
#	Copyright (c) 2003 Hiroo Hayashi.  All rights reserved.
#		hiroo.hayashi@computer.org
#
#	This program is free software; you can redistribute it and/or
#	modify it under the same terms as Perl itself.
#
#	$Id: midiout.t,v 1.6 2003-03-30 13:06:24-05 hiroo Exp $

use strict;
use Test;
use vars qw($ntest);
BEGIN { $ntest = 13; plan tests => $ntest; };
use Win32API::MIDI;
use Data::Dumper;
ok(1); # If we made it this far, we're ok.

my $midi = new Win32API::MIDI;
ok(1);

use Win32API::MIDI::SysEX;
ok(1);

if ($midi->OutGetNumDevs() == 0){
    skip('need MIDI Output device', 'skipping t/midiout.t') for (1..$ntest-3);
    exit 0;
}
ok(1);

# for debug
sub datadump {
    my ($m) = @_;
    my $l = length $m;
    foreach (unpack 'C*', $m) { printf "%02x ", $_; }; print ":length $l\n";
}

########################################################################
# open MIDI out device using default device
my $mo = new Win32API::MIDI::Out()	or die $midi->OutGetErrorText();
ok(1);

# test Short Message Out
testShortMsg($mo);
# test MIDI Out prepare/Unparepare Header
out_header_test($mo);
# System Exclusive Out
system_exclusive_test($mo);

# Close the MIDI device
$mo->Close	or die $midi->OutGetErrorText();
ok(1);

exit 0;

########################################################################
sub system_exclusive_test {
    my $mo = shift;
    # create a generic System Exclusive object
    my $se = new Win32API::MIDI::SysEX;
    ok(1);

    print "Turn General MIDI 1 On\n";
    $mo->SysEX($se->GM1SystemOn)	or die $mo->GetErrorText();
    ok(1);
    print "Turn General MIDI 1 Off\n";
    $mo->SysEX($se->GMSystemOff)	or die $mo->GetErrorText();
    ok(1);
    print "Turn General MIDI 2 On\n";
    $mo->SysEX($se->GM2SystemOn)	or die $mo->GetErrorText();
    ok(1);
}

sub out_header_test {
    my $mo = shift;

    my $buf = "abcdef";
    my $bufsize = length $buf;

    # make a pointer to MIDIHDR data structure
    # cf. perlpacktut in Perl 5.8.0 or later
    #     (http://www.perldoc.com/)
    my $midihdr = pack ("PLLLLPLL",
			$buf,	# lpData
			length $buf, # dwBufferLength
			0,	# dwBytesRecorded
			0xDEAD,	# dwUser
			0,	# dwFlags
			undef,	# lpNext
			0,	# reserved
			0);	# dwOffset
    my $lpMidiOutHdr = unpack('L!', pack('P', $midihdr));
    printf "lpMidiOutHdr: 0x%08x\n", $lpMidiOutHdr;

    my @h = unpack("P${bufsize}LLLLpLL", $midihdr);
    print Dumper(@h);

    $mo->PrepareHeader($lpMidiOutHdr) or die $mo->GetErrorText();
    ok(1);

    $mo->UnprepareHeader($lpMidiOutHdr) or die $mo->GetErrorText();
    ok(1);

#    my $hdr = unpack('P', pack('L!', $lpMidiOutHdr));
    my @d = unpack('LL4LL', $midihdr);
    my $lpData = $d[0];
#      printf("lpData:0x%x,0x%p,0x%x,$lpData\n",
#  	   $lpData,		# == $ptr (correct)
#  	   $lpData,		# What does %p show?
#  	   unpack('P1024', pack('L!', $lpData)));

    @h = unpack("P${bufsize}LLLLpLL", $midihdr);
    print Dumper(@h);
}

sub testShortMsg {
    my $mo = shift;
    # Output the C note (ie, sound the note)
    $mo->ShortMsg(0x00403C90) or die $mo->GetErrorText();
    # Output the E note
    $mo->ShortMsg(0x00404090) or die $mo->GetErrorText();
    # Output the G note
    $mo->ShortMsg(0x00404390) or die $mo->GetErrorText();
    sleep(1);
    # turn off those 3 notes
    $mo->ShortMsg(0x00003C90) or die $mo->GetErrorText();
    $mo->ShortMsg(0x00004090) or die $mo->GetErrorText();
    $mo->ShortMsg(0x00004390) or die $mo->GetErrorText();
    ok(1);
}
