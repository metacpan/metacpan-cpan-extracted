#!/usr/bin/perl
#
#	$Id: MIDI.pm,v 1.12 2003-04-13 22:57:37-05 hiroo Exp $
#
#	Copyright (c) 2003 Hiroo Hayashi.  All rights reserved.
#
#	This program is free software; you can redistribute it and/or
#	modify it under the same terms as Perl itself.

package Win32API::MIDI;

=head1 NAME

Win32API::MIDI - Perl extension for MS Windows 32bit MIDI API

=head1 SYNOPSIS

  use Win32API::MIDI;
  $midi = new Win32API::MIDI;

  # MIDI::Out::ShortMsg
  $mo = new Win32API::MIDI::Out	or die $midi->OutGetErrorText();
  $mo->ShortMsg(0x00403C90)	or die $mo->GetErrorText();
  sleep(1);
  $mo->ShortMsg(0x00003C90)	or die $mo->GetErrorText();
  $mo->Close			or die $mo->GetErrorText();

See L<"EXAMPLE"> for more examples.

=head1 DESCRIPTION

=head2 Overview

Win32API::MIDI is a wrapper for MS Windows 32bit MIDI API.  It
supports all MS Windows 32bit MIDI API, MIDI output, input, and
stream API.  For more details about each API visit
http://msdn.microsoft.com/ and search for the word "MIDI".

This module is still under development.  Interface may be changed to
improve usability.

=cut

use 5.006;
use strict;
use warnings;
use Carp;
use Win32API::MIDI::Out;

require Exporter;
require DynaLoader;
#use AutoLoader;

our $VERSION = '0.05';

our @ISA = qw(Exporter DynaLoader);

our @EXPORT_OK = qw(
       CALLBACK_EVENT CALLBACK_FUNCTION CALLBACK_NULL CALLBACK_TASK
       CALLBACK_THREAD CALLBACK_TYPEMASK CALLBACK_WINDOW

       MEVT_COMMENT MEVT_EVENTPARM MEVT_EVENTTYPE MEVT_F_CALLBACK MEVT_F_LONG
       MEVT_F_SHORT MEVT_LONGMSG MEVT_NOP MEVT_SHORTMSG MEVT_TEMPO MEVT_VERSION

       MIDICAPS_CACHE MIDICAPS_LRVOLUME MIDICAPS_STREAM MIDICAPS_VOLUME

       MIDIMAPPER MIDIPATCHSIZE MIDIPROP_GET MIDIPROP_SET MIDIPROP_TEMPO
       MIDIPROP_TIMEDIV MIDISTRM_ERROR MIDI_CACHE_ALL MIDI_CACHE_BESTFIT
       MIDI_CACHE_QUERY MIDI_IO_STATUS MIDI_MAPPER MIDI_UNCACHE

       MIXERLINE_TARGETTYPE_MIDIIN MIXERLINE_TARGETTYPE_MIDIOUT
       MIXER_OBJECTF_HMIDIIN MIXER_OBJECTF_HMIDIOUT
       MIXER_OBJECTF_MIDIIN MIXER_OBJECTF_MIDIOUT

       MIDIERR_BADOPENMODE MIDIERR_BASE MIDIERR_DONT_CONTINUE
       MIDIERR_INVALIDSETUP MIDIERR_LASTERROR MIDIERR_NODEVICE MIDIERR_NOMAP
       MIDIERR_NOTREADY MIDIERR_STILLPLAYING MIDIERR_UNPREPARED

       MMSYSERR_ALLOCATED MMSYSERR_BADDB MMSYSERR_BADDEVICEID
       MMSYSERR_BADERRNUM MMSYSERR_BASE MMSYSERR_DELETEERROR MMSYSERR_ERROR
       MMSYSERR_HANDLEBUSY MMSYSERR_INVALFLAG MMSYSERR_INVALHANDLE
       MMSYSERR_INVALIDALIAS MMSYSERR_INVALPARAM MMSYSERR_KEYNOTFOUND
       MMSYSERR_LASTERROR MMSYSERR_NODRIVER MMSYSERR_NODRIVERCB
       MMSYSERR_NOERROR MMSYSERR_NOMEM MMSYSERR_NOTENABLED
       MMSYSERR_NOTSUPPORTED MMSYSERR_READERROR MMSYSERR_VALNOTFOUND
       MMSYSERR_WRITEERROR

       MM_MIM_CLOSE MM_MIM_DATA MM_MIM_ERROR MM_MIM_LONGDATA
       MM_MIM_LONGERROR MM_MIM_MOREDATA MM_MIM_OPEN

       MIM_CLOSE MIM_DATA MIM_ERROR MIM_LONGDATA
       MIM_LONGERROR MIM_MOREDATA MIM_OPEN

       MM_MOM_CLOSE MM_MOM_DONE MM_MOM_OPEN MM_MOM_POSITIONCB

       MOM_CLOSE MOM_DONE MOM_OPEN MOM_POSITIONCB

       TIME_CALLBACK_EVENT_PULSE TIME_CALLBACK_EVENT_SET
       TIME_CALLBACK_FUNCTION TIME_MIDI

       MOD_MIDIPORT MCIERR_SEQ_NOMIDIPRESENT MCI_SEQ_MIDI
      );

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "$& not defined" if $constname eq 'constant';
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/ || $!{EINVAL}) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	} else {
	    croak "Your vendor has not defined Win32API::MIDI macro $constname";
	}
    }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#	if ($] >= 5.00561) {
