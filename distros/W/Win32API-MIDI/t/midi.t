# -*- perl -*-
#	midi.t : test Win32API::MIDI
#
#	Copyright (c) 2003 Hiroo Hayashi.  All rights reserved.
#		hiroo.hayashi@computer.org
#
#	This program is free software; you can redistribute it and/or
#	modify it under the same terms as Perl itself.
#
#	$Id: midi.t,v 1.4 2003-03-30 13:05:34-05 hiroo Exp $

use strict;
use Test;
use Data::Dumper;
BEGIN { plan tests => 9 };
use Win32API::MIDI qw( /^(CALLBACK_|TIME_|MIDIERR_)/ );
ok(1); # If we made it this far, we're ok.

# test new
my $midi = new Win32API::MIDI;
ok(1);

# MIDI In Devs
my $InNumDevs  = $midi->InGetNumDevs();
ok(1);
for (0..$InNumDevs-1) {
    my $c = $midi->InGetDevCaps($_)
	or print $midi->InGetErrorText(), "\n";
    print "MIDI In Dev: $_\n";
    print Dumper(\$c);
}
ok(1);

# MIDI Out Devs
my $OutNumDevs = $midi->OutGetNumDevs();
ok(1);
for (-1..$OutNumDevs-1) {
    my $c = $midi->OutGetDevCaps($_)
	or print $midi->OutGetErrorText(), "\n";
    print "MIDI Out Dev: $_\n";
    print Dumper(\$c);
}
ok(1);

# test constant value
ok(CALLBACK_EVENT, 0x50000);
ok(TIME_CALLBACK_EVENT_PULSE, 32);
ok(MIDIERR_NODEVICE, 64+4);

exit;
