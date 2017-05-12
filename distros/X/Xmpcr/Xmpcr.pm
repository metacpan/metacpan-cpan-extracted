package Audio::Xmpcr;

$VERSION="1.02";

use strict;
use Audio::Xmpcr::Serial;
use Audio::Xmpcr::Network;

sub new {
	my($class,%args)=@_;
	if ($args{SERIALPORT}) {
		return new Audio::Xmpcr::Serial($args{SERIALPORT});
	} elsif ($args{NETHOST}) {
		return new Audio::Xmpcr::Network($args{NETHOST},$args{NETPORT},
															$args{LOCKER});
	} elsif ($args{LOADTEST}) {
		# just return a blessed hash, for loading/testing purposes
		my $ref={};
		bless $ref, $class;
		return $ref;
	} else {
		die "Xmpcr: unknown API mode - must use either NET/SERIAL method.\n";
	}
}

=pod

=head1 NAME

Audio::Xmpcr - control an XMPCR device for XM Radio

=head1 SYNOPSIS

	use Audio::Xmpcr;

=head1 DESCRIPTION

The Audio::Xmpcr module allows you to control an XMPCR device,
which is used to tune into the XM satellite radio network.
More info can be found at http://www.xmradio.com. The device
itself can only be purchased (as of this writing) at PCConnection
http://www.pcconnection.com.

The api operates in one of two modes. First, a direct SERIAL
mode where the api communicates with the device directly. This is usually
not desirable because polling the device for song data is time consuming.
Time required to pull an entire channel/song/artist listing is upwards
of 10-20 seconds. Also, the device may be shared by several users/programs.
Protocol confusion may result if everyone is talking at the same time.
Note that the serial mode will write a channel cache file into 
~/.xmpcrd-cache, so if the channel list changes, you'll need to delete
this file and restart the program. (i.e., since the daemon uses serial
mode, you'll need to restart the daemon)

The second mode of operation is NETWORK/DAEMON mode. Here, a daemon
runs on the machine connected to the Pcr, and all communication with the
daemon is done via sockets. This is preferable for most applications, as
the daemon takes care of much of the busy work. In particular, the
daemon continuously polls the device, and updates its internal channel
listing. The default timing allows 4 channels to be updated each second.
Also, every half second, the current channel is updated - since we always
want to know when the channel data changes on the current channel. This
means that it takes 100/4 or 25 seconds to refresh all channels. When
retrieving a channel/song listing, a few channels may be out of date, 
but will most certainly be correct the next pass through.  See the note
about the cache file in the SERIAL mode paragraph, above.

The mode is chosen when the device is instantiated - i.e., the constructor
is an abstract factory for the two types of connections. Regardless of the 
mode chosen, the interface supports the same method calls and behaviour 
with few exceptions. That is, you won't care whether you're talking 
directly to the device or the daemon - the api will return the same 
results either way. The following is a list of exceptions to that rule:

=over 1

=item list()

Via daemon, this call returns almost immediately; via SERIAL, dramatically slower (i.e., a full channel pull will take between 10-20 secs)

=item events() and processEvents()

Channel events are not supported in the SERIAL api.

=back 1

=head1 METHOD CALLS

=over 4

=item new(KEY => VALUE,...)

Creates a new Xmpcr object. Preferably, use the network mode;
use the serial mode if you're unable to run a daemon.

my $radio=new Xmpcr(SERIALPORT => "/dev/ttyUSB0")

or...

my $radio=new Xmpcr(NETHOST => "localhost",NETPORT => 32463,LOCKER => "appname");
(port and locker are optional)

Since many users may use the device when the daemon is running, you have
the option of locking the device to prevent channel changes/power off
from occuring. When LOCKER is specified, no other networked API user
may change the channel or power off if their appname is different. For
example, you have a program with the LOCKER 'ripper', which is busily
recording show data - you don't want the channel to be changed. Another
API user whose appname is 'web-interface' may attempt to change the
channel, but the call will be refused. When the locker powers the 
device off, it will be freed for use by other applications.

It may take a few tens-of-seconds to power on the device, since a
channel scan must be performed.  

=item power("on"/"off")

Turns the power to the XmPCR on or off. While off, no commands may
be executed (other than to turn the power on).

Returns undef if successful, or an error string if call failed.

=item mute("on"/"off")

Turns the mute control on or off. 

Returns undef if successful, or an error string if call failed.

=item setchannel(integer)

Sets the receiver channel.

Returns undef if successful, or an error string if call failed.

=item list() (pull entire channel list)

=item list(integer) (pull single channel list)

Loads channel data. The "single channel" mode returns a reference
to a single hash; the "entire list mode" returns an array of hashes. 
In serial mode (both entire and single list), the data is pulled 
directly from the device; the full channel listing takes some time. 
In network mode, a single channel is also pulled directly from the 
device (since it's fairly quick), but a full channel listing is 
pulled from a cache. This cache is continually refreshed in the 
background by the daemon, about every 20 seconds. Therefore, when
the network/entire list is pulled, there's a chance that a few of the
song titles will be incorrect, but they will be corrected shortly 
thereafter. (The currently selected channel is refreshed every
.5 second, so it will always be accurate).  A channel entry has the keys:

=over 1

=item NUM 

Channel number

=item NAME 

Name of channel

=item CAT 

Category of channel

=item SONG 

Title of song

=item ARTIST 

Name of artist

=back

returns an empty hash/array if the operation fails.

=item status() 

Returns status data. Returns a hash with the following keys:

=over 1

=item POWER

on/off

=item ANTENNA

0-100 (percent)

=item NUM

integer (channel num)

=item NAME

string (channel name)

=item CAT

string (channel category)

=item SONG

string (currently playing song)

=item ARTIST

string (currently playing artist)

=item RADIOID

8-character string

=back 1

Hash may have undefined/null values if operation failed - but POWER will
always be defined.

=item events("on"/"off")

Turns event delivery on or off. Whenever a song changes, the API will
automatically track channels that change songs, and deliver these
changes to you. (see the processEvents() call)

This call is only supported in network mode, and always returns success.

=item processEvents()

If event delivery is enabled, you may use this call to see which
channels have changed songs. It returns an array of hashes, each containing
data about any channels that have changed. See the list() method for
a hash key description.

Because the daemon broadcasts event changes to all interested parties,
it is important that you call processEvents() periodically - perhaps 
every second - to avoid buffer overrun and data loss. (The alternative
is to provide a separate thread to check the daemon, but not every environment
is ready to run threads yet). You may also use the eventFd() call for
use in select() statements (see eventFd()).

This call is only supported in network mode. An empty list will be
returned if event deliver (via events()) is disabled.

=item eventFd()

Returns a single file descriptor (*not* a file handle) for use in
select() calls. Useful when you need to monitor your own file handles
for input/output, and also need to check for song events. When select
indicates that the descriptor is ready for I/O, call processEvents to
determine what was sent. Please do not try to send or receive data using
the descriptor; let the API do that.

=item forcelock()

If the PCR is locked by a program that has exited and was unable to
turn off the radio, the daemon may remain locked, and no other programs
will be able to use the device. This call removes the lock, allowing
the radio to be turned off via the 'power' call.

=back

=head1 AUTHOR AND COPYRIGHT

This code is modeled after a Perl module written by Chris Carlson
(c@rlson.net). Only the low-level protocol communication was derived 
from his work (which was further derived from another author's Visual 
Basic project). 

Copyright (c) 2003 Paul Bournival.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the terms
of the Artistic License, distributed with Perl.

=head1 SEE ALSO

The XMPCR module, available from http://xmpcr.sf.net


=cut

1;
