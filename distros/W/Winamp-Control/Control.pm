# Author: Murat Uenalan (muenalan@cpan.org)
#
# Copyright (c) 2002 Murat Uenalan. All rights reserved.
#
# Note: This program is free software; you can redistribute
#
# it and/or modify it under the same terms as Perl itself.

use 5.006; use warnings; use strict;

package Winamp::Control;

use Class::Maker;

use LWP::Simple;

use URI;

use vars qw($AUTOLOAD $VERSION);

our $VERSION = '0.2.1';

Class::Maker::class
{
	public =>
	{
		string => [qw(host passwd)],

		integer => [qw(port)],
	},
};

sub _preinit
{
	my $this = shift;

		$this->host( 'localhost' );

		$this->port( 4800 );
}

sub AUTOLOAD : method
{
	my $this = shift || return undef;

	my @args;
	
	@args = ( p => $this->passwd ) if defined $this->passwd;
	
	push @args, @_;

	my $func = $AUTOLOAD;

		$func =~ s/.*:://;

		return if $func eq 'DESTROY';

	my $uri = URI->new;

		$uri->scheme( 'http' );

		$uri->host( $this->host );

	    $uri->port( $this->port );

		$uri->path( $func );
		
	    $uri->query_form( @args );

    	#$uri->userinfo( 'user:pw' );

		warn $uri->as_string, "\n" if $main::opts{debug};

	my $result = get( $uri->as_string );

		return undef unless $result;

	my @array = ();

		@array = split( '<br>', $result );

return wantarray ? @array : $array[0];
}

1;

__END__

=head1 NAME

Winamp::Control - control winamp (over the network)

=head1 SYNOPSIS

	use Winamp::Control;

	use IO::Extended qw(printfln);

		my $winamp = Winamp::Control->new( host => $opts{host}, port => $opts{port} );

		if( my $ver = $winamp->getversion )
		{
			printfln 'Connected to Winamp (Ver: %s)', $ver;

			printfln 'Currently playing: %s ', $winamp->getcurrenttitle() if $winamp->isplaying();

			println "Current playlist:\n\t", join "\n\t", $winamp->getplaylisttitle();
		}

=head1 DESCRIPTION

B<Winamp::Control> is a perl module for controlling Winamp (www.winamp.com) over a network or
local. It requires the httpQ winamp-plugin written by Kosta Arvanitis (see prerequisites)
installed on the computer playing the music (It is called "server" and will receive the commands).
Perl clients doesn't need it, because the clients are communicating via http (and they are not restricted
to any operating-system).

=head2 METHODS (modified after the httpQ documentation)

=head3 Constructor parameters (new)

=over 4

=item host (default: C<127.0.0.1>)

The host address where the httpQ plugin and C<Winamp> is running.

=item port (default: C<4800>)

The httpQ plugin port.

=item passwd (default: none)

A plain text password to httpQ (required if set via the httpQ preferences).

=back

[Note] The parameters have also instance methods counterparts. So you may call
them after construction like:

 $winamp->host( $host );
 $winamp->port( $port );
 $winamp->passwd( $passwd );

=head3 prev, play, pause, stop, next

  action: Like clicking on it.
  argument: none.
  return: 1 on success, 0 otherwise.

  example: $winamp-><command>

=head3 getversion

  action: Get the current version of your winamp player.
  argument: none.
  return: Version of winamp, or 0 on error.

  example: $winamp->getversion

=head3 delete

  action: Clears the contents of the play list.
  argument: none.
  return: 1 on success, 0 otherwise.

  example: $winamp->delete

=head3 isplaying

  action: Get the playing status of winamp player.
  argument: none.
  return: 1 = playing, 0 = not playing, 3 = paused

  example: $winamp->isplaying

=head3 getoutputtime

  action: Returns the position in milliseconds of the current song, or the song length, in seconds.
  argument: 0 Position (in ms) of current song, 1 Length (in sec) of current song
  return: -1 if not playing, 0 on error.

  example: $winamp->getoutputtime( a => 1 );

=head3 jumptotime (requires Winamp 1.60+)

  action: Sets the position in milliseconds of the current song (approximately) to 'argument'.
  argument: Position in milliseconds to jump to.
  return: 1 on success,0 otherwise

  example: $winamp->jumptotime( a => 1000 ); #jump to 1 second

