package WWW::Grooveshark;

use 5.006;
use strict;
use warnings;

=head1 NAME

WWW::Grooveshark - Perl wrapper for the Grooveshark API

=head1 VERSION

This document describes C<WWW::Grooveshark> version 0.02 (July 22, 2009).

The latest version is hosted on Google Code as part of
L<http://elementsofpuzzle.googlecode.com/>.  Significant changes are also
contributed to CPAN: http://search.cpan.org/dist/WWW-Grooveshark/.

=cut

our $VERSION = '0.02';
$VERSION = eval $VERSION;

=head1 SYNOPSIS

Basic use is demonstrated here.  See L</API METHODS> for details.

  use WWW::Grooveshark;

  my $gs = WWW::Grooveshark->new(https => 1, agent => "my-nice-robot/0.1");

  my $r;
  $r = $gs->session_start(apiKey => $secret) or die $r->fault_line;
  
  for($gs->search_songs(query => "The Beatles", limit => 10)->songs) {
      printf("%s", $_->{songName});
      printf(" by %s", $_->{artistName});
      printf(" on %s\n", $_->{albumName});
      printf(" <%s>\n", $_->{liteUrl});
  }
  
  # session automatically ended by destructor

=head1 DESCRIPTION

Grooveshark is an internationally-available online music search, streaming,
and recommendation service.  C<WWW::Grooveshark> wraps this service's API in
an object-oriented Perl interface, allowing you to programmatically search
for songs, artists, albums, or playlists; browse popular music; get song
recommendations; manage playlists; and more.

=head1 API KEYS

...are needed to use the Grooveshark API.  E-mail
E<lt>developers@grooveshark.comE<gt> to get one.  They'll probably also link
you to the official API page, which seems to still be in beta.

=cut

use Carp;
use Digest::MD5 qw(md5_hex);
use JSON::Any;
use URI::Escape;

use WWW::Grooveshark::Response qw(:fault);

our @ISA = ();

=head1 CONSTRUCTOR

To use this module, you'll have to create a C<WWW::Grooveshark> instance.  The
default, argumentless constructor should be adequate, but customization is
possible through key-value options.

=over 4

=item WWW::Grooveshark->new( %OPTIONS )

Prepares a new C<WWW::Grooveshark> object with the specified options, which are
passed in as key-value pairs, as in a hash.  Accepted options are:

=over 4

=item I<https>

Whether or not to use HTTPS for API calls.  Defaults to false, i.e. just use
HTTP.

=item I<service>

The hostname to use for the Grooveshark API service.  Defaults to
"api.grooveshark.com" unless C<staging> is true, in which case it defaults to
"staging.api.grooveshark.com".

=item I<path>

Path (relative to the hostname) to request for API calls.  Defaults to "ws".

=item I<api_version>

Version of the Grooveshark API you plan on using.  Defaults to 1.0.

=item I<query_string>

The query string to include in API call requests.  May be blank.  Defaults to
"json" so that the full default API root URL becomes
E<lt>http://api.grooveshark.com/ws/1.0/?jsonE<gt>.

=item I<agent>

Value to use for the C<User-Agent> HTTP header.  Defaults to
"WWW::Grooveshark/### libwww-perl/###", where the "###" are substituted with
the appropriate versions.  This is provided for convenience: the user-agent
string can also be set in the C<useragent_args> (see below).  If it's set in
both places, this one takes precedence.

=item I<useragent_class>

Name of the L<LWP::UserAgent> compatible class to be used internally by the 
newly-created object.  Defaults to L<LWP::UserAgent>.

=item I<useragent_args>

Hashref of arguments to pass to the constructor of the aforementioned
C<useragent_class>.  Defaults to no arguments.

=back

Options not listed above are ignored.

=cut