#	    *$AUTOLOAD = sub () { $val };
#	} else {
	    *$AUTOLOAD = sub { $val };
#	}
    }
    goto &$AUTOLOAD;
}

bootstrap Win32API::MIDI $VERSION;

# Preloaded methods go here.

=head2 Querying MIDI Devices

=over 4

=item C<$midi = new Win32API::MIDI>

Returns a object for InGetNumDevs(), OutGetNumDevs(), InGetDevCaps(),
OutGetDevCaps(), syserr(), InGetErrorText(), or OutGetErrorText().

=item C<$midi-E<gt>InGetNumDevs(void)>

Retrieves the number of MIDI input devices present in the system.
Returns zero if there is no device.

=item C<$midi-E<gt>OutGetNumDevs(void)>

Retrieves the number of MIDI output devices present in the system.
Returns zero if there is no device.

=item C<$midi-E<gt>InGetDevCaps(DeviceID)>

Retrieves the capabilities of a given MIDI input device and return
this information in a hash data whose keys are "wMid", "wPid",
"vDriverVersion", "szPname", and "dwSupport".

=item C<$midi-E<gt>OutGetDevCaps([DeviceID = MIDI_MAPPER])>

Retrieves the capabilities of a given MIDI output device and places
this information in a hash data whose keys are "wMid", "wPid",
"vDriverVersion", "szPname", "wTechnology", "wVoices", "wNotes",
"wChannelMask", and "dwSupport".

=item C<$midi-E<gt>syserr(void)>

Returns the return value of the MIDI function called recently.  Zero
means no error.

The only MIDI functions that do not return error codes are the
midiInGetNumDevs and midiOutGetNumDevs functions. These functions
return a value of zero if no devices are present in a system or if any
errors are encountered by the function.


=item C<$midi-E<gt>InGetErrorText([wError])>

Retrieves textual descriptions for the error codes given.  If the
error code is omitted, the error code for the MIDI function called
recently is used.

=item C<$midi-E<gt>OutGetErrorText([wError])>

Retrieves textual descriptions for the error codes given.  If the
error code is omitted, the error code for the MIDI function called
recently is used.

=item C<$midi-E<gt>InGetDevNum(name)>

Retrives the MIDI input device number whose C<szPname> entry of the
capabilityes list returned by C<InGetDevCaps()> matches C<name>.  If
there is no match, returns C<undef>.

This is not a part of MS Windows 32bit MIDI API.

=item C<$midi-E<gt>OutGetDevNum(name)>

Retrives the MIDI output device number whose C<szPname> entry of the
capabilityes list returned by C<OutGetDevCaps()> matches C<name>.  If
there is no match, returns C<undef>.

This is not a part of MS Windows 32bit MIDI API.

=back

=cut

sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return $self;
}

sub InGetNumDevs {
    my $self = shift;
    return midiInGetNumDevs();
}

sub OutGetNumDevs {
    my $self = shift;
    return midiOutGetNumDevs();
}