=head3 setplaylistpos (requires Winamp 2.0+)

  action: Sets the playlsit position to 'argument'.
  argument: Position to set play list to.
  return: 1 on success,0 otherwise

  example: $winamp->setplaylistpos( a => 1 ); #set play list to position 1

=head3 getlistlength (requires Winamp 2.0+)

  action: get the length of the current playlist, in tracks.
  argument: none.
  return: The current track number or 0 on error.

  example: $winamp->getlistlength

=head3 getplaylisttitle (requires Winamp 2.04+)

  action: returns the title of the playlist entry at index 'argument'.
  note: if no argument is specified, returns a list of all the titles in the playlist seperated by '<br>'.
  argument: index in the list from which to retrieve title.
  note: the list is zero indexed so track 1 is 0.
  return: Title of track or 0 on error.

  example:

  	$winamp->getplaylisttitle( a => 1 ); #get title at list index 1

	or

	$winamp->getplaylisttitle; #get a list of titles

=head3 getplaylistfile (requires Winamp 2.04+)

  action: Returns the file name of the playlist entry at index 'argument'.
  note: If no argument is specified, returns a list of all the file names in the playlist seperated by '<br>'.
  argument: Index in the list from which to retrieve title.
  note: The list is zero indexed so track 1 is 0.
  return: Filename of track or 0 on error.

  example:

  	$winamp->getplaylistfile( a => 1 ); #get file name at list index 1

	or

	$winamp->getplaylistfile; #get a list of file names

=head3 getlistpos (requires Winamp 2.05+)

  action: Gets the current index of the play list.
  note: The list is zero indexed so track 1 is 0.
  argument: none.
  return: List position or 0 on error.

  example: $winamp->getlistpos;

=head3 chdir

  action: Change the working direcotry to argument.
  argument: The path to the new current working directory.
  return: 1 on success, 0 otherwise.

  example: $winamp->chdir( a => 'c:\mp3' );

=head3 playfile

  action: Appends a file to the playlist.The file must be in the current working directory or
          pass in the directory with the filename as the argument.
  argument: The file name to append to the playlist.
  return: 1 on success, 0 otherwise.

  example:

  	$winamp->playfile( a => 'music.mp3' );

	$winamp->playfile( a => 'c:\mp3\music.mp3' );

=head3 getinfo (requires Winamp 2.05+)

  action: Gets info about the current playing song. The value it returns depends on the value of 'argument'.
  argument: 0 Samplerate (i.e. 44100), 1 Bitrate (i.e. 128), 2 Channels (i.e. 2)

  return: Info or 0 on error.

  example: $winamp->getinfo( a => 0 );

=head3 fadeoutandstop

  action: Fades out current song and stops playing.
  argument: none.
  return: 0 on error, 1 otherwise

  example: $winamp->fadeoutandstop;

=head3 shuffle

  action: Toggle shuffle on and off.
  argument: 0 Turn shuffle off, 1 Turn shuffle on
  return: 1 if shuffle is on, 0 otherwise

  example: $winamp->shuffle( a => 0 );

=head3 shuffle_status

  action: Gets the status of shuffle button.
  argument: none.
  return: 1 if shuffle is on, 0 otherwise.

  example: $winamp->shuffle_status;

=head3 repeat

  action: Toggle repeat on and off.
  argument: 0 Turn shuffle off, 1 Turn shuffle on
  return: 1 if repeat is on, 0 otherwise.

  example: $winamp->repeat( a => 0 );

=head3 repeat_status

  action: Gets the status of the repeat button.
  argument: none.
  return: 1 if repeat is on, 0 otherwise

  example: $winamp->repeat_status;

=head3 volumeup

  action: Turns up the volume.
  argument: none.
  return: 1 on success, 0 otherwise

  example: $winamp->volumeup;

=head3 volumedown

  action: Turns down the volume.
  argument: none.
  return: 1 on success, 0 otherwise

  example: $winamp->volumedown;

=head3 setvolume

  action: Set the volume level.
  argument: 0-255 The volume level.
  return: 1 on success, 0 otherwise

  example: $winamp->setvolume( a => 100 );