sub new {
	my($pkg, %opts) = @_;

	# user-agent constructor args
	my $ua_args = $opts{useragent_args} || {};
	
	# user-agent string
	$ua_args->{agent} = $opts{agent} if defined $opts{agent};
	$ua_args->{agent} ||= __PACKAGE__  . "/$VERSION ";

	# prepare user-agent object
	my $ua_class = $opts{useragent_class} || 'LWP::UserAgent';
	eval "require $ua_class";
	croak $@ if $@;
	my $ua = $ua_class->new(%$ua_args);

	my $default_service = $opts{staging} ?
	                      'staging.api.grooveshark.com' :
		                  'api.grooveshark.com';

	return bless({
		_ua           => $ua,
		_service      => $opts{service}      || $default_service,
		_path         => $opts{path}         || 'ws',
		_api_version  => $opts{api_version}  || '1.0',
		_query_string => $opts{query_string} || 'json',
		_https        => $opts{https}        || 0,
		_session_id   => undef,
		_json         => new JSON::Any,
	}, $pkg);
}

=back

=head1 DESTRUCTOR

I like code that cleans up after itself.  If a program starts by creating a
session, it's only logical that it should finish by ending it.  But should it
be up to the programmer to manage when that happens?  Anyone can be forgetful.

Enter the destructor.  Continue explicitly cleaning up, but if you forget to
do so, the destructor has your back.  When a C<WWW::Grooveshark> object gets
garbage collected, it will destroy its session if any.

=cut

sub DESTROY {
	my $self = shift;
	$self->session_destroy if $self->sessionID;	
}

=head1 MANAGEMENT METHODS

The following methods do not issue any API calls but deal with management of
the C<WWW::Grooveshark> object itself.  Ideally, you won't have to touch these
methods too often.  If you find yourself being insufficiently lazy, let me
know how I can make this module smarter.

=over 4

=item $gs->sessionID( )

Returns the Grooveshark API session ID, or C<undef> if there is no active
session.

=back

=cut

sub sessionID {
	return shift->{_session_id};
}

=head1 API METHODS

The methods listed here directly wrap the methods of Groveshark's JSON-RPC
API.  As you may have noticed, there is a very complex mapping between the
API's official methods and those of this interface: replace the period ('.')
with an underscore ('_').  As with the constructor, pass arguments as
hash-like key-value pairs, so for example, to get the 11th through 20th most
popular songs, I would:

  my $response = $gs->popular_getSongs(limit => 10, page => 2);

All API methods return L<WWW::Grooveshark::Response> objects, even in case of
errors, but their boolean evaluation is L<overload>ed to give false for fault
responses.  Make a habit of checking that method calls were successful:

  die $response->fault_line unless $response;

Access result elements by using the key as the method name.  In list context,
dereferencing takes place automagically, saving you a few characters:

  my @songs = $response->songs;