sub InGetDevCaps {
    my $self = shift;
    return midiInGetDevCaps(@_);
}

sub OutGetDevCaps {
    my $self = shift;
    return midiOutGetDevCaps(@_);
}

sub syserr {
    my $self = shift;
    return midisyserr();
}

sub InGetErrorText {
    my $self = shift;
    $self->Win32API::MIDI::In::GetErrorText(@_);
}

sub OutGetErrorText {
    my $self = shift;
    $self->Win32API::MIDI::Out::GetErrorText(@_);
}

sub InGetDevNum {
    my ($self, $name) = @_;
    my $NumDevs = $self->InGetNumDevs();
    for (0..$NumDevs-1) {
	my $c = $self->InGetDevCaps($_);
	unless ($c) {
	    carp $self->InGetErrorText(), "\n";
	    return undef;
	}
	return $_ if $c->{szPname} =~ $name;
    }
    return undef;
}

sub OutGetDevNum {
    my ($self, $name) = @_;
    my $NumDevs = $self->OutGetNumDevs();
    for (0..$NumDevs-1) {
	my $c = $self->OutGetDevCaps($_);
	unless ($c) {
	    carp $self->OutGetErrorText(), "\n";
	    return undef;
	}
	return $_ if $c->{szPname} =~ $name;
    }
    return undef;
}


package Win32API::MIDI::In;

=head2 Recording MIDI Audio

=head3 Opening and Closing MIDI Input Device

=over 4

=item C<$midiIn = new Win32API::MIDI::In(DeviceID,
 				 	 [Callback = undef,
				 	 [CallbackInstance = undef,
				 	 [Flags = CALLBACK_NULL]]]);>

Opens a specified MIDI input device for recording.

For Flags argument only CALLBACK_NULL and CALLBACK_FUNCTION are
supported now.

=item C<$midiIn-E<gt>GetID(void)>

Retrieves the device identifier for the given MIDI input device.

=item C<$midiIn-E<gt>Close(void)>

Closes the MIDI input device.

=back

=head3 Managing MIDI Recording

=over 4

=item C<$midiIn-E<gt>PrepareHeader($lpMidiInHdr)>

Prepares a MIDI input data block.

Preparing a header that has already been prepared has no effect, and
the function returns zero.

After the header has been prepared, do not modify the buffer.  To free
the buffer, use the UnprepareHeader method.

Before using this method, you must set the lpData, dwBufferLength,
and dwFlags members of the MIDIHDR structure.

The dwFlags member must be set to zero.

	# Example of how to use PrepareHeader()
	# create buffer
	$buf = "\0" x 1024;
	# make a pointer to MIDIHDR data structure
	# cf. perlpacktut in Perl 5.8.0 or later
	#     (http://www.perldoc.com/)
	$midihdr = pack ("PLLLLPLL",
			 $buf,		# lpData
			 length $buf,	# dwBufferLength
			 0,		# dwBytesRecorded
			 0xBEEF,	# dwUser
			 0,		# dwFlags (must be zero)
			 undef,		# lpNext
			 0,		# reserved
			 0);		# dwOffset
	$lpMidiInHdr = unpack('L!', pack('P', $midihdr));
	# pass the pointer to PrepareHeader()
	$midiIn->PrepareHeader($lpMidiInHdr);

=item C<$midiIn-E<gt>UnprepareHeader($lpMidiInHdr)>

Cleans up the preparation of a MIDI input data block.

=item C<$midiIn-E<gt>AddBuffer($lpMidiInHdr)>

Sends a buffer to the device driver so it can be filled with recorded
system exclusive MIDI data.

=item C<$midiIn-E<gt>Reset(void)>

Stops MIDI recording and marks all pending buffers as done.

=item C<$midiIn-E<gt>Start(void)>

Starts MIDI recording and resets the time stamp to zero.

=item C<$midiIn-E<gt>Stop(void)>

Stops MIDI recording.

=item C<$midiIn-E<gt>GetErrorText([$mmsyserr])>

Retrieves textual descriptions for the error codes given.  If the
error code is omitted, the error code for the MIDI function called
recently is used.

=item C<$midiIn-E<gt>Connect($midi_thru_or_output)>

