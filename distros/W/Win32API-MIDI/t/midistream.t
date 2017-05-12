# -*- perl -*-
#	midistream.t : test MIDI::Stream
#
#	Copyright (c) 2003 Hiroo Hayashi.  All rights reserved.
#		hiroo.hayashi@computer.org
#
#	This program is free software; you can redistribute it and/or
#	modify it under the same terms as Perl itself.
#
#	$Id: midistream.t,v 1.5 2003-03-30 13:06:24-05 hiroo Exp $

use strict;
use Test;
use vars qw($ntest);
BEGIN { $ntest = 9; plan tests => $ntest; };
use Win32API::MIDI qw( /^(MEVT_)/ );
#use Data::Dumper;
ok(1); # If we made it this far, we're ok.

my $midi = new Win32API::MIDI;
ok(1);

if ($midi->OutGetNumDevs() == 0){
    skip('need MIDI Output device', 'skipping t/midiout.t') for (1..$ntest-3);
    exit 0;
}
ok(1);

my $ms = new Win32API::MIDI::Stream()	or die $midi->OutGetErrorText();
ok(1);

# borrowed from Stream.c
my $buf = pack('L*',
	       # System Exclusive (set master volume full)
	       0,  0, (&MEVT_LONGMSG << 24) | 8, 0x047F7FF0, 0xF77F7F01,
	       # set tempo (0x20000 microsecond per quarter note)
	       0,  0, (&MEVT_TEMPO<<24) | 0x00020000,
	       # short messages
	       0,  0, 0x007F3C90,
	       48, 0, 0x00003C90,
	       0,  0, 0x007F3C90,
	       48, 0, 0x00003C90,

	       0,  0, 0x007F4390,
	       48, 0, 0x00004390,
	       0,  0, 0x007F4390,
	       48, 0, 0x00004390,

	       0,  0, 0x007F4590,
	       48, 0, 0x00004590,
	       0,  0, 0x007F4590,
	       48, 0, 0x00004590,

	       0,  0, 0x007F4390,
	       86, 0, 0x00004390,

	       10, 0, 0x007F4190,
	       48, 0, 0x00004190,
	       0,  0, 0x007F4190,
	       48, 0, 0x00004190,

	       0,  0, 0x007F4090,
	       48, 0, 0x00004090,
	       0,  0, 0x007F4090,
	       48, 0, 0x00004090,

	       0,  0, 0x007F3E90,
	       48, 0, 0x00003E90,
	       0,  0, 0x007F3E90,
	       48, 0, 0x00003E90,

	       0,  0, 0x007F3C90,
	       96, 0, 0x00003C90);
my $midihdr = pack ("PLLLLPLL",
		    $buf,	# lpData
		    length $buf, # dwBufferLength
		    length $buf, # dwBytesRecorded
		    0,		# dwUser
		    0,		# dwFlags
		    undef,	# lpNext
		    0,		# reserved
		    0);		# dwOffset
my $lpMidiHdr = unpack('L!', pack('P', $midihdr));

$ms->PrepareHeader($lpMidiHdr)		or die $ms->GetErrorText(); ok(1);
$ms->Out($lpMidiHdr)			or die $ms->GetErrorText(); ok(1);
$ms->Restart()				or die $ms->GetErrorText(); ok(1);
sleep(5);
$ms->UnprepareHeader($lpMidiHdr)	or die $ms->GetErrorText(); ok(1);
$ms->Close()				or die $ms->GetErrorText(); ok(1);

exit;