But after this first "layer" you're stuck dealing with hashrefs, as in the
L</SYNOPSIS> (though perhaps this will change in the future if I'm up to it):

  for(@songs) {
      printf("%s", $_->{songName});
      printf(" by %s", $_->{artistName});
      printf(" on %s\n", $_->{albumName});
      printf(" <%s>\n", $_->{liteUrl});
  }

Check the official API documentation for valid keys. Alternatively, experiment!

  use Data::Dumper;
  print Dumper($response);

This module's interface aims to parallel the official API as much as possible.
Consequently, all methods take argument names identical to the official ones.
However, some methods are "overloaded."  For example,
C<session_createUserAuthToken> gives you the option of passing a plaintext
C<pass> rather than a C<hashpass>, handling C<hashpass> generation for you.

Some methods may also have side effects.  These are generally "harmless": for
example, successful C<session_create> and C<session_get> calls store the
returned session ID so that it can be passed in the header of subsequent API
calls.

Alternate method arguments and any side effects are listed where applicable.

=head2 ALBUM

=over 4

=item $gs->album_about( albumID => $ALBUM_ID )

Returns meta-information for the album with the specified $ALBUM_ID, such as
album name, artist ID, and artist name.

=cut

sub album_about {
	my($self, %args) = @_;
	my $ret = $self->_call('album.about', %args);
	return $ret;
}

=item $gs->album_getSongs( albumID => $ALBUM_ID [, limit => $LIMIT ] [, page => $PAGE ] )

Returns all the songs on the album with the specified $ALBUM_ID, as well as
song meta-information.

=cut

sub album_getSongs {
	my($self, %args) = @_;
	my $ret = $self->_call('album.getSongs', %args);
	return $ret;
}

=back

=head2 ARTIST

=over 4

=item $gs->artist_about( artistID => $ARTIST_ID )

Returns information for the artist with the specified $ARTIST_ID.

=cut

sub artist_about {
	my($self, %args) = @_;
	my $ret = $self->_call('artist.about', %args);
	return $ret;
}

=item $gs->artist_getAlbums( artistID => $ARTIST_ID [, limit => $LIMIT ] [, page => $PAGE ] )

Returns the albums of the artist with the specified $ARTIST_ID, as well as
album meta-information.

=cut

sub artist_getAlbums {
	my($self, %args) = @_;
	my $ret = $self->_call('artist.getAlbums', %args);
	return $ret;
}

=item $gs->artist_getSimilar( artistID => $ARTIST_ID [, limit => $LIMIT ] [, page => $PAGE ] )

Returns a list of artists similar to the one with the specified $ARTIST_ID.

=cut

sub artist_getSimilar {
	my($self, %args) = @_;
	my $ret = $self->_call('artist.getSimilar', %args);
	return $ret;
}

=item $gs->artist_getSongs( artistID => $ARTIST_ID [, limit => $LIMIT ] [, page => $PAGE ] )

Returns the songs on the albums of the artist with the specified $ARTIST_ID, as
well as song meta-information.

=cut

sub artist_getSongs {
	my($self, %args) = @_;
	my $ret = $self->_call('artist.getSongs', %args);
	return $ret;
}

=item $gs->artist_getTopRatedSongs( artistID => $ARTIST_ID [, limit => $LIMIT ] [, page => $PAGE ] )

Returns the top rated songs of the artist with the specified $ARTIST_ID, as
well as song meta-information.  Use at your own risk: the existence of this
method was not mentioned in the official API documentation at the time of
this writing; it was discovered through the sandbox tool.

=cut

sub artist_getTopRatedSongs {
	my($self, %args) = @_;
	my $ret = $self->_call('artist.getTopRatedSongs', %args);
	return $ret;
}

=back

=head2 AUTOPLAY

=over 4

=item $gs->autoplay_frown( autoplaySongID => $AUTOPLAY_SONG_ID )

"Frowns" the song with the specified $AUTOPLAY_SONG_ID in the current Autoplay
session, indicating that the song is not liked and making the Autoplay session
suggest fewer songs like it.

=cut

sub autoplay_frown {
	my($self, %args) = @_;
	my $ret = $self->_call('autoplay.frown', %args);
	return $ret;
}

=item $gs->autoplay_getNextSong( )

Returns the next suggested song in the current Autoplay session, based on the
seed songs and any "smiles" or "frowns."

=cut

sub autoplay_getNextSong {
	my($self, %args) = @_;
	my $ret = $self->_call('autoplay.getNextSong', %args);
	return $ret;
}

=item $gs->autoplay_smile( autoplaySongID => $AUTOPLAY_SONG_ID )

"Smiles" the song with the specified $AUTOPLAY_SONG_ID in the current Autoplay
session, indicating that the song is liked and making the Autoplay session
suggest more songs like it.

=cut

sub autoplay_smile {
	my($self, %args) = @_;
	my $ret = $self->_call('autoplay.smile', %args);
	return $ret;
}

=item $gs->autoplay_start( songIDs => \@SONG_IDS )

Starts an Autoplay session seeded with the specified song IDs and returns the
first song suggestion.

=cut

sub autoplay_start {
	my($self, %args) = @_;
	my $ret = $self->_call('autoplay.start', %args);
	return $ret;
}

=item $gs->autoplay_stop( )

Ends the active Autoplay session.

=cut

sub autoplay_stop {
	my($self, %args) = @_;
	my $ret = $self->_call('autoplay.stop', %args);
	return $ret;
}

=back

=head2 PLAYLIST

=over 4

=item $gs->playlist_about( playlistID => $PLAYLIST_ID )

Returns information for the playlist with the specified $PLAYLIST_ID, such as
its name, description, song count, creation date, etc.

=cut

sub playlist_about {
	my($self, %args) = @_;
	my $ret = $self->_call('playlist.about', %args);
	return $ret;
}

=item $gs->playlist_addSong( playlistID => $PLAYLIST_ID , songID => $SONG_ID [, position => $POSITION ] )

Adds the song with the specified $SONG_ID to the playlist with the specified
$PLAYLIST_ID at $POSITION (or at the end, if $POSITION is omitted).  Valid
positions start from 1: a value of zero is equivalent to not specifying any.
To succeed, this method requires being authenticated as the playlist's
creator.

=cut

sub playlist_addSong {
	my($self, %args) = @_;
	my $ret = $self->_call('playlist.addSong', %args);
	return $ret;
}

=item $gs->playlist_create( name => $NAME, about => $DESCRIPTION )

Creates a playlist with the specified $NAME and $DESCRIPTION and returns the
playlist ID.  Requires user authentication.

=cut

sub playlist_create {
	my($self, %args) = @_;
	my $ret = $self->_call('playlist.create', %args);
	return $ret;
}

=item $gs->playlist_delete( playlistID => $PLAYLIST_ID )

Deletes the playlist with the specified $PLAYLIST_ID.  Requires being
authenticated as the playlist's creator.

=cut

sub playlist_delete {
	my($self, %args) = @_;
	my $ret = $self->_call('playlist.delete', %args);
	return $ret;
}

=item $gs->playlist_getSongs( playlistID => $PLAYLIST_ID [, limit => $LIMIT ] [, page => $PAGE ] )

Returns the songs on the playlist with the specified $PLAYLIST_ID, as well as
song meta-information.

=cut

sub playlist_getSongs {
	my($self, %args) = @_;
	my $ret = $self->_call('playlist.getSongs', %args);
	return $ret;
}

=item $gs->playlist_moveSong( playlistID => $PLAYLIST_ID , position => $POSITION , newPosition => $NEW_POSITION )

Moves the song at $POSITION in the playlist with the specified $PLAYLIST_ID to
$NEW_POSITION.  Valid positions start from 1.  A $NEW_POSITION of zero moves
the song to the end of the playlist.  To succeed, this method requires being
authenticated as the playlist's creator.

=cut

sub playlist_moveSong {
	my($self, %args) = @_;
	my $ret = $self->_call('playlist.moveSong', %args);
	return $ret;
}

=item $gs->playlist_removeSong( playlistID => $PLAYLIST_ID , position => $POSITION )

Removes the song at $POSITION from the playlist with the specified
$PLAYLIST_ID.  Valid positions start from 1.  To succeed, this method requires
being authenticated as the playlist's creator.

=cut

sub playlist_removeSong {
	my($self, %args) = @_;
	my $ret = $self->_call('playlist.removeSong', %args);
	return $ret;
}

=item $gs->playlist_rename( playlistID => $PLAYLIST_ID , name => $NAME )

Renames the playlist with the specified $PLAYLIST_ID to $NAME.  Requires being
authenticated as the playlist's creator.

=cut

sub playlist_rename {
	my($self, %args) = @_;
	my $ret = $self->_call('playlist.rename', %args);
	return $ret;
}

=item $gs->playlist_replace( playlistID => $PLAYLIST_ID , songIDs = \@SONG_IDS )

Replaces the contents of the playlist with the specified $PLAYLIST_ID with the
songs corresponding to the given @SONG_IDS, in the specified order. To succeed,
this method requires being authenticated as the playlist's creator.  (But at
the time of this writing, this didn't seem to work as expected, instead
returning an internal server error message.)