Connects a MIDI input device to a MIDI thru or output device.

=item C<$midiIn-E<gt>Disconnect($midi_thru_or_output)>

Disconnects a MIDI input device from a MIDI thru or output device.

=back

=cut

sub new {
    my $class = shift;
    my $self = Open(@_);
    bless $self, $class if defined $self;
    return $self;
}

# Commented out because this is invoked when a callback function finishes.
#  sub DESTROY {
#      my $self = shift;
#      $self->Close;
#  }

sub Connect {
    Win32API::MIDI::midiConnect(@_);
}

sub Disconnect {
    Win32API::MIDI::midiDisconnect(@_);
}


package Win32API::MIDI::Out;

=head2 Playing MIDI

=head3 Opening and Closing MIDI Output Device

=over 4

=item C<$midiOut = new Win32API::MIDI::Out([DeviceID = MIDI_MAPPER,
 					   [Callback = undef,
					   [CallbackInstance = undef,
					   [Flags = CALLBACK_NULL]]]]);>

Opens a MIDI output device for playback.

For Flags argument only CALLBACK_NULL is supported now.

=item C<$midiOut-E<gt>GetID(void)>

Retrieves the device identifier for the given MIDI output device.

=item C<$midiOut-E<gt>Close(void)>

Closes a specified MIDI output device.

=back

=head3 Sending Individual MIDI Messages

=over 4

=item C<$midiOut-E<gt>ShortMsg(Msg)>

Sends a MIDI message to a specified MIDI output device.

=item C<$midiOut-E<gt>PrepareHeader($lpMidiOutHdr)>

Prepares a MIDI output data block.

Preparing a header that has already been prepared has no effect, and
the method returns zero.

After the header has been prepared, do not modify the buffer.  To free
the buffer, use the UnprepareHeader method.

Before using this method, you must set the lpData, dwBufferLength, and
dwFlags members of the MIDIHDR structure.

The dwFlags member must be set to zero.

A stream buffer cannot be larger than 64K.

	# Example of how to use PrepareHeader()
	# "Set Master Volume" System Exclusive Message
	$buf = "\xf0\x7f\x7f\x04\x01\x7f\x7f\xf7";
	# make a pointer to MIDIHDR data structure
	# cf. perlpacktut in Perl 5.8.0 or later
	#     (http://www.perldoc.com/)
	$midihdr = pack ("PLLLLPLL",
			 $buf,		# lpData
			 length $buf,	# dwBufferLength
			 0,		# dwBytesRecorded
			 0,		# dwUser
			 0,		# dwFlags (must be zero)
			 undef,		# lpNext
			 0,		# reserved
			 0);		# dwOffset
	$lpMidiOutHdr = unpack('L!', pack('P', $midihdr));
	# pass the pointer to PrepareHeader()
	$midiOut->PrepareHeader($lpMidiOutHdr);

=item C<$midiOut-E<gt>UnprepareHeader($lpMidiOutHdr)>

Cleans up the preparation of a MIDI output data block.

=item C<$midiOut-E<gt>LongMsg($lpMidiOutHdr)>

Sends a buffer of MIDI data to the specified MIDI output device. Use
this function to send system-exclusive messages to a MIDI device.

=back

=head3 Misc.

=over 4

=item C<$midiOut-E<gt>GetErrorText([mmsyserr])>

Retrieves textual descriptions for the error codes given.  If the
error code is omitted, the error code for the MIDI function called
recently is used.

=item C<$midiOut-E<gt>Reset(void)>

Turns off all notes on all channels for a specified MIDI output
device. Any pending system-exclusive buffers and stream buffers are
marked as done and returned to the application.

=item C<$midiOut-E<gt>Connect($midi_output)>

Connects a MIDI thru device to a MIDI output device.

=item C<$midiOut-E<gt>Disconnect($midi_output)>

Disconnects a MIDI thru device from a MIDI output device.

=back

=cut

sub new {
    my $class = shift;
    my $self = Open(@_);
    bless $self, $class if defined $self;
    return $self;
}

# Commented out because this is invoked when a callback function finishes.
#  sub DESTROY {
#      my $self = shift;
#      $self->Close;
#  }

