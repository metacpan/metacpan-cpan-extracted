use Test::More tests => 77;

my $config_file;
BEGIN {
	$config_file = 'test_config';
	diag(<<"NOTE");


NOTE: This test takes additional configuration to run all tests.
See $config_file.example for details.


NOTE
	use_ok('WWW::Grooveshark');
	use_ok('WWW::Grooveshark::Response', qw(:fault));
};

cmp_ok(INTERNAL_FAULT, '==', WWW::Grooveshark::Response::INTERNAL_FAULT,
	'constant importing succeeded');

# configurable values
our $api_key;
our $user;
our $pass;
our $staging = 1;

# grab the config file
require $config_file if -e $config_file;

my $gs = new_ok('WWW::Grooveshark' => [staging => $staging]);

SKIP: {
    my $conn_ok;
    eval 'use Net::Config qw(%NetConfig); $conn_ok = $NetConfig{test_hosts}';
    skip 'Net::Config needed for network-related tests', 73 if $@;
    skip 'No network connection', 73 unless $conn_ok;

	my $r;

	# test service_getMethods()
	ok($gs->service_getMethods->methods,
		'service_getMethods() returns expected structure');	

	# test service_getVersion()
	ok($r = $gs->service_getVersion, 'service_getVersion() succeeds');	
	cmp_ok($r->version, '>=', 1,
		'service_getVersion() returns expected value');

	# test sessionless service_ping()
	ok($gs->service_ping, 'sessionless service_ping() succeeds');

	diag_skip('API key not defined, skipping remaining tests', 69)
		unless defined $api_key;

	# test session_start()
	ok($r = $gs->session_start(apiKey => $api_key),
		'session_start() succeeds');

	diag_skip('Problem starting session: ' . $r->fault_line, 68)
		unless $r;

	# test service_ping()
	ok($gs->service_ping, 'service_ping() succeeds');
	
	# test session_id()
	ok($gs->sessionID, 'sessionID() returns true value');
	cmp_ok($r->sessionID, 'eq', $gs->sessionID,
		'sessionID() returns expected value');
	
	# test session_get()
	ok($r = $gs->session_get, 'session_get() succeeds');
	cmp_ok($r->sessionID, 'eq', $gs->sessionID,
		'session_get() returns expected value');
	
	my %search = (query => 'The Beatles', limit => 1);
	my($album_id, $artist_id, $playlist_id, $song_id);
	my($ap_song_id, @song_ids);
	my($lite_url, $tinysong_url);

	# test search_albums()
	ok($gs->search_albums(%search)->albums,
		'search_albums() returns expected structure');

	# test popular_getAlbums()
	$r = $gs->popular_getAlbums(limit => 1);
	ok($r->albums, 'popular_getAlbums() returns expected structure');
	$album_id = ($r->albums)[0]->{albumID};

	# test album_about()
	ok($r = $gs->album_about(albumID => $album_id),
		'album_about() succeeds');
	cmp_ok($r->albumID, '==', $album_id,
		'album_about() returns expected value');

	# test album_getSongs()
	ok($r = $gs->album_getSongs(albumID => $album_id, limit => 1),
		'album_getSongs() succeeds');
	cmp_ok(($r->songs)[0]->{albumID}, '==', $album_id,
		'album_getSongs() returns expected value');

	# test search_artists()
	ok($gs->search_artists(%search)->artists,
		'search_artists() returns expected structure');

	# test popular_getArtists()
	$r = $gs->popular_getArtists(limit => 1);
	ok($r->artists, 'popular_getArtists() returns expected structure');
	$artist_id = ($r->artists)[0]->{artistID};

	# test artist_about()
	ok($r = $gs->artist_about(artistID => $artist_id),
		'artist_about() succeeds');
	cmp_ok($r->artistID, '==', $artist_id,
		'artist_about() returns expected value');

	# test artist_getAlbums()
	ok($r = $gs->artist_getAlbums(artistID => $artist_id, limit => 1),
		'artist_getAlbums() succeeds');
	cmp_ok(($r->albums)[0]->{artistID}, '==', $artist_id,
		'artist_getAlbums() returns expected value');

	# test artist_getSongs()
	ok($r = $gs->artist_getSongs(artistID => $artist_id, limit => 1),
		'artist_getSongs() succeeds');
	cmp_ok(($r->songs)[0]->{artistID}, '==', $artist_id,
		'artist_getSongs() returns expected value');

	# test artist_getSimilar()
	ok($gs->artist_getSimilar(artistID => $artist_id, limit => 1)->artists,
		'artist_getSimilar() returns expected structure');

	# test artist_getTopRatedSongs()
	ok($r = $gs->artist_getTopRatedSongs(artistID => $artist_id,
		limit => 1), 'artist_getTopRatedSongs() succeeds');
	cmp_ok(($r->songs)[0]->{artistID}, '==', $artist_id,
		'artist_getTopRatedSongs() returns expected value');

	# test search_playlists()
	$r = $gs->search_playlists(%search);
	ok($r->playlists, 'search_playlists() returns expected structure');
	$playlist_id = ($r->playlists)[0]->{playlistID};

	# test playlist_about()
	ok($r = $gs->playlist_about(playlistID => $playlist_id),
		'playlist_about() succeeds');
	cmp_ok($r->playlistID, '==', $playlist_id,
		'playlist_about() returns expected value');

	# test playlist_getSongs()
	ok($gs->playlist_getSongs(playlistID => $playlist_id, limit => 1)
		->songs, 'playlist_getSongs() returns expected structure');	

	# test search_songs()
	ok($gs->search_songs(%search)->songs,
		'search_songs() returns expected structure');

	# test popular_getSongs()
	$r = $gs->popular_getSongs(limit => 10);
	ok($r->songs, 'popular_getSongs() returns expected structure');
	@song_ids = map {$_->{songID}} $r->songs;
	$song_id = ($r->songs)[0]->{songID};

	# test song_about()
	ok($r = $gs->song_about(songID => $song_id), 'song_about() succeeds');
	cmp_ok($r->song->{songID}, '==', $song_id,
		'song_about() returns expected value');
	$lite_url = $r->song->{liteUrl};

	# test song_getSimilar()
	ok($gs->song_getSimilar(songID => $song_id, limit => 1)->songs,
		'song_getSimilar() returns expected structure');

	# test song_getStreamKey()
	ok((($r = $gs->song_getStreamKey(songID => $song_id)) && $r->streamKey)
		|| $r->fault_code == ACCESS_RIGHTS_FAULT,
		'song_getStreamKey() works as expected');

	# test song_getStreamUrl()
	ok((($r = $gs->song_getStreamUrl(songID => $song_id)) && $r->url)
		|| $r->fault_code == ACCESS_RIGHTS_FAULT,
		'song_getStreamUrl() works as expected');

	# test song_getStreamUrlEx()
	ok((($r = $gs->song_getStreamUrlEx(songID => $song_id)) && $r->url)
		|| $r->fault_code == ACCESS_RIGHTS_FAULT,
		'song_getStreamUrlEx() works as expected');
	
	# test song_getWidgetEmbedCode()
	ok($gs->song_getWidgetEmbedCode(songID => $song_id)->embed,
		'song_getWidgetEmbedCode() returns expected structure');

	# test song_getWidgetEmbedCodeFbml()
	like($gs->song_getWidgetEmbedCodeFbml(songID => $song_id)->embed,
		qr/^<fb/i, 'song_getWidgetEmbedCodeFbml() returns expected structure');

	# test autoplay_start()
	ok($ap_song_id = $gs->autoplay_start(songIDs => \@song_ids)->song
		->{autoplaySongID}, 'autoplay_start() returns expected structure');
	
	# test autoplay_smile()
	ok($gs->autoplay_smile(autoplaySongID => $ap_song_id),
		'autoplay_smile() succeeds');

	# test autoplay_getNextSong()
	ok($ap_song_id = $gs->autoplay_getNextSong->song->{autoplaySongID},
		'autoplay_getNextSong() returns expected structure');
	
	# test autoplay_frown()
	ok($gs->autoplay_frown(autoplaySongID => $ap_song_id),
		'autoplay_frown() succeeds');
	
	# test autoplay_stop()
	ok($gs->autoplay_stop, 'autoplay_stop() succeeds');

	# test tinysong_create()
	ok($r = $gs->tinysong_create(songID => $song_id),
		'tinysong_create() succeeds');
	ok($tinysong_url = $r->tinySongUrl,
		'tinysong_create() returns expected structure');
	
	# test tinysong_getExpandedUrl()
	ok($r = $gs->tinysong_getExpandedUrl(tinySongUrl => $tinysong_url),
		'tinysong_getExpandedUrl() succeeds');
	cmp_ok($r->tinySongUrl, 'eq', $lite_url,
		'tinysong_getExpandedUrl() returns expected value');

	SKIP: {
		diag_skip('Username or password not defined, ' .
			'skipping tests requiring login', 22)
			unless defined($user) && defined($pass);
		
		my($auth_token, $user_id);
		
		# test session_createUserAuthToken()
		ok($r = $gs->session_createUserAuthToken(username => $user, pass =>
			$pass), 'session_createUserAuthToken() succeeds');
		ok($auth_token = $r->token,
			'session_createUserAuthToken() returns expected structure');
		$user_id = $r->userID;

		# test session_loginViaAuthToken()
		ok($r = $gs->session_loginViaAuthToken(token => $auth_token),
			'session_loginViaAuthToken() succeeds');
		cmp_ok($user_id, '==', $r->userID,
			'session_loginViaAuthToken() returns expected value');

		# test session_getUserID()
		ok($r = $gs->session_getUserID, 'session_getUserID() succeeds');
		cmp_ok($user_id, '==', $r->result,
			'session_getUserID() returns expected value');

		# test user_about()
		ok($r = $gs->user_about(userID => $user_id), 'user_about() succeeds');
		cmp_ok($user_id, '==', $r->user->{userID},
			'user_about() returns expected value');

		# test user_getPlaylists()
		ok($gs->user_getPlaylists(userID => $user_id, limit => 1)->playlists,
			'user_getPlaylists() returns expected structure');

		if($gs->song_about(songID => $song_id)->song->{isFavorite}) {
			# test user_getFavoriteSongs()
			ok($r = $gs->user_getFavoriteSongs(userID => $user_id,
				limit => 1), 'user_getFavoriteSongs() succeeds');
			ok($r->songs->[0]->{isFavorite},
				'user_getFavoriteSongs() returns expected value');
		
			# test song_unfavorite()
			ok($gs->song_unfavorite(songID => $song_id),
				'song_unfavorite() succeeds');

			# test song_favorite()
			ok($gs->song_favorite(songID => $song_id),
				'song_favorite() succeeds');
		}
		else {
			# test song_favorite()
			ok($gs->song_favorite(songID => $song_id),
				'song_favorite() succeeds');

			# test user_getFavoriteSongs()
			ok($r = $gs->user_getFavoriteSongs(userID => $user_id,
				limit => 1), 'user_getFavoriteSongs() returns true value');
			ok($r->songs->[0]->{isFavorite},
				'user_getFavoriteSongs() returns expected value');

			# test song_unfavorite()
			ok($gs->song_unfavorite(songID => $song_id),
				'song_unfavorite() succeeds');			
		}

		# test playlist_create()
		ok($playlist_id = $gs->playlist_create(name => 'test')->playlistID,
			'playlist_create() returns expected structure');
		
		# test playlist_addSong()
		cmp_ok(scalar(@song_ids), '==', scalar(grep {$_}
			map {$gs->playlist_addSong(playlistID => $playlist_id,
			songID => $_)} @song_ids),
			'playlist_addSong() succeeds');

		# test playlist_removeSong()
		ok($gs->playlist_removeSong(playlistID => $playlist_id,
			position => scalar(@song_ids)),
			'playlist_removeSong() succeeds');

		# test playlist_moveSong()
		ok($gs->playlist_moveSong(playlistID => $playlist_id,
			position => 1, newPosition => 2),
			'playlist_moveSong() succeeds');

		TODO: {
			local $TODO = 'Thre may be a server-side error in ' .
				'playlist replacing through the API.';

			# test playlist_replace()
			ok($gs->playlist_replace(playlistID => $playlist_id,
				songIDs => \@song_ids),
				'playlist_replace() succeeds');
		}

		# test playlist_rename()
		ok($gs->playlist_rename(playlistID => $playlist_id, name =>
			'API testing playlist'), 'playlist_rename() succeeds');

		# test playlist_delete()
		ok($gs->playlist_delete(playlistID => $playlist_id),
			'playlist_delete() succeeds');

		# test session_logout()
		ok($gs->session_logout, 'session_logout() succeeds');

		# test session_destroyAuthToken()
		ok($gs->session_destroyAuthToken(token => $auth_token),
			'session_destroyAuthToken() succeeds');
	}

	# test session_destroy()
	ok($gs->session_destroy, 'session_destroy() succeeds');
}

sub diag_skip {
	my $msg = shift;
	diag($msg);
	skip $msg, @_;
}