=cut

sub playlist_replace {
	my($self, %args) = @_;
	my $ret = $self->_call('playlist.replace', %args);
	return $ret;
}

=back

=head2 POPULAR

=over 4

=item $gs->popular_getAlbums( [ limit => $LIMIT ] [, page => $PAGE ] )

Gets a list of popular albums (and meta-information) from Grooveshark's
billboard.

=cut

sub popular_getAlbums {
	my($self, %args) = @_;
	my $ret = $self->_call('popular.getAlbums', %args);
	return $ret;
}

=item $gs->popular_getArtists( [ limit => $LIMIT ] [, page => $PAGE ] )

Gets a list of popular artists from Grooveshark's billboard.

=cut

sub popular_getArtists {
	my($self, %args) = @_;
	my $ret = $self->_call('popular.getArtists', %args);
	return $ret;
}

=item $gs->popular_getSongs( [ limit => $LIMIT ] [, page => $PAGE ] )

Gets a list of popular songs (and meta-information) from Grooveshark's
billboard.

=cut

sub popular_getSongs {
	my($self, %args) = @_;
	my $ret = $self->_call('popular.getSongs', %args);
	return $ret;
}

=back

=head2 SEARCH

=over 4

=item $gs->search_albums( query => $QUERY [, limit => $LIMIT ] [, page => $PAGE ] )