# for MIDI through device
sub Connect {
    my $thru = shift;
    my $out = shift;
    Win32API::MIDI::midiConnect($thru, $out);
}

# for MIDI through device
sub Disconnect {
    Win32API::MIDI::midiDisconnect(@_);
}


package Win32API::MIDI::Stream;

=head2 Sending MIDI Messages with Stream Buffers

=over 4

=item C<$midiStream = new Win32API::MIDI::Stream([DeviceID = MIDI_MAPPER,
						 [Callback = undef,
						 [CallbackInstance = undef,
						 [Flags = CALLBACK_NULL]]]]);>

Opens a MIDI stream for output. By default, the device is opened in
paused mode.

For Flags argument only CALLBACK_NULL is supported now.

=item C<$midiStream-E<gt>Close(void)>

Closes an open MIDI stream.

=item C<$midiStream-E<gt>PrepareHeader($lpMidiInHdr)>

Prepares a MIDI stream data block.

Preparing a header that has already been prepared has no effect, and
the function returns zero.

After the header has been prepared, do not modify the buffer.  To free
the buffer, use the midiInUnprepareHeader function.

Before using this function, you must set the lpData, dwBufferLength,
and dwFlags members of the MIDIHDR structure.

The dwFlags member must be set to zero.

A stream buffer cannot be larger than 64K.

=item C<$midiStream-E<gt>UnprepareHeader($lpMidiInHdr)>

Cleans up the preparation of a MIDI output data block.

=item C<$midiStream-E<gt>Out($midiOutHdr)>

Plays or queues a stream (buffer) of MIDI data to a MIDI output
device.

=item C<$midiStream-E<gt>Pause(void)>

Pauses playback of a specified MIDI stream.

=item C<$midiStream-E<gt>Restart(void)>

Restarts a paused MIDI stream.

=item C<$midiStream-E<gt>Stop(void)>

Turns off all notes on all MIDI channels for the specified MIDI output
device.

=item C<$midiStream-E<gt>GetErrorText([$mmsyserr])>

Retrieves textual descriptions for the error codes given.  If the
error code is omitted, the error code for the MIDI function called
recently is used.

=item C<$midiStream-E<gt>Position($lpmmtime)>

Retrieves the current position in a MIDI stream.

=item C<$midiStream-E<gt>Property($lppropdata, $dwProperty)>

Sets or retrieves properties of a MIDI data stream associated with a
MIDI output device.

=back

=cut

sub new {
    my $class = shift;
    my $self = Open(@_);
    bless $self, $class if defined $self;
    return $self;
}

sub PrepareHeader {
    my $self = shift;
    $self->Win32API::MIDI::Out::PrepareHeader(@_);
}

sub UnprepareHeader {
    my $self = shift;
    $self->Win32API::MIDI::Out::UnprepareHeader(@_);
}

sub GetErrorText {
    my $self = shift;
    $self->Win32API::MIDI::Out::GetErrorText(@_);
}

# Commented out because this is invoked when a callback function finishes.
#  sub DESTROY {
#      my $self = shift;
#      $self->Close;
#  }

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 EXPORT

