#!/usr/bin/perl
#
#	Receive MIDI System Exclusive Bulk Dump Data with Win32API::MIDI
#
#	Copyright (c) 2002 Hiroo Hayashi.  All rights reserved.
#		hiroo.hayashi@computer.org
#
#	This program is free software; you can redistribute it and/or
#	modify it under the same terms as Perl itself.
#
#	$Id: midisysexin.pl,v 1.4 2003-04-13 22:42:52-05 hiroo Exp $

use strict;
use Win32API::MIDI qw( /^(MIM_)/ MIDIERR_STILLPLAYING );
# Tie::Watch is included in Perl/Tk.  Instead of it we should use
# Win32::Event, but I have not test it.
use Tie::Watch;

# Static memory buffer for MIDI Input Data.
# Maxinum number of bytes of acutual data is 128 (0x7F+1). 256 is
# enough for a whole packet including packet header, etc.
my $SysXBuffer1 = "\0" x 256;
my $SysXBuffer2 = "\0" x 256;

my @data;
my $ignore_callback = 0;
my $get_sysex;
my $ndata = 0;
my $npacket = 0;

my $midev = choose_midiin_dev();

########################################################################
# MIDI In Callback Function

# From MSDN:
#	Applications should not call any system-defined functions from
#	inside a callback function, except for EnterCriticalSection,
#	LeaveCriticalSection, midiOutLongMsg, midiOutShortMsg,
#	OutputDebugString, PostMessage, PostThreadMessage, SetEvent,
#	timeGetSystemTime, timeGetTime, timeKillEvent, and
#	timeSetEvent.

# This means that we cannot use print() in the callback function.
# But print() is still useful for initial debugging.
my $cb_debug = 0;

# Return as early as possible.
sub midiCallback {
    my ($handle, $uMsg, $dwInstance, $dwParam1, $dwParam2) = @_;
    # ignore Timing Clock message (System Real Time Messages)
    return if ($uMsg == MIM_DATA and $dwParam1 == 0xf8);

    # Don't call MIDI functions when MIDI-In hanlder is closing.
    return if $ignore_callback;

    printf("midiCallback: %p, %x, %x, %x, %x\n",
	   $handle, $uMsg, $dwInstance, $dwParam1, $dwParam2) if $cb_debug;

    if ($uMsg == MIM_LONGDATA) {
	printf("MIM_LONGDATA:\n") if $cb_debug;
	$get_sysex = [ $handle, $dwInstance, $dwParam1, $dwParam2 ];
    } else {
	# Ignore other type of messages, MIM_OPEN, MIM_CLOSE,
	# MIM_ERROR, MIM_LONGERROR, MIM_MOREDATA, or MIM_DATA.
	printf("[%d]\n", $uMsg) if $cb_debug;
    }
}

########################################################################
# When $get_sysex is updated, copy data into @data, then queue the
# input buffer again.
sub copy_buf_data {
    my($self, $new_val) = @_;
    my ($handle, $dwInstance, $dwParam1, $dwParam2) = @{$new_val};

    my $midihdr = unpack('P32', pack('L!', $dwParam1));
    my $bytesrecorded = (unpack('LL4LL2', $midihdr))[2];

    push(@data, unpack("P$bytesrecorded", $midihdr));

    # Queue the MIDIHDR for more input
    $handle->PrepareHeader($dwParam1)	or die $handle->GetErrorText();
    $handle->AddBuffer($dwParam1)	or die $handle->GetErrorText();

    # for debugging
    $ndata += $bytesrecorded;
    $npacket++;
}

########################################################################
# Main Routine
my $midi = new Win32API::MIDI;

# Open default MIDI In device
my $handle = new Win32API::MIDI::In($midev, \&midiCallback)
    or die $midi->InGetErrorText();

sub Win32API::MIDI::In::queue_buf {
    my $handle = $_[0];
    my $buf = ${$_[1]};

    # Store pointer to our input buffer for System Exclusive messages
    # in MIDIHDR
    my $midihdr = pack("PLLLLPLL",
		       $buf,	# lpData
		       length $buf, # dwBufferLength
		       0,	# dwBytesRecorded
		       0xBEEF,	# dwUser (not used)
		       0,	# dwFlags must be set to 0
		       undef,	# lpNext
		       0,	# reserved
		       0);	# dwOffset

    my $lpMidiInHdr = unpack('L!', pack('P', $midihdr));
    # Prepare the buffer and MIDIHDR
    $handle->PrepareHeader($lpMidiInHdr) or die $handle->GetErrorText();
    # Queue MIDI input buffer
    $handle->AddBuffer($lpMidiInHdr)	 or die $handle->GetErrorText();

    return $lpMidiInHdr;
}

my $hdr1 = $handle->queue_buf(\$SysXBuffer1);
my $hdr2 = $handle->queue_buf(\$SysXBuffer2);

# Let copy_buf_data() be invoked when $get_sysex is updated.
Tie::Watch->new
    (
     -variable	=> \$get_sysex,
     -store	=> \&copy_buf_data,
    );

# Start recording Midi
$handle->Start()			or die $handle->GetErrorText();
# Wait for user to abort recording
print("Start sending Bulk Dump Data.\n");
print("Press Enter to stop recording...\n");
scalar <>;

print "npacket:$npacket\n";
print "ndata:$ndata\n";

# Without this line, midiInReset() hangs!
$ignore_callback = 1;

# Stop recording
$handle->Stop()				or die $handle->GetErrorText();
$handle->Reset()			or die $handle->GetErrorText();
# Close the MIDI In device
$handle->Close()			or die $handle->GetErrorText();

# Unprepare the buffer and MIDIHDR.
# You must use this function before freeing the buffer.
$handle->UnprepareHeader($hdr1);
$handle->UnprepareHeader($hdr2);

dump_data();

exit 0;

########################################################################
sub dump_data {
    foreach my $d (@data) {
	my $bytes = 16;
	foreach (unpack('C*', $d)) {
	    if (!(--$bytes)) {
		printf("%02X\n", $_);
		$bytes = 16;
	    } else {
		printf("%02X ", $_);
	    }
	}
	print "\n" unless $bytes == 16;
	print '-' x 48, "\n";
    }
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