Searches for albums with names that match $QUERY.

=cut

sub search_albums {
	my($self, %args) = @_;
	my $ret = $self->_call('search.albums', %args);
	return $ret;
}

=item $gs->search_artists( query => $QUERY [, limit => $LIMIT ] [, page => $PAGE ] )

Searches for artists with names that match $QUERY.

=cut

sub search_artists {
	my($self, %args) = @_;
	my $ret = $self->_call('search.artists', %args);
	return $ret;
}

=item $gs->search_playlists( query => $QUERY [, limit => $LIMIT ] [, page => $PAGE ] )

Searches for playlists that match $QUERY by name or by meta-information
of composing songs.

=cut

sub search_playlists {
	my($self, %args) = @_;
	my $ret = $self->_call('search.playlists', %args);
	return $ret;
}

=item $gs->search_songs( query => $QUERY [, limit => $LIMIT ] [, page => $PAGE ] )

Searches for songs that match $QUERY by name or meta-information.

=cut

sub search_songs {
	my($self, %args) = @_;
	my $ret = $self->_call('search.songs', %args);
	return $ret;
}

=back

=head2 SERVICE

=over 4

=item $gs->service_getMethods( )

Gets a list of the methods supported by the service, as well as the names of
their parameters.  Calling this method doesn't require a session.

=cut

sub service_getMethods {
	my($self, %args) = @_;
	my $ret = $self->_call('service.getMethods', %args);
	return $ret;
}

=item $gs->service_getVersion( )

Gets the version of the API supported by the service.  Calling this method
doesn't require a session.

=cut

sub service_getVersion {
	my($self, %args) = @_;
	my $ret = $self->_call('service.getVersion', %args);
	return $ret;
}

=item $gs->service_ping( )

Checks that the service is alive.  Calling this method doesn't require a
session.  Useful for testing (and for getting a "Hello, world" greeting in
some language).

=cut

sub service_ping {
	my($self, %args) = @_;
	my $ret = $self->_call('service.ping', %args);
	return $ret;
}

=back

=head2 SESSION

=over 4

=item $gs->session_createUserAuthToken( username => $USERNAME , pass => $PASS | hashpass => $HASHPASS )