None by default.  The following constant values can be exported.

       CALLBACK_EVENT CALLBACK_FUNCTION CALLBACK_NULL CALLBACK_TASK
       CALLBACK_THREAD CALLBACK_TYPEMASK CALLBACK_WINDOW

       MEVT_COMMENT MEVT_EVENTPARM MEVT_EVENTTYPE MEVT_F_CALLBACK MEVT_F_LONG
       MEVT_F_SHORT MEVT_LONGMSG MEVT_NOP MEVT_SHORTMSG MEVT_TEMPO MEVT_VERSION

       MIDICAPS_CACHE MIDICAPS_LRVOLUME MIDICAPS_STREAM MIDICAPS_VOLUME

       MIDIMAPPER MIDIPATCHSIZE MIDIPROP_GET MIDIPROP_SET MIDIPROP_TEMPO
       MIDIPROP_TIMEDIV MIDISTRM_ERROR MIDI_CACHE_ALL MIDI_CACHE_BESTFIT
       MIDI_CACHE_QUERY MIDI_IO_STATUS MIDI_MAPPER MIDI_UNCACHE

       MIXERLINE_TARGETTYPE_MIDIIN MIXERLINE_TARGETTYPE_MIDIOUT
       MIXER_OBJECTF_HMIDIIN MIXER_OBJECTF_HMIDIOUT
       MIXER_OBJECTF_MIDIIN MIXER_OBJECTF_MIDIOUT

       MIDIERR_BADOPENMODE MIDIERR_BASE MIDIERR_DONT_CONTINUE
       MIDIERR_INVALIDSETUP MIDIERR_LASTERROR MIDIERR_NODEVICE MIDIERR_NOMAP
       MIDIERR_NOTREADY MIDIERR_STILLPLAYING MIDIERR_UNPREPARED

       MMSYSERR_ALLOCATED MMSYSERR_BADDB MMSYSERR_BADDEVICEID
       MMSYSERR_BADERRNUM MMSYSERR_BASE MMSYSERR_DELETEERROR MMSYSERR_ERROR
       MMSYSERR_HANDLEBUSY MMSYSERR_INVALFLAG MMSYSERR_INVALHANDLE
       MMSYSERR_INVALIDALIAS MMSYSERR_INVALPARAM MMSYSERR_KEYNOTFOUND
       MMSYSERR_LASTERROR MMSYSERR_NODRIVER MMSYSERR_NODRIVERCB
       MMSYSERR_NOERROR MMSYSERR_NOMEM MMSYSERR_NOTENABLED
       MMSYSERR_NOTSUPPORTED MMSYSERR_READERROR MMSYSERR_VALNOTFOUND
       MMSYSERR_WRITEERROR

       MM_MIM_CLOSE MM_MIM_DATA MM_MIM_ERROR MM_MIM_LONGDATA
       MM_MIM_LONGERROR MM_MIM_MOREDATA MM_MIM_OPEN

       MIM_CLOSE MIM_DATA MIM_ERROR MIM_LONGDATA
       MIM_LONGERROR MIM_MOREDATA MIM_OPEN

       MM_MOM_CLOSE MM_MOM_DONE MM_MOM_OPEN MM_MOM_POSITIONCB

       MOM_CLOSE MOM_DONE MOM_OPEN MOM_POSITIONCB

       TIME_CALLBACK_EVENT_PULSE TIME_CALLBACK_EVENT_SET
       TIME_CALLBACK_FUNCTION TIME_MIDI

       MOD_MIDIPORT MCIERR_SEQ_NOMIDIPRESENT MCI_SEQ_MIDI

=head1 EXAMPLE