=head3 geteqdata

  action: Gets the eq data.
  argument:
  		0-9 10 bands of EQ data
		10 Preamp value
		11 Equalizer enabled
		12 Equalizer autoload
  return:
  		0-9 0-63 (+20db - -20db)
		10 0-63 (+20db - -20db)
		11 Zero if disabled, nonzero if enabled.
		12 Zero if disabled, nonzero if enabled.

  example: $winamp->geteqdata( a => 8 );

=head3 seteqdata

  action: Sets the eq data at 'x' to 'y'.
  note: the argument format is ( a => 'x,y' )
		x is the band.
		y is the value.

  argument: 0-9,0-63 10 bands of EQ data (0-63)
		10,0-63 Preamp value (0-63)
		11,0-1 Equalizer enabled (0-1)
		12,0-1 Equalizer autoload (0-1)

  return: 1 on success,0 otherwise

  example: $winamp->seteqdata( a => '8,10' );

=head3 getid3tag

  action: Gets the ID3 tag info of a file.
  argument: none Gets info for current playing file, or <n> gets the info for the file indexed at 'n'.
  return: 0 on error, otherwise returns contents of ID3 tag formated:

	SongName<br>Artist<br>Album<br>Year<br>Genre<br>Comment

  example: $winamp->getid3tag( a => 3 );

=head3 getid3tag_album, getid3tag_artist, getid3tag_comment, getid3tag_genre, getid3tag_songname, getid3tag_year

  action: Gets a specific portion of the ID3 tag info from a file.
  argument: none Gets info for current playing file or <n> gets the info for the file indexed at 'n'.
  return: 0 on error, otherwise returns contents of specific portion of ID3 tag.

  example: $winamp->getid3tag_year( a => 3 );

=head3 validate_password

  action: Check a given string against the real password.
  argument: a string representing the password.
  return: 0 if incorrect, 1 otherwise.

  example: $winamp->validate_password( a=> 'password' );


=head3 flushplaylist

  action: Flushes the playlist cache buffer.
  argument: none.
  return: 0 on error,1 otherwise.

  example: $winamp->flushplaylist;


=head3 getcurrenttitle

  action: Returns the title of the current song from the winamp window name. Used when the playlist title is not enough.
  argument: none.
  return: 0 on error, song title otherwise.

  example: $winamp->getcurrenttitle;


=head3 updatecurrenttitle

  action: Updates the information about the current title.
  argument: none.
  return: 0 on error, 1 otherwise

  example: $winamp->updatecurrenttitle;

=head3 internet

  action: Checks for an internet connection.
  argument: none.
  return: 1 if internect connection exists,	0 otherwise

  example: $winamp->internet;

=head3 restart

  action: Restarts winamp.
  note: If the httpQ service is not set to start automatically httpQ will be shut down.
  argument: none.
  return: 0 on error, 1 otherwise.

  example: $winamp->restart;

=head3 getautoservice

  action: Returns the status of how the httpQ service starts.
  argument: none.
  return: 1 if the service is set to start automatically, 0 otherwise.

  example: $winamp->getautoservice;


=head3 setautoservice

  action: Sets the flag which controls if the httpQ service will start automatically or not.
  argument: 1 Sets the service to start automatically, 0 Sets the service to not start automatically.
  return: 1 if the service is set to start automatically, 0 otherwise.

  example: $winamp->setautoservice( a => 1 );

=head3 shoutcast_connect

  action: Attempts to start the shoutcast server.
  argument: none.
  return: 1 if successful, 0 otherwise.

  example: $winamp->shoutcast_connect;


=head3 shoutcast_status

  action: Attempts to retrieve status from shoutcast server.
  argument: none.
  return: status of shoutcast server if successful,	0 otherwise.

  example: $winamp->shoutcast_status;

=head2 EXPORT

None by default.

=head1 PREREQUISITES

You will need the winamp-plugin "httpQ" (Written by Kosta Arvanitis) on the machine playing
the music via winamp. You may find it via searching at the winamp headquarter:

	http://www.winamp.com

Or directly from the author:

	http://www.kostaa.com/winamp/

=head1 AUTHOR

Murat Ünalan, muenalan@cpan.org

=head1 COPYRIGHT

Copyright (c) 2002 Murat Uenalan. All rights reserved.
Note: This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1).

=cut