Creates an authentication token for the specified $USERNAME.  Authentication
requires a $HASHPASS, which is a hexadecimal MD5 hash of the concatenation of
$USERNAME and a hexadecimal MD5 hash of $PASS.  If you're storing the password 
as plaintext, don't bother generating the $HASHPASS yourself: just omit the
$HASHPASS and give C<pass =E<gt> $PASS> to this method.  If you specify both a
$HASHPASS and a $PASS, the $HASHPASS will take precedence (but don't try it).
Regardless, the $PASS will be removed from the arguments that are passed during
the API call.

=cut

sub session_createUserAuthToken {
	my($self, %args) = @_;
	
	# make hashpass, unless it already exists
	if(exists($args{hashpass})) {
		delete $args{pass};
	}
	else {
		if(exists($args{username}) && exists($args{pass})) {
			$args{hashpass} = md5_hex($args{username}, md5_hex($args{pass}));
		}
		else {
			carp 'Need username and pass to create authentication token';
		}
		delete $args{pass};
	}
	
	my $ret = $self->_call('session.createUserAuthToken', %args);		
	return $ret;
}

=item $gs->session_destroy( )

Destroys the currently active session.  As a side effect, removes the stored
session ID so that subsequent C<sessionID> calls on this C<WWW::Grooveshark>
object will return C<undef>.

=cut

sub session_destroy {
	my($self, %args) = @_;
	my $ret = $self->_call('session.destroy', %args);
	
	# kill the stored session ID if destroying was successful
	$self->{_session_id} = undef if $ret;
		
	return $ret;
}

=item $gs->session_destroyAuthToken( token => $TOKEN )

Destroys an auth token so that subsequent attempts to use it to login will
fail.

=cut

sub session_destroyAuthToken {
	my($self, %args) = @_;
	my $ret = $self->_call('session.destroyAuthToken', %args);		
	return $ret;
}

=item $gs->session_get( )

Gets the session ID of the currently active session.  Presumably this updates
every once in a while because there wouldn't be much use in this method
otherwise: an active session is required to call it, and returning the same
session ID would be a waste of an API call...  Assuming this does update,
calling this method has the side effect of updating the session ID of this
C<WWW::Grooveshark> object.

=cut

sub session_get {
	my($self, %args) = @_;
	my $ret = $self->_call('session.get', %args);
	
	# save the session ID given in the response
	$self->{_session_id} = $ret->sessionID if $ret;
	
	return $ret;
}

=item $gs->session_getUserID( )

Gets the user ID of the currently logged-in user.

=cut

sub session_getUserID {
	my($self, %args) = @_;
	my $ret = $self->_call('session.getUserID', %args);		
	return $ret;
}

=item $gs->session_loginViaAuthToken( token => $TOKEN )

Logs in using a $TOKEN created using C<session_createUserAuthToken>.

=cut

sub session_loginViaAuthToken {
	my($self, %args) = @_;
	my $ret = $self->_call('session.loginViaAuthToken', %args);		
	return $ret;
}

=item $gs->session_logout( )

Logs out the logged-in user.

=cut

sub session_logout {
	my($self, %args) = @_;
	my $ret = $self->_call('session.logout', %args);		
	return $ret;
}

=item $gs->session_start( apiKey => $API_KEY [, mobileID => $MOBILE_ID ] )

Starts a session using the specified $API_KEY.  This method must be called
before using (nearly) all of the other methods.  The returned session ID will
be stored in this C<WWW::Grooveshark> object, accessible via calls to
C<sessionID>, and automatically placed in the header of subsequent API calls.
$MOBILE_ID isn't mentioned in the official documentation and appears only in
the sandbox tool.

=cut

sub session_start {
	my($self, %args) = @_;
	
	# remove a prior session ID, but store this value
	my $old_session_id = $self->{_session_id};
	$self->{_session_id} = undef;
	
	my $ret = $self->_call('session.start', %args);
	
	if($ret) {
		# save the session ID given in the response
		$self->{_session_id} = $ret->sessionID;
	}
	else {
		# restore old session ID
		$self->{_session_id} = $old_session_id;
	}
	
	return $ret;
}

=back

=head2 SONG

=over 4

=item $gs->song_about( songID => $SONG_ID )

Returns meta-information for the song with the specified $SONG_ID, such as
song name, album name, album ID, artist name, artist ID, etc.

=cut

sub song_about {
	my($self, %args) = @_;
	my $ret = $self->_call('song.about', %args);
	return $ret;
}

=item $gs->song_favorite( songID => $SONG_ID )

Marks the song with the specified $SONG_ID as a favorite.  Requires user
authentication.

=cut

sub song_favorite {
	my($self, %args) = @_;
	my $ret = $self->_call('song.favorite', %args);
	return $ret;
}

=item $gs->song_getSimilar( songID => $SONG_ID [, limit => $LIMIT ] [, page => $PAGE ] )

Gets a list of songs similar to the one with the specified $SONG_ID, as well as
their meta-information.

=cut

sub song_getSimilar {
	my($self, %args) = @_;
	my $ret = $self->_call('song.getSimilar', %args);
	return $ret;
}

=item $gs->song_getStreamKey( songID => $SONG_ID )

Gets a streamKey for the song with the specified $SONG_ID (needed to authorize
playback for some Grooveshark embeddable players).

=cut

sub song_getStreamKey {
	my($self, %args) = @_;
	my $ret = $self->_call('song.getStreamKey', %args);
	return $ret;
}

=item $gs->song_getStreamUrl( songID => $SONG_ID )

Gets an URL for streaming playback of the song with the specified $SONG_ID.
According to the response header, this method is deprecated and 
C<song_getStreamUrlEx> should be used instead.

=cut

sub song_getStreamUrl {
	my($self, %args) = @_;
	my $ret = $self->_call('song.getStreamUrl', %args);
	return $ret;
}

=item $gs->song_getStreamUrlEx( songID => $SONG_ID [, lowBitrate => $LOW_BITRATE ] )

The supposedly preferred alternative to C<song_getStreamUrlEx>.  Use at your
own risk: the existence of this method was not mentioned in the official API
documentation at the time of this writing; it was discovered through the
sandbox tool as well as the deprecation message in the header of
C<song_getStreamUrl> responses.

=cut

sub song_getStreamUrlEx {
	my($self, %args) = @_;
	my $ret = $self->_call('song.getStreamUrlEx', %args);
	return $ret;
}

=item $gs->song_getWidgetEmbedCode( songID => $SONG_ID [, theme => $THEME ] [, pxHeight => $HEIGHT ] [, pxWidth => $WIDTH ] [, ap => $AP ] )

Gets HTML code for embedding the song with the specified $SONG_ID.  The code
may be customized by specifying a pixel $HEIGHT and $WIDTH as well as a theme
for the widget, which must be in C<qw(metal grass wood water)>.  The $AP is
optional and appears only in the sandbox tool and not the official
documentation: its meaning is unknown.

=cut

sub song_getWidgetEmbedCode {
	my($self, %args) = @_;
	my $ret = $self->_call('song.getWidgetEmbedCode', %args);
	return $ret;
}

=item $gs->song_getWidgetEmbedCodeFbml( songID => $SONG_ID [, theme => $THEME ] [, pxHeight => $HEIGHT ] [, pxWidth => $WIDTH ] [, ap => $AP ]

This is in fact not an API method but a wrapper for C<song_getWidgetEmbedCode>
that modifies the returned HTML code to FBML so it can be used in Facebook
applications.  This method is experimental: use it at your own risk.

=cut

sub song_getWidgetEmbedCodeFbml {
	my $ret = shift->song_getWidgetEmbedCode(@_);

	if($ret) {
		my $code = $ret->{result}->{embed};
		$code =~ /<embed (.*?)>\s*<\/embed>/;		
		$code = "<fb:swf swf$1 />";
		$ret->{result}->{embed} = $code;	
	}

	return $ret;
}

=item $gs->song_unfavorite( songID => $SONG_ID )

Removes the song with the specified $SONG_ID from the logged-in user's list
of favorites.

=cut

sub song_unfavorite {
	my($self, %args) = @_;
	my $ret = $self->_call('song.unfavorite', %args);
	return $ret;
}

=back

=head2 TINYSONG

=over 4

=item $gs->tinysong_create( songID => $SONG_ID | ( query => $QUERY [, useFirstResult => $USE_FIRST_RESULT ] ) )

Creates a tiny URL that links to the song with the specified $SONG_ID.  The
method seems to also allow searching (if a $QUERY and whether to
$USE_FIRST_RESULT are specified), but this form appears to be buggy at the
time of this writing, and is discouraged.

=cut

sub tinysong_create {
	my($self, %args) = @_;
	my $ret = $self->_call('tinysong.create', %args);
	return $ret;
}

=item $gs->tinysong_getExpandedUrl( tinySongUrl => $TINYSONG_URL )

Expands a TinySong URL into the full URL to which it redirects.

=cut

sub tinysong_getExpandedUrl {
	my($self, %args) = @_;
	my $ret = $self->_call('tinysong.getExpandedUrl', %args);
	return $ret;
}

=back

=head2 USER

=over 4

=item $gs->user_about( $user_id => $USER_ID )

Returns information about the user with the specified $USER_ID, such as
username, date joined, etc.

=cut

sub user_about {
	my($self, %args) = @_;
	my $ret = $self->_call('user.about', %args);
	return $ret;
}

=item $gs->user_getFavoriteSongs( $user_id => $USER_ID [, limit => $LIMIT ] [, page => $PAGE ] )

Returns songs (and meta-information) from the favorite list of the user with
the specified $USER_ID.

=cut

sub user_getFavoriteSongs {
	my($self, %args) = @_;
	my $ret = $self->_call('user.getFavoriteSongs', %args);
	return $ret;
}

=item $gs->user_getPlaylists( $user_id => $USER_ID [, limit => $LIMIT ] [, page => $PAGE ] )

Gets the playlists created by the user with the specified $USER_ID.

=cut

sub user_getPlaylists {
	my($self, %args) = @_;
	my $ret = $self->_call('user.getPlaylists', %args);
	return $ret;
}

=back

=cut

################################################################################

sub _call {
	my($self, $method, %param) = @_;

#	print STDERR "Called $method\n";

	my $req = {
		header     => {sessionID => $self->sessionID},
		method     => $method,
		parameters => \%param,
	};

#	use Data::Dumper; print STDERR Dumper($req);

	my $json = $self->{_json}->encode($req);
	my $url = sprintf('%s://%s/%s/%s/', ($self->{_https} ? 'https' : 'http'),
		map($self->{$_}, qw(_service _path _api_version)));
	if(my $q = $self->{_query_string}) {
		$q = uri_escape($q);
		$url .= '?' . $q;
	}
	my $response = $self->{_ua}->post($url,
		'Content-Type' => 'text/json',
		'Content'      => $json,
	);

   	my $ret;
	if($response->is_success) {
		my $content = $response->decoded_content || $response->content;
		$ret = $self->{_json}->decode($content);
	}
	else {
    	$ret = {
    		header => {sessionID => $self->sessionID},
    		fault  => {
    			code    => INTERNAL_FAULT,
	    		message => $response->status_line,
	    	},
    	};
	}

#	use Data::Dumper; print STDERR Dumper($ret);

	return WWW::Grooveshark::Response->new($ret);
}

1;

__END__

=head1 SEE ALSO

L<http://www.grooveshark.com/>, L<WWW::Grooveshark::Response>, L<WWW::TinySong>

=head1 BUGS

Please report them!  The preferred way to submit a bug report for this module
is through CPAN's bug tracker:
http://rt.cpan.org/Public/Dist/Display.html?Name=WWW-Grooveshark.  You may
also create an issue at http://elementsofpuzzle.googlecode.com/ or drop me an
e-mail.

=head1 AUTHOR

Miorel-Lucian Palii E<lt>mlpalii@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Miorel-Lucian Palii

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.  See
L<perlartistic>.

=cut