The files under F<t/> and F<eg/> directory are actual working examples.

  use Win32API::MIDI qw( /^(MIM_)/ );
  $midi = new Win32API::MIDI;

  # MIDI::Out::ShortMsg
  $mo = new Win32API::MIDI::Out		or die $midi->OutGetErrorText();
  $mo->ShortMsg(0x00403C90)		or die $mo->GetErrorText();
  sleep(1);
  $mo->ShortMsg(0x00003C90)		or die $mo->GetErrorText();
  $mo->Close				or die $mo->GetErrorText();

  # MIDI::Out::LongMsg
  $mo = new Win32API::MIDI::Out		or die $midi->OutGetErrorText();
  # sysEx: Set Master Volume
  $m = "\xf0\x7f\x7f\x04\x01\x7f\x7f\xf7";
  $midiHdr = pack ("PL4PL6",
  		   $m,	# lpData
  		   length $m, # dwBufferLength
  		   0, 0, 0, undef, 0, 0);
  $mo->PrepareHeader(unpack('L!', pack('P',$midiHdr)))
			 		or die $mo->GetErrorText();
  $mo->LongMsg($lpMidiOutHdr)		or die $mo->GetErrorText();
  $mo->UnprepareHeader($lpMidiOutHdr)	or die $mo->GetErrorText();
  $mo->Close				or die $mo->GetErrorText();

  # MIDI::Stream
  $ms = new Win32API::MIDI::Stream()	or die $midi->OutGetErrorText();
  $buf = pack('L*',
	      # System Exclusive (Set Master Volume Full)
	      0,  0, (&MEVT_LONGMSG << 24) | 8, 0x047F7FF0, 0xF77F7F01,
	      # Short Messages
	      0,  0, 0x007F3C90,
	      48, 0, 0x00003C90);
  $midihdr = pack("PLLLLPLL",
		  $buf,	# lpData
		  length $buf,	# dwBufferLength
		  length $buf,	# dwBytesRecorded
		  0,		# dwUser
		  0,		# dwFlags
		  undef,	# lpNext
		  0,		# reserved
		  0);		# dwOffset
  $lpMidiHdr = unpack('L!', pack('P', $midihdr));
  $ms->PrepareHeader($lpMidiHdr)	or die $ms->GetErrorText();
  $ms->Out($lpMidiHdr)			or die $ms->GetErrorText();
  $ms->Restart()			or die $ms->GetErrorText();
  sleep(1);
  $ms->UnprepareHeader($lpMidiHdr)	or die $ms->GetErrorText();
  $ms->Close()				or die $ms->GetErrorText();

  # MIDI::In
  $mi = new Win32API::MIDI::In(0, \&midiincallback, 0x1234)
					or die $midi->InGetErrorText();
  sub midiincallback {
    my ($self, $msg, $instance, $param1, $param2) = @_;
    if ($msg == MIM_OPEN) {
  	  print "MIM_OPEN\n";
  	  ...
    } elsif ($msg == MIM_LONGDATA) {
  	  print "MIM_LONGDATA\n";
  	  ...
    }
  }
  $buf = "\0" x 1024;
  $midihdr = pack ("PLLLLPLL",
		   $buf,	# lpData
		   length $buf, # dwBufferLength
		   0,		# dwBytesRecorded
		   0xBEEF,	# dwUser
		   0,		# dwFlags
		   undef,	# lpNext
		   0,		# reserved
		   0);		# dwOffset
  $lpMidiInHdr = unpack('L!', pack('P', $midihdr));
  $mi->PrepareHeader($lpMidiInHdr)	or die $mi->GetErrorText();
  $mi->AddBuffer($lpMidiInHdr)		or die $mi->GetErrorText();
  $mi->Start				or die $mi->GetErrorText();
  # do some job here
  $mi->Stop				or die $mi->GetErrorText();
  $mi->Reset				or die $mi->GetErrorText();
  $mi->UnprepareHeader($lpMidiInHdr)	or die $mi->GetErrorText();
  $mi->Close()				or die $ms->GetErrorText();

  sub midiincallback {
      my ($self, $msg, $instance, $param1, $param2) = @_;
      printf "<<<0x%x,0x%x,0x%x,0x%x>>>\n", $msg, $instance, $param1, $param2;
      if ($msg == MIM_OPEN) {
  	  print "MIM_OPEN\n";
      } elsif ($msg == MIM_CLOSE) {
  	  print "MIM_CLOSE\n";
      } elsif ($msg == MIM_ERROR) {
  	  print "MIM_ERROR\n";
      } elsif ($msg == MIM_DATA) {
  	  print "MIM_DATA\n";
      } elsif ($msg == MIM_LONGDATA) {
  	  print "MIM_LONGDATA\n";
  	  my $midiHdr = unpack('P32', pack('L!', $param1));
  	  my @d = unpack('LL4LL2', $midiHdr);
  	  printf "lpData:%x,Buflen:%x,bytesrecorded:%d,dwUser:%x,dwFlags:%d\n",
  	      @d[0..4];
  	  datadump(unpack("P$d[2]", $midiHdr));
      } elsif ($msg == MIM_LONGERROR) {
  	  print "MIM_LONGERROR\n";
      } else {
  	  print "unknown message type\n";
      }
  }

=head1 AUTHOR

Hiroo Hayashi, E<lt>hiroo.hayashi@computer.orgE<gt>

=head1 SEE ALSO

=over 4

=item MICROSOFT Developer Network (C<http://msdn.microsoft.com/library/>)

	Graphics and Multimedia
	-> Windows Multimedia
	-> SDK Documentation
	-> Windows Multimedia
	-> Multimedia Audio
	-> Musical Instrument Digital Interface (MIDI)

=item Win32API::MIDI::Out

=item Win32API::MIDI::SysEX

=back

=head1 TODO

More test.

=head1 BUGS

If you find bugs, report to the author.  Thank you.

=cut
