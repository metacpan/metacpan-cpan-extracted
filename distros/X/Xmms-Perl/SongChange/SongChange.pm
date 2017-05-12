package Xmms::SongChange;

use 5.005;
use strict;
use DynaLoader ();

{
    no strict;
    @ISA = qw(DynaLoader);
    $VERSION = '0.01';
    __PACKAGE__->bootstrap($VERSION);
}

1;
__END__

=head1 NAME

Xmms::SongChange - Take actions based on song track/time change

=head1 SYNOPSIS

 xmms> change on

=head1 DESCRIPTION

This module creates a thread to poll I<xmms> for song track and time
changes.  The thread is started via the I<Xmms::shell> command
I<change on> and stopped via I<change off>.

=head1 CAVEATS

This module is considered very B<EXPERIMENTAL>.  During testing, it
caused I<xmms> to freeze sometimes.  However, this freezing occured
with I<xmms> version B<0.9>, I have seen no freezing with version
B<0.9.1>.

The module decides if a song has changed based on track number or
track length.  So, when only one track is in the playlist, this logic
is broken.

Since the thread is constantly polling I<xmms> via the remote
protocol, xmms is consuming more cpu time than normal.

=head1 FEATURES

Current features include:

=over 4

=item jtime

When I<Xmms::SongChange> is running, it will auto jump to the current 
track's I<jtime>, if any.

=item repeat

The I<Xmms::shell> I<repeat> command can be used with 2 additional
arguments, to repeat a track in the playlist I<n> number of times
before advancing.  Example:

 xmms> repeat 1 3

This command will cause track I<1> to be repeated I<3> times before
advancing.

=item crop

I<Xmms::SongChange> adds a new I<crop> command, which is similar in
concept to I<jtime>, but advances to the next track in the playlist
when the current track I<crop> time is reached.  Example:

 xmms> crop 2 4:30

This command will cause playlist advance when track I<2> reaches the
output time of I<4:30>.

With no arguments, the current output time is set as the I<crop> time
for the current track.  The I<M-c> key binding has the same effect.

=item clear

When the I<SongChange> thread is running, the I<Xmms::shell> I<clear>
command will also clear all I<SongChange> watch points.

=back

=head1 TIPS

The I<Xmms::shell> I<history> command can be used to run a "script".
For example, consider a file such as:

 change on
 clear
 add /usr/local/mp3/prodigy/live/speedway.mp3
 add /usr/local/mp3/prodigy/live/rock_n_roll_98.mp3
 jtime 1 1:19
 crop 1 2:17
 repeat 1 3
 jtime 2 1:00
 crop 2 4:20
 play

Which can be run in the shell like so:

 xmms> history < ~/mp3/example.sc

=head1 FUTURE

I plan to implement the following features in the future:

=over 4

=item fade

start to fade the volume at a given time.

=item splice

similar to using I<jtime> and I<crop>, but in the middle of a song.
of course, this can already be done by adding the same file to the
playlist multiple times and setting different I<jtime> and I<crop>
times for each.

=item ???

=back

=head1 AUTHOR

Doug MacEachern
