package WWW::TheMovieDB;

use 5.010000;
use strict;
use warnings;
use HTTP::Request;
use LWP::UserAgent;
use URI::Escape;
use JSON qw(encode_json);

our $VERSION = '0.05';
our $EMPTY = q{};
our $SL = q{/};
our $AM = q{&};
our $EQ = q{=};

sub new {
	my $package = bless{}, shift;
	my $params = shift;

	$package->{'api_key'}          = $params->{'key'}              || $EMPTY;
	$package->{'language'}         = $params->{'language'}         || 'en';
	$package->{'version'}          = $params->{'version'}          || '3';
	$package->{'type'}             = $params->{'type'}             || 'json';
	$package->{'uri'}              = $params->{'uri'}              || 'http://api.themoviedb.org';
	$package->{'request_token'}    = $params->{'requset_token'}    || $EMPTY;
	$package->{'session_id'}       = $params->{'session_id'}       || $EMPTY;
	$package->{'guest_session_id'} = $params->{'guest_session_id'} || $EMPTY;
	$package->{'user_id'}          = $params->{'user_id'}          || $EMPTY;

	return $package;
}

#
# Configuration Methods
# 

sub language {
	my $package = shift;
	$package->{'language'} = shift;
	return $package;
}

sub version {
	my $package = shift;
	$package->{'ver'} = shift;
	return $package;
}

sub api_key {
	my $package = shift;
	$package->{'api_key'} = shift;
	return $package;
}

sub type {
	my $package = shift;
	$package->{'type'} = shift;
	return $package;
}

sub request_token {
	my $package = shift;
	$package->{'request_token'} = shift;
	return $package;
}

sub session_id {
	my $package = shift;
	$package->{'session_id'} = shift;
	return $package;
}

sub guest_session_id {
	my $package = shift;
	$package->{'guest_session_id'} = shift;
	return $package;
}

sub user_id {
	my $package = shift;
	$package->{'user_id'} = shift;
	return $package;
}

#
# Application Methods
#

sub buildURL {
	my $package = shift;
	my $params = shift;

	my %query_string = $params->{'query_string'} ? %{$params->{'query_string'}} : ();

	my $url  = $package->{'uri'} . $SL . $package->{'version'} . $SL;
	   $url .= $params->{'function'};

	   $url .= "?api_key=". $package->{'api_key'};

	for my $key ( keys %query_string ) {
		$url .= $AM . $key . $EQ . $query_string{$key};
	}

	return $url;
}

sub getURL {
	my $package = shift;
	my $params = shift;

	my $url = $params->{'url'};
	my $method = $params->{'method'};
	my $json = $params->{'json'} || $EMPTY;

	my $ua = LWP::UserAgent->new;
	   $ua->agent("WWW::TheMovieDB/". $VERSION);

	# http://search.cpan.org/~gaas/HTTP-Message-6.06/lib/HTTP/Request.pm
	my $request = HTTP::Request->new;
	   $request->method( $method );
	   $request->uri( $url );
	   $request->header(accept=>'application/json');
	if ($json ne $EMPTY) {
		$request->header( 'Content-Type' => 'application/json' );
		$request->content( $json );
	}
	my $response = $ua->request($request);

	return $response->content;
}

#
# API Methods
#

#
# Configuration
# http://docs.themoviedb.apiary.io/#configuration
# 
sub Configuration::configuration {
	# Get the system wide configuration information. Some elements of the API require some knowledge of this 
	# configuration data. The purpose of this is to try and keep the actual API responses as light as possible. 
	# It is recommended you store this data within your application and check for updates every so often.
	# http://docs.themoviedb.apiary.io/#get-%2F3%2Fconfiguration
	my $package = shift;
	my $method = "GET";

	my $url = $package->buildURL({
		'function' => 'configuration'
	});

	return $package->getURL({
		'url'    => $url,
		'method' => $method
	});
}

#
# Authentication
# http://docs.themoviedb.apiary.io/#authentication
#
sub Authentication::request_token {
	# This method is used to generate a valid request token for user based authentication. A request token is required in order to request a session id.
	# This token must be authenticated by the user via: http://www.themoviedb.org/authenticate/{this_request_token}
	# http://docs.themoviedb.apiary.io/#get-%2F3%2Fauthentication%2Ftoken%2Fnew
	my $package = shift;
	my $method = "GET";

	my $url = $package->buildURL({
		'function' => 'authentication/token/new'
	});

	return $package->getURL({
		'url'    => $url,
		'method' => $method
	});
}

sub Authentication::session_new {
	# This method is used to generate a session id for user based authentication. A session id is required in order to use any of the write methods.
	# http://docs.themoviedb.apiary.io/#get-%2F3%2Fauthentication%2Fsession%2Fnew
	my $package = shift;
	my $method = "GET";
	my $query_string = shift;

	$query_string->{'request_token'} = $query_string->{'request_token'} || $package->{'request_token'};

	my $url = $package->buildURL({
		'function'     => 'authentication/session/new',
		'query_string' => \%{$query_string}
	});

	return $package->getURL({
		'url'    => $url,
		'method' => $method
	});
}

sub Authentication::guest_session_new {
	# This method is used to generate a guest session id.
	#
	# A guest session can be used to rate movies without having a registered TMDb user account. You should only generate a 
	# single guest session per user (or device) as you will be able to attach the ratings to a TMDb user account in the 
	# future. There is also IP limits in place so you should always make sure it's the end user doing the guest session actions.
	#
	# If a guest session is not used for the first time within 24 hours, it will be automatically discarded.
	# http://docs.themoviedb.apiary.io/#get-%2F3%2Fauthentication%2Fguest_session%2Fnew
	my $package = shift;
	my $method = "GET";

	my $url = $package->buildURL({
		'function' => 'authentication/guest_session/new'
	});

	return $package->getURL({
		'url'    => $url,
		'method' => $method
	});
}

#
# Account
# http://docs.themoviedb.apiary.io/#account
#
sub Account::account {
	# Get the basic information for an account. You will need to have a valid session id.
	# http://docs.themoviedb.apiary.io/#get-%2F3%2Faccount
	my $package = shift;
	my $method = "GET";
	my $query_string = shift;

	$query_string->{'session_id'} = $query_string->{'session_id'} || $package->{'session_id'};

	my $url = $package->buildURL({
		'function'     => 'account',
		'query_string' => \%{$query_string}
	});

	return $package->getURL({
		'url'    => $url,
		'method' => $method
	});
}

sub Account::lists {
	# Get the lists that you have created and marked as a favorite.
	# http://docs.themoviedb.apiary.io/#get-%2F3%2Faccount%2F{id}%2Flists
	my $package = shift;
	my $method = "GET";
	my $query_string = shift;

	$query_string->{'session_id'} = $query_string->{'session_id'} || $package->{'session_id'};
	$query_string->{'user_id'}    = $query_string->{'user_id'}    || $package->{'user_id'};
	$query_string->{'language'}   = $query_string->{'language'}   || $package->{'language'};
	$query_string->{'page'}       = $query_string->{'page'}       || 1;

	my $url = $package->buildURL({
		'function'     => 'account/'. (delete $query_string->{'user_id'}) .'/lists',
		'query_string' => \%{$query_string}
	});

	return $package->getURL({
		'url'    => $url,
		'method' => $method
	});
}

sub Account::favorite_movies {
	# Get the list of favorite movies for an account.
	# http://docs.themoviedb.apiary.io/#get-%2F3%2Faccount%2F{id}%2Ffavorite_movies
	my $package = shift;
	my $method = "GET";
	my $query_string = shift;

	$query_string->{'session_id'} = $query_string->{'session_id'} || $package->{'session_id'};
	$query_string->{'user_id'}    = $query_string->{'user_id'}    || $package->{'user_id'};
	$query_string->{'language'}   = $query_string->{'language'}   || $package->{'language'};
	$query_string->{'page'}       = $query_string->{'page'}       || 1;
	$query_string->{'sort_by'}    = $query_string->{'sort_by'}    || 'created_at';
	$query_string->{'sort_order'} = $query_string->{'sort_order'} || 'asc';

	my $url = $package->buildURL({
		'function'     => 'account/'. (delete $query_string->{'user_id'}) .'/favorite_movies',
		'query_string' => \%{$query_string}
	});

	return $package->getURL({
		'url'    => $url,
		'method' => $method
	});
}

sub Account::favorite {
	# Add or remove a movie to an accounts favorite list.
	# http://docs.themoviedb.apiary.io/#post-%2F3%2Faccount%2F{id}%2Ffavorite
	my $package = shift;
	my $method = "POST";
	my $query_string = shift;

	$query_string->{'session_id'} = $query_string->{'session_id'} || $package->{'session_id'};
	$query_string->{'user_id'}    = $query_string->{'user_id'}    || $package->{'user_id'};

	my %jsonTemp = (
		'movie_id' => (delete $query_string->{'movie_id'}),
		'favorite' => (delete $query_string->{'favorite'})
	);

	my $json = encode_json(\%jsonTemp);

	my $url = $package->buildURL({
		'function'     => 'account/'. (delete $query_string->{'user_id'}) .'/favorite',
		'query_string' => \%{$query_string}
	});

	return $package->getURL({
		'url'    => $url,
		'method' => $method,
		'json'   => $json
	});
}

sub Account::rated_movies {
	# Get the list of rated movies (and associated rating) for an account.
	# http://docs.themoviedb.apiary.io/#get-%2F3%2Faccount%2F{id}%2Frated_movies
	my $package = shift;
	my $method = "GET";
	my $query_string = shift;

	$query_string->{'session_id'} = $query_string->{'session_id'} || $package->{'session_id'};
	$query_string->{'user_id'}    = $query_string->{'user_id'}    || $package->{'user_id'};
	$query_string->{'language'}   = $query_string->{'language'}   || $package->{'language'};
	$query_string->{'page'}       = $query_string->{'page'}       || 1;
	$query_string->{'sort_by'}    = $query_string->{'sort_by'}    || 'created_at';
	$query_string->{'sort_order'} = $query_string->{'sort_order'} || 'asc';

	my $url = $package->buildURL({
		'function'     => 'account/'. (delete $query_string->{'user_id'}) .'/rated_movies',
		'query_string' => \%{$query_string}
	});

	return $package->getURL({
		'url'    => $url,
		'method' => $method
	});
}

sub Account::movie_watchlist {
	# Get the list of movies on an accounts watchlist.
	# http://docs.themoviedb.apiary.io/#get-%2F3%2Faccount%2F{id}%2Fmovie_watchlist
	my $package = shift;
	my $method = "GET";
	my $query_string = shift;

	$query_string->{'session_id'} = $query_string->{'session_id'} || $package->{'session_id'};
	$query_string->{'user_id'}    = $query_string->{'user_id'}    || $package->{'user_id'};
	$query_string->{'language'}   = $query_string->{'language'}   || $package->{'language'};
	$query_string->{'page'}       = $query_string->{'page'}       || 1;
	$query_string->{'sort_by'}    = $query_string->{'sort_by'}    || 'created_at';
	$query_string->{'sort_order'} = $query_string->{'sort_order'} || 'asc';

	my $url = $package->buildURL({
		'function'     => 'account/'. (delete $query_string->{'user_id'}) .'/movie_watchlist',
		'query_string' => \%{$query_string}
	});

	return $package->getURL({
		'url'    => $url,
		'method' => $method
	});
}

sub Account::modify_movie_watchlist {
	# Add or remove a movie to an accounts watch list.
	# http://docs.themoviedb.apiary.io/#post-%2F3%2Faccount%2F{id}%2Fmovie_watchlist
	my $package = shift;
	my $method = "POST";
	my $query_string = shift;

	$query_string->{'session_id'} = $query_string->{'session_id'} || $package->{'session_id'};
	$query_string->{'user_id'}    = $query_string->{'user_id'}    || $package->{'user_id'};

	my %jsonTemp = (
		'movie_id'        => (delete $query_string->{'movie_id'}),
		'movie_watchlist' => (delete $query_string->{'movie_watchlist'})
	);

	my $json = encode_json(\%jsonTemp);

	my $url = $package->buildURL({
		'function'     => 'account/'. (delete $query_string->{'user_id'}) .'/movie_watchlist',
		'query_string' => \%{$query_string}
	});

	return $package->getURL({
		'url'    => $url,
		'method' => $method,
		'json'   => $json
	});
}


#
# Movies
# http://docs.themoviedb.apiary.io/#movies
#
sub Movies::info {
	# Get the basic movie information for a specific movie id.
	# http://docs.themoviedb.apiary.io/#get-%2F3%2Fmovie%2F{id}
	my $package = shift;
	my $method = "GET";
	my $query_string = shift;

	$query_string->{'language'} = $query_string->{'language'} || $package->{'language'};

	my $url = $package->buildURL({
		'function'     => 'movie/'. (delete $query_string->{'movie_id'}),
		'query_string' => \%{$query_string}
	});

	return $package->getURL({
		'url'    => $url,
		'method' => $method
	});
}

sub Movies::alternative_titles {
	# Get the alternative titles for a specific movie id.
	# http://docs.themoviedb.apiary.io/#get-%2F3%2Fmovie%2F{id}%2Falternative_titles
	my $package = shift;
	my $method = "GET";
	my $query_string = shift;

	my $url = $package->buildURL({
		'function'     => 'movie/'. (delete $query_string->{'movie_id'}) .'/alternative_titles',
		'query_string' => \%{$query_string}
	});

	return $package->getURL({
		'url'    => $url,
		'method' => $method
	});
}

sub Movies::casts {
	# Get the cast information for a specific movie id.
	# http://docs.themoviedb.apiary.io/#get-%2F3%2Fmovie%2F{id}%2Fcasts
	my $package = shift;
	my $method = "GET";
	my $params = shift;

	my $url = $package->buildURL({
		'function' => 'movie/'. $params->{'movie_id'} .'/casts'
	});

	return $package->getURL({
		'url'    => $url,
		'method' => $method
	});
}

sub Movies::images {
	# Get the images (posters and backdrops) for a specific movie id.
	# http://docs.themoviedb.apiary.io/#get-%2F3%2Fmovie%2F{id}%2Fimages
	my $package = shift;
	my $method = "GET";
	my $query_string = shift;

	my $url = $package->buildURL({
		'function'     => 'movie/'. (delete $query_string->{'movie_id'}) .'/images',
		'query_string' => \%{$query_string}
	});

	return $package->getURL({
		'url'    => $url,
		'method' => $method
	});
}

sub Movies::keywords {
	# Get the plot keywords for a specific movie id.
	# http://docs.themoviedb.apiary.io/#get-%2F3%2Fmovie%2F{id}%2Fkeywords
	my $package = shift;
	my $method = "GET";
	my $params = shift;

	my $url = $package->buildURL({
		'function' => 'movie/'. $params->{'movie_id'} .'/keywords'
	});

	return $package->getURL({
		'url'    => $url,
		'method' => $method
	});
}

sub Movies::releases {
	# Get the release date by country for a specific movie id.
	# http://docs.themoviedb.apiary.io/#get-%2F3%2Fmovie%2F{id}%2Freleases
	my $package = shift;
	my $method = "GET";
	my $params = shift;

	my $url = $package->buildURL({
		'function' => 'movie/'. $params->{'movie_id'} .'/releases'
	});

	return $package->getURL({
		'url'    => $url,
		'method' => $method
	});
}

sub Movies::trailers {
	# Get the trailers for a specific movie id.
	# http://docs.themoviedb.apiary.io/#get-%2F3%2Fmovie%2F{id}%2Ftrailers
	my $package = shift;
	my $method = "GET";
	my $params = shift;

	my $url = $package->buildURL({
		'function' => 'movie/'. $params->{'movie_id'} .'/trailers'
	});

	return $package->getURL({
		'url'    => $url,
		'method' => $method
	});
}

sub Movies::translations {
	# Get the translations for a specific movie id.
	# http://docs.themoviedb.apiary.io/#get-%2F3%2Fmovie%2F{id}%2Ftranslations
	my $package = shift;
	my $method = "GET";
	my $params = shift;

	my $url = $package->buildURL({
		'function' => 'movie/'. $params->{'movie_id'} .'/translations'
	});

	return $package->getURL({
		'url'    => $url,
		'method' => $method
	});
}

sub Movies::similar_movies {
	# Get the similar movies for a specific movie id.
	# http://docs.themoviedb.apiary.io/#get-%2F3%2Fmovie%2F{id}%2Fsimilar_movies
	my $package = shift;
	my $method = "GET";
	my $query_string = shift;

	$query_string->{'language'} = $query_string->{'language'} || $package->{'language'};
	$query_string->{'page'}     = $query_string->{'page'}     || 1;

	my $url = $package->buildURL({
		'function'     => 'movie/'. (delete $query_string->{'movie_id'}) .'/similar_movies',
		'query_string' => \%{$query_string}
	});

	return $package->getURL({
		'url'    => $url,
		'method' => $method
	});
}

sub Movies::reviews {
	# Get the reviews for a particular movie id.
	# http://docs.themoviedb.apiary.io/#get-%2F3%2Fmovie%2F{id}%2Freviews
	my $package = shift;
	my $method = "GET";
	my $query_string = shift;

	$query_string->{'language'} = $query_string->{'language'} || $package->{'language'};
	$query_string->{'page'}     = $query_string->{'page'}     || 1;

	my $url = $package->buildURL({
		'function'     => 'movie/'. (delete $query_string->{'movie_id'}) .'/reviews',
		'query_string' => \%{$query_string}
	});

	return $package->getURL({
		'url'    => $url,
		'method' => $method
	});
}

sub Movies::lists {
	# Get the lists that the movie belongs to.
	# http://docs.themoviedb.apiary.io/#get-%2F3%2Fmovie%2F{id}%2Flists
	my $package = shift;
	my $method = "GET";
	my $query_string = shift;

	$query_string->{'language'} = $query_string->{'language'} || $package->{'language'};
	$query_string->{'page'}     = $query_string->{'page'}     || 1;

	my $url = $package->buildURL({
		'function'     => 'movie/'. (delete $query_string->{'movie_id'}) .'/lists',
		'query_string' => \%{$query_string}
	});

	return $package->getURL({
		'url'    => $url,
		'method' => $method
	});
}

sub Movies::changes {
	# Get the changes for a specific movie id.
	# http://docs.themoviedb.apiary.io/#get-%2F3%2Fmovie%2F{id}%2Fchanges
	my $package = shift;
	my $method = "GET";
	my $query_string = shift;

	my $url = $package->buildURL({
		'function'     => 'movie/'. (delete $query_string->{'movie_id'}) .'/changes',
		'query_string' => \%{$query_string}
	});

	return $package->getURL({
		'url'    => $url,
		'method' => $method
	});
}

sub Movies::latest {
	# Get the latest movie id.
	# http://docs.themoviedb.apiary.io/#get-%2F3%2Fmovie%2Flatest
	my $package = shift;
	my $method = "GET";

	my $url = $package->buildURL({
		'function' => 'movie/latest'
	});

	return $package->getURL({
		'url'    => $url,
		'method' => $method
	});
}

sub Movies::upcoming {
	# Get the list of upcoming movies. This list refreshes every day. The maximum number of items this list will include is 100.
	# http://docs.themoviedb.apiary.io/#get-%2F3%2Fmovie%2Fupcoming
	my $package = shift;
	my $method = "GET";
	my $query_string = shift;

	$query_string->{'language'} = $query_string->{'language'} || $package->{'language'};
	$query_string->{'page'}     = $query_string->{'page'}     || 1;

	my $url = $package->buildURL({
		'function'     => 'movie/upcoming',
		'query_string' => \%{$query_string}
	});

	return $package->getURL({
		'url'    => $url,
		'method' => $method
	});
}

sub Movies::now_playing {
	# Get the list of movies playing in theatres. This list refreshes every day. The maximum number of items this list will include is 100.
	# http://docs.themoviedb.apiary.io/#get-%2F3%2Fmovie%2Fnow_playing
	my $package = shift;
	my $method = "GET";
	my $query_string = shift;

	$query_string->{'language'} = $query_string->{'language'} || $package->{'language'};
	$query_string->{'page'}     = $query_string->{'page'}     || 1;

	my $url = $package->buildURL({
		'function'     => 'movie/now_playing',
		'query_string' => \%{$query_string}
	});

	return $package->getURL({
		'url'    => $url,
		'method' => $method
	});
}

sub Movies::popular {
	# Get the list of popular movies on The Movie Database. This list refreshes every day.
	# http://docs.themoviedb.apiary.io/#get-%2F3%2Fmovie%2Fpopular
	my $package = shift;
	my $method = "GET";
	my $query_string = shift;

	$query_string->{'language'} = $query_string->{'language'} || $package->{'language'};
	$query_string->{'page'}     = $query_string->{'page'}     || 1;

	my $url = $package->buildURL({
		'function'     => 'movie/popular',
		'query_string' => \%{$query_string}
	});

	return $package->getURL({
		'url'    => $url,
		'method' => $method
	});
}

sub Movies::top_rated {
	# Get the list of top rated movies. By default, this list will only include movies that have 10 or more votes. This list refreshes every day.
	# http://docs.themoviedb.apiary.io/#get-%2F3%2Fmovie%2Ftop_rated
	my $package = shift;
	my $method = "GET";
	my $query_string = shift;

	$query_string->{'language'} = $query_string->{'language'} || $package->{'language'};
	$query_string->{'page'}     = $query_string->{'page'}     || 1;

	my $url = $package->buildURL({
		'function'     => 'movie/top_rated',
		'query_string' => \%{$query_string}
	});

	return $package->getURL({
		'url'    => $url,
		'method' => $method
	});
}

sub Movies::account_states {
	# This method lets users get the status of whether or not the movie has been rated or added to their favourite or watch lists. A valid session id is required.
	# http://docs.themoviedb.apiary.io/#get-%2F3%2Fmovie%2F{id}%2Faccount_states
	my $package = shift;
	my $method = "GET";
	my $query_string = shift;

	$query_string->{'session_id'} = $query_string->{'session_id'} || $package->{'session_id'};

	my $url = $package->buildURL({
		'function'     => 'movie/'. (delete $query_string->{'movie_id'}) .'/account_states',
		'query_string' => \%{$query_string}
	});

	return $package->getURL({
		'url'    => $url,
		'method' => $method
	});
}

sub Movies::rate {
	# This method lets users rate a movie. A valid session id or guest session id is required.
	# http://docs.themoviedb.apiary.io/#post-%2F3%2Fmovie%2F{id}%2Frating
	my $package = shift;
	my $method = "POST";
	my $query_string = shift;

	$query_string->{'session_id'} = $query_string->{'session_id'} || $package->{'session_id'};
	if ($query_string->{'session_id'} eq $EMPTY) {
		delete $query_string->{'session_id'};
		$query_string->{'guest_session_id'} = $query_string->{'guest_session_id'} || $package->{'guest_session_id'};
	}

	my %jsonTemp = (
		'value' => (delete $query_string->{'value'})
	);

	my $json = encode_json(\%jsonTemp);

	my $url = $package->buildURL({
		'function'     => 'movie/'. (delete $query_string->{'movie_id'}) .'/rating',
		'query_string' => \%{$query_string}
	});

	return $package->getURL({
		'url'    => $url,
		'method' => $method,
		'json'   => $json
	});
}

#
# Collections
# http://docs.themoviedb.apiary.io/#collections
#
sub Collections::info {
	# Get the basic collection information for a specific collection id. You can get the ID needed for this 
	# method by making a /movie/{id} request and paying attention to the belongs_to_collection hash.
	my $package = shift;
	my $method = "GET";
	my $query_string = shift;

	$query_string->{'language'} = $query_string->{'language'} || $package->{'language'};

	my $url = $package->buildURL({
		'function'     => 'collection/'. (delete $query_string->{'id'}),
		'query_string' => \%{$query_string}
	});

	return $package->getURL({
		'url'    => $url,
		'method' => $method
	});
}

sub Collections::images {
	# Get all of the images for a particular collection by collection id.
	# http://docs.themoviedb.apiary.io/#get-%2F3%2Fcollection%2F{id}%2Fimages
	my $package = shift;
	my $method = "GET";
	my $query_string = shift;

	$query_string->{'language'} = $query_string->{'language'} || $package->{'language'};

	my $url = $package->buildURL({
		'function'     => 'collection/'. (delete $query_string->{'id'}) .'/images',
		'query_string' => \%{$query_string}
	});

	return $package->getURL({
		'url'    => $url,
		'method' => $method
	});
}

#
# People
# http://docs.themoviedb.apiary.io/#people
# 
sub People::info {
	# Get the general person information for a specific id.
	# http://docs.themoviedb.apiary.io/#get-%2F3%2Fperson%2F{id}
	my $package = shift;
	my $method = "GET";
	my $query_string = shift;

	my $url = $package->buildURL({
		'function' => 'person/'. (delete $query_string->{'person_id'})
	});

	return $package->getURL({
		'url'    => $url,
		'method' => $method
	});
}

sub People::credits {
	# Get the credits for a specific person id.
	# http://docs.themoviedb.apiary.io/#get-%2F3%2Fperson%2F{id}%2Fcredits
	my $package = shift;
	my $method = "GET";
	my $query_string = shift;

	my $url = $package->buildURL({
		'function'     => 'person/'. (delete $query_string->{'person_id'}) .'/credits',
		'query_string' => \%{$query_string}
	});

	return $package->getURL({
		'url'    => $url,
		'method' => $method
	});
}

sub People::images {
	# Get the images for a specific person id.
	# Get the general person information for a specific id.
	# http://docs.themoviedb.apiary.io/#get-%2F3%2Fperson%2F{id}%2Fimages
	my $package = shift;
	my $method = "GET";
	my $query_string = shift;

	my $url = $package->buildURL({
		'function' => 'person/'. (delete $query_string->{'person_id'}) .'/images'
	});

	return $package->getURL({
		'url'    => $url,
		'method' => $method
	});
}

sub People::changes {
	# Get the changes for a specific person id.
	# http://docs.themoviedb.apiary.io/#get-%2F3%2Fperson%2F{id}%2Fchanges
	my $package = shift;
	my $method = "GET";
	my $query_string = shift;

	my $url = $package->buildURL({
		'function'     => 'person/'. (delete $query_string->{'person_id'}) .'/changes',
		'query_string' => \%{$query_string}
	});

	return $package->getURL({
		'url'    => $url,
		'method' => $method
	});
}

sub People::popular {
	# Get the list of popular people on The Movie Database. This list refreshes every day.
	# http://docs.themoviedb.apiary.io/#get-%2F3%2Fperson%2Fpopular
	my $package = shift;
	my $method = "GET";
	my $query_string = shift;

	$query_string->{'page'} = $query_string->{'page'} || 1;

	my $url = $package->buildURL({
		'function'     => 'person/popular',
		'query_string' => \%{$query_string}
	});

	return $package->getURL({
		'url'    => $url,
		'method' => $method
	});
}

sub People::latest {
	# Get the latest person id.
	# http://docs.themoviedb.apiary.io/#get-%2F3%2Fperson%2Flatest
	my $package = shift;
	my $method = "GET";

	my $url = $package->buildURL({
		'function' => 'person/latest'
	});

	return $package->getURL({
		'url'    => $url,
		'method' => $method
	});
}

#
# Lists
# http://docs.themoviedb.apiary.io/#lists
#
sub Lists::info {
	# Get a list by id.
	# http://docs.themoviedb.apiary.io/#get-%2F3%2Flist%2F{id}
	my $package = shift;
	my $method = "GET";
	my $query_string = shift;

	my $url = $package->buildURL({
		'function' => 'list/'. (delete $query_string->{'list_id'})
	});

	return $package->getURL({
		'url'    => $url,
		'method' => $method
	});
}

sub Lists::item_status {
	# Check to see if a movie ID is already added to a list.
	# http://docs.themoviedb.apiary.io/#get-%2F3%2Flist%2F{id}%2Fitem_status
	my $package = shift;
	my $method = "GET";
	my $query_string = shift;

	my $url = $package->buildURL({
		'function'     => 'list/'. (delete $query_string->{'list_id'}) .'/item_status',
		'query_string' => \%{$query_string}
	});

	return $package->getURL({
		'url'    => $url,
		'method' => $method
	});
}

sub Lists::create {
	# This method lets users create a new list. A valid session id is required.
	# http://docs.themoviedb.apiary.io/#post-%2F3%2Flist
	my $package = shift;
	my $method = "POST";
	my $query_string = shift;

	$query_string->{'session_id'} = $query_string->{'session_id'} || $package->{'session_id'};
	$query_string->{'language'} = $query_string->{'language'} || $package->{'session_id'};

	my %jsonTemp = (
		'language'    => (delete $query_string->{'language'}),
		'name'        => (delete $query_string->{'name'}),
		'description' => (delete $query_string->{'description'})
	);

	my $json = encode_json(\%jsonTemp);

	my $url = $package->buildURL({
		'function'     => 'list',
		'query_string' => \%{$query_string}
	});

	return $package->getURL({
		'url'    => $url,
		'method' => $method,
		'json'   => $json
	});
}

sub Lists::add_item {
	# This method lets users add new movies to a list that they created. A valid session id is required.
	# http://docs.themoviedb.apiary.io/#post-%2F3%2Flist%2F{id}%2Fadd_item
	my $package = shift;
	my $method = "POST";
	my $query_string = shift;

	$query_string->{'session_id'} = $query_string->{'session_id'} || $package->{'session_id'};

	my %jsonTemp = (
		'media_id' => (delete $query_string->{'media_id'})
	);

	my $json = encode_json(\%jsonTemp);

	my $url = $package->buildURL({
		'function'     => 'list/'. (delete $query_string->{'list_id'}) .'/add_item',
		'query_string' => \%{$query_string}
	});

	return $package->getURL({
		'url'    => $url,
		'method' => $method,
		'json'   => $json
	});
}

sub Lists::remove_item {
	# This method lets users delete movies from a list that they created. A valid session id is required.
	# http://docs.themoviedb.apiary.io/#post-%2F3%2Flist%2F{id}%2Fremove_item
	my $package = shift;
	my $method = "POST";
	my $query_string = shift;

	$query_string->{'session_id'} = $query_string->{'session_id'} || $package->{'session_id'};

	my %jsonTemp = (
		'media_id' => (delete $query_string->{'media_id'})
	);

	my $json = encode_json(\%jsonTemp);

	my $url = $package->buildURL({
		'function'     => 'list/'. (delete $query_string->{'list_id'}) .'/remove_item',
		'query_string' => \%{$query_string}
	});

	return $package->getURL({
		'url'    => $url,
		'method' => $method,
		'json'   => $json
	});
}

sub Lists::delete {
	# This method lets users delete a list that they created. A valid session id is required.
	# http://docs.themoviedb.apiary.io/#delete-%2F3%2Flist%2F{id}
	my $package = shift;
	my $method = "DELETE";
	my $query_string = shift;

	$query_string->{'session_id'} = $query_string->{'session_id'} || $package->{'session_id'};

	my $url = $package->buildURL({
		'function'     => 'list/'. (delete $query_string->{'list_id'}),
		'query_string' => \%{$query_string}
	});

	return $package->getURL({
		'url'    => $url,
		'method' => $method
	});
}

#
# Companies
# http://docs.themoviedb.apiary.io/#companies
#
sub Companies::info {
	# This method is used to retrieve all of the basic information about a company.
	# http://docs.themoviedb.apiary.io/#get-%2F3%2Fcompany%2F{id}
	my $package = shift;
	my $method = "GET";
	my $query_string = shift;

	my $url = $package->buildURL({
		'function' => 'company/'. (delete $query_string->{'company_id'})
	});

	return $package->getURL({
		'url'    => $url,
		'method' => $method
	});
}

sub Companies::movies {
	# Get the list of movies associated with a particular company.
	# http://docs.themoviedb.apiary.io/#get-%2F3%2Fcompany%2F{id}%2Fmovies
	my $package = shift;
	my $method = "GET";
	my $query_string = shift;

	$query_string->{'page'} = $query_string->{'page'} || 1;
	$query_string->{'language'} = $query_string->{'language'} || $package->{'language'};

	my $url = $package->buildURL({
		'function'     => 'company/'. (delete $query_string->{'company_id'}) .'/movies',
		'query_string' => \%{$query_string}
	});

	return $package->getURL({
		'url'    => $url,
		'method' => $method
	});
}

#
# Genres
# http://docs.themoviedb.apiary.io/#genres
#
sub Genres::list {
	# Get the list of genres.
	# http://docs.themoviedb.apiary.io/#get-%2F3%2Fgenre%2Flist
	my $package = shift;
	my $method = "GET";
	my $query_string = shift;

	$query_string->{'language'} = $query_string->{'language'} || $package->{'language'};

	my $url = $package->buildURL({
		'function'     => 'genre/list',
		'query_string' => \%{$query_string}
	});

	return $package->getURL({
		'url'    => $url,
		'method' => $method
	});
}

sub Genres::movies {
	# Get the list of movies for a particular genre by id. By default, only movies with 10 or more votes are included.
	# http://docs.themoviedb.apiary.io/#get-%2F3%2Fgenre%2F{id}%2Fmovies
	my $package = shift;
	my $method = "GET";
	my $query_string = shift;

	$query_string->{'language'} = $query_string->{'language'} || $package->{'language'};
	$query_string->{'page'} = $query_string->{'page'} || 1;
	$query_string->{'include_adult'} = $query_string->{'include_adult'} || 'false';
	$query_string->{'include_all_movies'} = $query_string->{'include_all_movies'} || 'false';

	my $url = $package->buildURL({
		'function'     => 'genre/'. (delete $query_string->{'genre_id'}) .'/movies',
		'query_string' => \%{$query_string}
	});

	return $package->getURL({
		'url'    => $url,
		'method' => $method
	});
}

#
# Keywords
# http://docs.themoviedb.apiary.io/#keywords
#
sub Keywords::info {
	# Get the basic information for a specific keyword id.
	# http://docs.themoviedb.apiary.io/#get-%2F3%2Fkeyword%2F{id}
	my $package = shift;
	my $method = "GET";
	my $query_string = shift;

	my $url = $package->buildURL({
		'function' => 'keyword/'. (delete $query_string->{'keyword_id'})
	});

	return $package->getURL({
		'url'    => $url,
		'method' => $method
	});
}

sub Keywords::movies {
	# Get the list of movies for a particular keyword by id.
	# http://docs.themoviedb.apiary.io/#get-%2F3%2Fkeyword%2F{id}%2Fmovies
	my $package = shift;
	my $method = "GET";
	my $query_string = shift;

	$query_string->{'language'} = $query_string->{'language'} || $package->{'language'};
	$query_string->{'page'} = $query_string->{'page'} || 1;

	my $url = $package->buildURL({
		'function'     => 'keyword/'. (delete $query_string->{'keyword_id'}) .'/movies',
		'query_string' => \%{$query_string}
	});

	return $package->getURL({
		'url'    => $url,
		'method' => $method
	});
}

#
# Discover
# http://docs.themoviedb.apiary.io/#discover
#
sub Discover::movie {
	# Discover movies by different types of data like average rating, number of votes, genres and certifications.
	# http://docs.themoviedb.apiary.io/#get-%2F3%2Fdiscover%2Fmovie
	my $package = shift;
	my $method = "GET";
	my $query_string = shift;

	$query_string->{'language'} = $query_string->{'language'} || $package->{'language'};
	$query_string->{'page'} = $query_string->{'page'} || 1;

	my $url = $package->buildURL({
		'function'     => 'discover/movie',
		'query_string' => \%{$query_string}
	});

	return $package->getURL({
		'url'    => $url,
		'method' => $method
	});
}

#
# Search
# http://docs.themoviedb.apiary.io/#search
#
sub Search::movie {
	# Search for movies by title.
	# http://docs.themoviedb.apiary.io/#get-%2F3%2Fsearch%2Fmovie
	my $package = shift;
	my $method = "GET";
	my $query_string = shift;

	$query_string->{'page'} = $query_string->{'page'} || 1;
	$query_string->{'language'} = $query_string->{'language'} || $package->{'language'};
	$query_string->{'include_adult'} = $query_string->{'include_adult'} || 'false';

	my $url = $package->buildURL({
		'function'     => 'search/movie',
		'query_string' => \%{$query_string}
	});

	return $package->getURL({
		'url'    => $url,
		'method' => $method
	});
}

sub Search::collection {
	# Search for collections by name.
	# http://docs.themoviedb.apiary.io/#get-%2F3%2Fsearch%2Fcollection
	my $package = shift;
	my $method = "GET";
	my $query_string = shift;

	$query_string->{'page'} = $query_string->{'page'} || 1;
	$query_string->{'language'} = $query_string->{'language'} || $package->{'language'};
	$query_string->{'include_adult'} = $query_string->{'include_adult'} || 'false';

	my $url = $package->buildURL({
		'function'     => 'search/collection',
		'query_string' => \%{$query_string}
	});

	return $package->getURL({
		'url'    => $url,
		'method' => $method
	});
}

sub Search::person {
	# Search for people by name.
	# http://docs.themoviedb.apiary.io/#get-%2F3%2Fsearch%2Fperson
	my $package = shift;
	my $method = "GET";
	my $query_string = shift;

	$query_string->{'page'} = $query_string->{'page'} || 1;
	$query_string->{'language'} = $query_string->{'language'} || $package->{'language'};
	$query_string->{'include_adult'} = $query_string->{'include_adult'} || 'false';

	my $url = $package->buildURL({
		'function'     => 'search/person',
		'query_string' => \%{$query_string}
	});

	return $package->getURL({
		'url'    => $url,
		'method' => $method
	});
}

sub Search::list {
	# Search for lists by name and description.
	# http://docs.themoviedb.apiary.io/#get-%2F3%2Fsearch%2Flist
	my $package = shift;
	my $method = "GET";
	my $query_string = shift;

	$query_string->{'page'} = $query_string->{'page'} || 1;
	$query_string->{'language'} = $query_string->{'language'} || $package->{'language'};
	$query_string->{'include_adult'} = $query_string->{'include_adult'} || 'false';

	my $url = $package->buildURL({
		'function'     => 'search/list',
		'query_string' => \%{$query_string}
	});

	return $package->getURL({
		'url'    => $url,
		'method' => $method
	});
}

sub Search::company {
	# Search for companies by name.
	# http://docs.themoviedb.apiary.io/#get-%2F3%2Fsearch%2Fcompany
	my $package = shift;
	my $method = "GET";
	my $query_string = shift;
	$query_string->{'page'} = $query_string->{'page'} || 1;
	$query_string->{'language'} = $query_string->{'language'} || $package->{'language'};
	$query_string->{'include_adult'} = $query_string->{'include_adult'} || 'false';

	my $url = $package->buildURL({
		'function'     => 'search/company',
		'query_string' => \%{$query_string}
	});

	return $package->getURL({
		'url'    => $url,
		'method' => $method
	});
}

sub Search::keyword {
	# Search for keywords by name.
	# http://docs.themoviedb.apiary.io/#get-%2F3%2Fsearch%2Fkeyword
	my $package = shift;
	my $method = "GET";
	my $query_string = shift;
	$query_string->{'page'} = $query_string->{'page'} || 1;
	$query_string->{'language'} = $query_string->{'language'} || $package->{'language'};
	$query_string->{'include_adult'} = $query_string->{'include_adult'} || 'false';

	my $url = $package->buildURL({
		'function'     => 'search/keyword',
		'query_string' => \%{$query_string}
	});

	return $package->getURL({
		'url'    => $url,
		'method' => $method
	});
}

#
# Reviews
# http://docs.themoviedb.apiary.io/#reviews
#
sub Reviews::info {
	# Get the full details of a review by ID.
	# http://docs.themoviedb.apiary.io/#get-%2F3%2Freview%2F{id}
	my $package = shift;
	my $method = "GET";
	my $query_string = shift;

	my $url = $package->buildURL({
		'function' => 'review/'. (delete $query_string->{'review_id'})
	});

	return $package->getURL({
		'url'    => $url,
		'method' => $method
	});
}

#
# Changes
# http://docs.themoviedb.apiary.io/#changes
#
sub Changes::movie {
	# Get a list of movie ids that have been edited. By default we show the last 24 hours and only 100 items per page. The 
	# maximum number of days that can be returned in a single request is 14. You can then use the movie changes API to get 
	# the actual data that has been changed.
	# http://docs.themoviedb.apiary.io/#get-%2F3%2Fmovie%2Fchanges
	my $package = shift;
	my $query_string = shift;
	my $method = "GET";

	my $url = $package->buildURL({
		'function'     => 'movie/changes',
		'query_string' => \%{$query_string}
	});

	return $package->getURL({
		'url'    => $url,
		'method' => $method
	});
}

sub Changes::person {
	# Get a list of people ids that have been edited. By default we show the last 24 hours and only 100 items per page. The 
	# maximum number of days that can be returned in a single request is 14. You can then use the person changes API to get 
	# the actual data that has been changed.
	# http://docs.themoviedb.apiary.io/#get-%2F3%2Fperson%2Fchanges
	my $package = shift;
	my $query_string = shift;
	my $method = "GET";

	my $url = $package->buildURL({
		'function'     => 'person/changes',
		'query_string' => \%{$query_string}
	});

	return $package->getURL({
		'url'    => $url,
		'method' => $method
	});
}


#
# Jobs
# http://docs.themoviedb.apiary.io/#jobs
#
sub Jobs::list {
	# Get a list of valid jobs.
	# http://docs.themoviedb.apiary.io/#get-%2F3%2Fjob%2Flist
	my $package = shift;
	my $method = "GET";

	my $url = $package->buildURL({
		'function' => 'job/list'
	});

	return $package->getURL({
		'url'    => $url,
		'method' => $method
	});
}



1;
__END__

=head1 NAME

WWW::TheMovieDB - Complete Perl client to the TMDb API

=head1 SYNOPSIS

A full feature TMDb client.

=head1 DESCRIPTION

This module is a complete rewrite of my original WWW::TheMovieDB::Search which attempts to 
allow access to all methods of the API provided by TheMovieDB.

This module requires an API key for TheMovieDB.org, see: REFERENCE

=head1 DOCUMENTATION

The 000000000000000000000000000000000 should be replaced with your individual API key, you can get an API key
from TheMovieDB. Review the REFERENCE section for more information.

Basic initialization.

	use WWW::TheMovieDB;
	my $api = new WWW::TheMovieDB({
		'key'=>'000000000000000000000000000000000'
	});

Slightly advanced initialization.

	use WWW::TheMovieDB;
	my $api = new WWW::TheMovieDB({
		'key'		=>	'000000000000000000000000000000000',
		'language'	=>	'en',
		'version'	=>	'3',
		'type'		=>	'json',
		'uri'		=>	'http://api.themoviedb.org'
	});

You can also set the globals via methods.

	use WWW::TheMovieDB;
	my $api = new WWW::TheMovieDB();
	$api->api_key('000000000000000000000000000000000');
	$api->language('en'); # default: en
	$api->version('3');   # default: 3
	$api->type('json');   # default: json

=head2 Sessions & Guest Sessions

Some of the methods in this module require either a session_id or a guest_session_id.

B<Session>

=over 1

=item *

Account::account

=item *

Account::lists

=item *

Account::favorite_movies

=item *

Account::favorite

=item *

Account::rated_movies

=item *

Account::movie_watchlist

=item *

Account::modify_movie_watchlist

=item *

Movies::account_states

=item *

Movies::rate

=item *

Lists::create

=item *

Lists::add_item

=item *

Lists::remove_item

=item *

Lists::delete

=back

B<Guest Session>

=over 1

=item *

Movies::rate

=back

To use these methods you can pass the ID in as such, you should never use both session_id and guest_session_id at the same time.

	my $api = new WWW::TheMovieDB({
		'key'        => '000000000000000000000000000000000',
		'session_id' =>	'000000000000000000000000000000000'
	});

OR

	my $api = new WWW::TheMovieDB({
		'key'              => '000000000000000000000000000000000',
		'guest_session_id' => '000000000000000000000000000000000'
	});

OR

	$api->session_id('000000000000000000000000000000000');

OR

	$api->guest_session_id('000000000000000000000000000000000');

OR

	$api->Movies::rate({
		'session_id' => '000000000000000000000000000000000',
		'id' => 550,
		'value' => '9.5'
	});

OR

	$api->Movies::rate({
		'guest_session_id' => '000000000000000000000000000000000',
		'id' => 550,
		'value' => '9.5'
	});

If you pass the id in using the session_id or guest_session_id method you will not need to pass it into the method later on.

	$api->session_id('000000000000000000000000000000000');
	$api->Movies::rate({
		'id' => 550,
		'value' => '9.5'
	});

To generate a standard session you will first need to use:

	print Authentication::request_token();

This will generate a hash which the end-user must authenticate, this process is outlined in the official tmdb documentation.

L<https://www.themoviedb.org/documentation/api/sessions>

After the end-user authenticates you may use that request_token to generate a session.

	print $api->Authentication::session_new({
		'request_token' => '000000000000000000000000000000000'
	});

This should return:

	{"success":true,"session_id":"000000000000000000000000000000000"}

Otherwise you can generate a guest session as such, but you will only be able to rate movies with it.

	print $api->Authentication::guest_session_new();

=head2 Methods

=head3 Basic Methods

=head4 api_key

Sets your API Key.

	$api->api_key('000000000000000000000000000000000');

=head4 type

Sets the type of data you want to retrieve. 

I<Default value:> json

I<Available values:> json

	$api->type('json');

=head4 language

Sets the language based on ISO 639-1 Language Codes.

I<Default value:> en

I<Available values:> various

	$api->language('en');

=head4 version

Sets the API version.

I<Default value:> 3

I<Available values:> 3

	$api->version('3');

=head4 request_token

Sets the request token generated from Authentication.

	$api->request_token('000000000000000000000000000000000');

=head4 session_id

Sets the session id generated from Authentication.

	$api->session_id('000000000000000000000000000000000');

=head4 guest_session_id

Sets the guest session id generated from Authentication.

	$api->guest_session_id('000000000000000000000000000000000');

=head4 user_id

Sets the user id.

	$api->user_id('xxxxx');

=head3 Configuration

L<http://docs.themoviedb.apiary.io/#configuration>

=head4 Configuration::configuration

Get the system wide configuration information. Some elements of the API require some knowledge of this configuration 
data. The purpose of this is to try and keep the actual API responses as light as possible. It is recommended you 
store this data within your application and check for updates every so often.

	print $api->Configuration::configuration();

=head3 Authentication

L<http://docs.themoviedb.apiary.io/#authentication>

Instructions for using the request_token and session_id listed below are available here: L<https://www.themoviedb.org/documentation/api/sessions>

=head4 Authentication::request_token

This method is used to generate a valid request token for user based authentication. A request token is required in order to request a session id.
This token must be authenticated by the user via: http://www.themoviedb.org/authenticate/generated_request_token

	print $api->Authentication::request_token();

=head4 Authentication::session_new

This method is used to generate a session id for user based authentication. A session id is required in order to use any of the write methods.

	print $api->Authentication::session_new({
		'request_token' => '000000000000000000000000000000000'
	});

I<Required Parameters>

=over 1

=item *

request_token

The request token parameter is the token you generated for the user to approve. The token needs to be approved by the user before being used here. You can read more about this L<http://www.themoviedb.org/documentation/api/sessions>.

=back

=head4 Authentication::guest_session_new

This method is used to generate a guest session id.

A guest session can be used to rate movies without having a registered TMDb user account. You should only generate a 
single guest session per user (or device) as you will be able to attach the ratings to a TMDb user account in the 
future. There is also IP limits in place so you should always make sure it's the end user doing the guest session actions.

If a guest session is not used for the first time within 24 hours, it will be automatically discarded.

	print $api->Authentication::guest_session_new();

=head3 Account

L<http://docs.themoviedb.apiary.io/#account>

=head4 Account::account

Get the basic information for an account. You will need to have a valid session id.

	print $api->Account::account();

I<Required Parameters>

=over 1

=item *

session_id

=back

=head4 Account::lists

Get the lists that you have created and marked as a favorite.

	print $api->Account::lists({
		'user_id' => '#####'
	});

Where id is your account id, which you can get from Account::account.

I<Required Parameters>

=over 1

=item *

session_id

=item *

user_id

ID for the user.

=back

I<Optional Parameters>

=over 1

=item *

page

Integer, default: 1

=item *

language

ISO 639-1 code, default: en

=back

=head4 Account::favorite_movies

Get the list of favorite movies for an account.

	print $api->Account::favorite_movies({
		'user_id' => '#####'
	});

OR

	$api->user_id('#####');
	print $api->Account::favorite_movies();

I<Required Parameters>

=over 1

=item *

session_id

=item *

user_id

ID of the user.

=back

I<Optional Parameters>

=over 1

=item *

page

Integer, default: 1

=item *

sort_by

Only "created_at" is currently supported.

=item *

sort_order

asc or desc, default: asc

=item *

language

ISO 639-1 code, default: en

=back

=head4 Account::favorite

Add or remove a movie to an accounts favorite list.

	print $api->Account::favorite({
		'user_id'  => '#####',
		'movie_id' => 550,
		'favorite' => 'true'
	});

I<Required Parameters>

=over 1

=item *

session_id

=item *

user_id

ID of the user.

=item *

movie_id

ID of the movie.

=item *

favorite

true or false

=back

=head4 Account::rated_movies

Get the list of rated movies (and associated rating) for an account.

	print $api->Account::rated_movies({
		'user_id' => '#####'
	});

OR

	$api->user_id('#####');
	print $api->Account::rated_movies();

I<Required Parameters>

=over 1

=item *

session_id

=item *

user_id

=back

I<Optional Parameters>

=over 1

=item *

language

ISO 639-1 code, default: en

=item *

page

Integer, default: 1

=item *

sort_by

Only "created_at" is currently supported.

=item *

sort_order

asc or desc, default: asc

=back

=head4 Account::movie_watchlist

Get the list of movies on an accounts watchlist.

	print $api->Account::movie_watchlist({
		'user_id' => '#####'
	});

I<Required Parameters>

=over 1

=item *

session_id

=item *

user_id

=back

I<Optional Parameters>

=over 1

=item *

page

Integer, default: 1

=item *

sort_by

Only "created_at" is currently supported.

=item *

sort_order

asc or desc, default: asc

=item *

language

ISO 639-1 code, default: en

=back

=head4 Account::modify_movie_watchlist

Add or remove a movie to an accounts watch list.

	print $api->Account::modify_movie_watchlist({
		'user_id'         => '#####',
		'movie_id'        => 550,
		'movie_watchlist' => 'true'
	});

I<Required Parameters>

=over 1

=item *

session_id

=item *

user_id

=item *

movie_id

=item *

movie_watchlist

true or false, default: true

=back

=head3 Movies

L<http://docs.themoviedb.apiary.io/#movies>

=head4 Movies::info

Get the basic movie information for a specific movie id.

	print $api->Movies::info({
		'movie_id' => 550
	});

I<Required Parameters>

=over 1

=item *

movie_id

=back

I<Optional Parameters>

=over 1

=item *

language

ISO 639-1 code, default: en

=back

=head4 Movies::alternative_titles

Get the alternative titles for a specific movie id.

	print $api->Movies::alternative_titles({
		'movie_id' => 550
	});

I<Required Parameters>

=over 1

=item *

movie_id

=back

I<Optional Parameters>

=over 1

=item *

country

ISO 3166-1 code.

=back

=head4 Movies::casts

Get the cast information for a specific movie id.

	print $api->Movies::casts({
		'movie_id' => 550
	});

=head4 Movies::images

Get the images (posters and backdrops) for a specific movie id.

	print $api->Movies::images({
		'movie_id' => 550
	});

I<Required Parameters>

=over 1

=item *

movie_id

=back

I<Optional Parameters>

=over 1

=item *

language

ISO 639-1 code, default: en

=back

=head4 Movies::keywords

Get the plot keywords for a specific movie id.

	print $api->Movies::keywords({
		'movie_id' => 550
	});

I<Required Parameters>

=over 1

=item *

movie_id

=back

=head4 Movies::releases

Get the release date by country for a specific movie id.

	print $api->Movies::releases({
		'movie_id' => 550
	});

I<Required Parameters>

=over 1

=item *

movie_id

=back

=head4 Movies::trailers

Get the trailers for a specific movie id.

	print $api->Movies::trailers({
		'movie_id' => 550
	});

I<Required Parameters>

=over 1

=item *

movie_id

=back

=head4 Movies::translations

Get the translations for a specific movie id.

	print $api->Movies::translations({
		'movie_id' => 550
	});

I<Required Parameters>

=over 1

=item *

movie_id

=back

=head4 Movies::similar_movies

Get the similar movies for a specific movie id.

	print $api->Movies::similar_movies({
		'movie_id' => 550
	});

I<Required Parameters>

=over 1

=item *

movie_id

=back

I<Optional Parameters>

=over 1

=item *

page

Integer, default: 1

=item *

language

ISO 639-1 code, default: en

=back

=head4 Movies::reviews

Get the reviews for a particular movie id.

	print $api->Movies::reviews({
		'movie_id' => 68734
	});

I<Required Parameters>

=over 1

=item *

movie_id

=back

I<Optional Parameters>

=over 1

=item *

page

Integer, default: 1

=item *

language

ISO 639-1 code, default: en

=back

=head4 Movies::lists

Get the lists that the movie belongs to.

	print $api->Movies::lists({
		'movie_id' => 550
	});

I<Required Parameters>

=over 1

=item *

movie_id

=back

I<Optional Parameters>

=over 1

=item *

page

Integer, default: 1

=item *

language

ISO 639-1 code, default: en

=back

=head4 Movies::changes

Get the changes for a specific movie id.

Changes are grouped by key, and ordered by date in descending order. By default, only the last 24 hours of changes are returned. 
The maximum number of days that can be returned in a single request is 14. The language is present on fields that are translatable.

	print $api->Movies::lists({
		'movie_id' => 550
	});

I<Required Parameters>

=over 1

=item *

movie_id

=back

I<Optional Parameters>

=over 1

=item *

start_date

YYYY-MM-DD

=item *

end_date

YYYY-MM-DD

=back

=head4 Movies::latest

Get the latest movie id.

	print $api->Movies::latest();

=head4 Movies::upcoming

Get the list of upcoming movies. This list refreshes every day. The maximum number of items this list will include is 100.

	print $api->Movies::upcoming();

I<Optional Parameters>

=over 1

=item *

page

Integer, default: 1

=item *

language

ISO 639-1 code, default: en

=back

=head4 Movies::now_playing

Get the list of movies playing in theatres. This list refreshes every day. The maximum number of items this list will include is 100.

	print $api->Movies::now_playing();

I<Optional Parameters>

=over 1

=item *

page

Integer, default: 1

=item *

language

ISO 639-1 code, default: en

=back

=head4 Movies::popular

Get the list of popular movies on The Movie Database. This list refreshes every day.

	print $api->Movies::popular();

I<Optional Parameters>

=over 1

=item *

page

Integer, default: 1

=item *

language

ISO 639-1 code, default: en

=back

=head4 Movies::top_rated

Get the list of top rated movies. By default, this list will only include movies that have 10 or more votes. This list refreshes every day.

	print $api->Movies::top_rated();

I<Optional Parameters>

=over 1

=item *

page

Integer, default: 1

=item *

language

ISO 639-1 code, default: en

=back

=head4 Movies::account_states

This method lets users get the status of whether or not the movie has been rated or added to their favourite or watch lists. A valid session id is required.

	print $api->Movies::account_states();

I<Required Parameters>

=over 1

=item *

session_id

=back

=head4 Movies::rate

This method lets users rate a movie. A valid session id or guest session id is required.

	print $api->Movies::rate({
		'movie_id' => 550,
		'value' => '9.5'
	});

I<Required Parameters>

=over 1

=item *

session_id

=item *

guest_session_id

=item *

movie_id

=item *

value

Available values: 0, 0.5, 1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5, 5.5, 6, 6.5, 7, 7.5, 8, 8.5, 9, 9.5, 10

=back

=head3 Collections

L<http://docs.themoviedb.apiary.io/#collections>

=head4 Collections::info

Get the basic collection information for a specific collection id. You can get the ID needed for this method by making a /movie/{id} request and paying attention to the belongs_to_collection hash.

Movie parts are not sorted in any particular order. If you would like to sort them yourself you can use the provided release_date.

	print Collections::info();

I<Optional Parameters>

=over 1

=item *

language

ISO 639-1 code, default: en

=back

=head4 Collections::images

Get all of the images for a particular collection by collection id.

	print Collections::images();

I<Optional Parameters>

=over 1

=item *

language

ISO 639-1 code, default: en

=back

=head3 People

L<http://docs.themoviedb.apiary.io/#people>

=head4 People::info

Get the general person information for a specific id.

	print $api->People::info({
		'person_id' => 819
	});

I<Required Parameters>

=over 1

=item *

person_id

=back

=head4 People::credits

Get the credits for a specific person id.

	print $api->People::credits({
		'person_id' => 819
	});

I<Required Parameters>

=over 1

=item *

person_id

=back

I<Optional Parameters>

=over 1

=item *

language

ISO 639-1 code, default: en

=back

=head4 People::images

Get the images for a specific person id.

	print $api->People::images({
		'person_id' => 819
	});

I<Required Parameters>

=over 1

=item *

person_id

=back

=head4 People::changes

Get the changes for a specific person id.

Changes are grouped by key, and ordered by date in descending order. By default, only the last 24 hours of changes are returned. The maximum 
number of days that can be returned in a single request is 14. The language is present on fields that are translatable.

	print $api->People::changes({
		'person_id' => 819
	});

I<Required Parameters>

=over 1

=item *

person_id

=back

I<Optional Parameters>

=over 1

=item *

start_date

YYYY-MM-DD

=item *

end_date

YYYY-MM-DD

=back

=head4 People::popular

Get the list of popular people on The Movie Database. This list refreshes every day.

	print $api->People::popular();

I<Optional Parameters>

=over 1

=item *

page

Integer, default: 1

=back

=head4 People::latest

Get the latest person id.

	print $api->People::latest();

=head3 Lists

L<http://docs.themoviedb.apiary.io/#lists>

=head4 Lists::info 

Get a list by id.

	print $api->Lists::info({
		'list_id' => '###'
	});

I<Required Parameters>

=over 1

=item *

list_id

=back

=head4 Lists::item_status

Check to see if a movie ID is already added to a list.

	print $api->Lists::item_status({
		'list_id' => '###'
	});

I<Required Parameters>

=over 1

=item *

list_id

=item *

movie_id

=back

=head4 Lists::create

This method lets users create a new list. A valid session id is required.

	print $api->Lists::create({
		'name' => 'My New List',
		'description' => 'Blah blah blah.'
	});

I<Required Parameters>

=over 1

=item *

session_id

=item *

name

Name of the list.

=item *

description

Description of the list

=back

I<Optional Parameters>

	language

	ISO 639-1 code, default: en

=head4 Lists::add_item

This method lets users add new movies to a list that they created. A valid session id is required.

	print $api->Lists::add_item({
		'movie_id' => 550,
		'list_id'  => '###'
	});

I<Required Parameters>

=over 1

=item *

session_id

=item *

list_id

=item *

movie_id

=back

=head4 Lists::remove_item

This method lets users delete movies from a list that they created. A valid session id is required.

	print $api->Lists::remove_item({
		'movie_id' => 550,
		'list_id'  => '###'
	});

I<Required Parameters>

=over 1

=item *

session_id

=item *

list_id

=item *

movie_id

=back

=head4 Lists::delete

This method lets users delete a list that they created. A valid session id is required.

	print $api->Lists::delete({
		'list_id' => '###'
	});

I<Required Parameters>

=over 1

=item *

session_id

=item *

list_id

=back

=head3 Companies

L<http://docs.themoviedb.apiary.io/#companies>

=head4 Companies::info

This method is used to retrieve all of the basic information about a company.

	print $api->Companies::info({
		'company_id'=>1632
	});

I<Required Parameters>

=over 1

=item *

company_id

=back

=head4 Companies::movies

Get the list of movies associated with a particular company.

	print $api->Companies::movies({
		'company_id'=>1632
	});

I<Required Parameters>

=over 1

=item *

company_id

=back

I<Optional Parameters>

=over 1

=item *

page

Integer, default: 1

=item *

language

ISO 639-1 code, default: en

=back

=head3 Genres

L<http://docs.themoviedb.apiary.io/#genres>

=head4 Genres::list

Get the list of genres.

	print $api->Genres::list();

I<Optional Parameters>

=over 1

=item *

language

ISO 639-1 code, default: en

=back

=head4 Genres::movies

Get the list of movies for a particular genre by id. By default, only movies with 10 or more votes are included.

	print $api->Genres::movies({
		'genre_id'=>28
	});

I<Required Parameters>

=over 1

=item *

genre_id

=back

I<Optional Parameters>

=over 1

=item *

page

Integer, default: 1

=item *

language

ISO 639-1 code, default: en

=item *

include_all_movies

Toggle the inclusion of all movies and not just those with 10 or more ratings. true or false, default: false

=item *

include_adult

Include adult movies, true or false, default: false

=back

=head3 Keywords

L<http://docs.themoviedb.apiary.io/#keywords>

=head4 Keywords::info

Get the basic information for a specific keyword id.

	print $api->Keywords::info({
		'keyword_id'=>1541
	});

I<Required Parameters>

=over 1

=item *

keyword_id

=back

=head4 Keywords::movies

Get the list of movies for a particular keyword by id.

	print $api->Keywords::movies({
		'keyword_id'=>1541
	});

I<Required Parameters>

=over 1

=item *

keyword_id

=back

I<Optional Parameters>

=over 1

=item *

page

Integer, default: 1

=item *

language

ISO 639-1 code, default: en

=back

=head3 Discover

L<http://docs.themoviedb.apiary.io/#discover>

=head4 Discover::movie

Discover movies by different types of data like average rating, number of votes, genres and certifications.

	print $api->Discover::movie();

	print $api->Discover::movie({
		'sort_by' => 'popularity.desc',
		'certification_country' => 'us'
	});

I<Optional Parameters>

=over 1

=item *

page

Integer, default: 1

=item *

sort_by

Available options are vote_average.desc, vote_average.asc, release_date.desc, 
release_date.asc, popularity.desc, popularity.asc

=item *

include_adult

Toggle the inclusion of adult titles. Expected value is a boolean, true or false

=item *

year

Filter the results release dates to matches that include this value. Expected value is a year.

=item *

primary_release_year

Filter the results so that only the primary release date year has this value. Expected value is a year.

=item *

vote_count.gte

Only include movies that are equal to, or have a vote count higher than this value. Expected value is an integer.

=item *

vote_average.gte

Only include movies that are equal to, or have a higher average rating than this value. Expected value is a float.

=item *

with_genres

Only include movies with the specified genres. Expected value is an integer (the id of a genre). Multiple values 
can be specified. Comma separated indicates an 'AND' query, while a pipe (|) separated value indicates an 'OR'.

=item *

release_date.gte

The minimum release to include. Expected format is YYYY-MM-DD.

=item *

release_date.lte

The maximum release to include. Expected format is YYYY-MM-DD.

=item *

certification_country

Only include movies with certifications for a specific country. When this value is specified, 'certification.lte' 
is required. A ISO 3166-1 is expected.

=item *

certification.lte

Only include movies with this certification and lower. Expected value is a valid certification for the specificed 
'certification_country'.

=item *

with_companies

Filter movies to include a specific company. Expected valu is an integer (the id of a company). They can be comma 
separated to indicate an 'AND' query.

=back

=head3 Search

L<http://docs.themoviedb.apiary.io/#search>

=head4 Search::movie

Search for movies by title.

	print $api->Search::movie({
		'query' => 'The%20Big'
	});

I<Required Parameters>

query
CGI escaped string

I<Optional Parameters>

=over 1

=item *

page

Integer, default: 1

=item *

language

ISO 639-1 code, default: en

=item *

include_adult

Toggle the inclusion of adult titles. Expected value is: true or false

=item *

year

Filter the results release dates to matches that include this value.

=item *

primary_release_year

Filter the results so that only the primary release dates have this value.

=item *

search_type

By default, the search type is 'phrase'. This is almost guaranteed the option 
you will want. It's a great all purpose search type and by far the most tuned 
for every day querying. For those wanting more of an "autocomplete" type search, 
set this option to 'ngram'.

=back

=head4 Search::collection

Search for collections by name.

	print $api->Search::collection({
		'query' => 'The%20Big'
	);

I<Required Parameters>

=over 1

=item *

query

CGI escaped string

=back

I<Optional Parameters>

=over 1

=item *

page

Integer, default: 1

=item *

language

ISO 639-1 code, default: en

=item *

include_adult

Toggle the inclusion of adult titles. Expected value is: true or false

=item *

year

Filter the results release dates to matches that include this value.

=item *

primary_release_year

Filter the results so that only the primary release dates have this value.

=item *

search_type

By default, the search type is 'phrase'. This is almost guaranteed the option you 
will want. It's a great all purpose search type and by far the most tuned for every 
day querying. For those wanting more of an "autocomplete" type search, set this 
option to 'ngram'.

=back

=head4 Search::person

Search for people by name.

	print $api->Search::name({
		'query' => 'Edward%20Norton'
	);

I<Required Parameters>

=over 1

=item *

query

CGI escaped string

=back

I<Optional Parameters>

=over 1

=item *

page

Integer, default: 1

=item *

include_adult

Toggle the inclusion of adult titles. Expected value is: true or false

=item *

search_type

By default, the search type is 'phrase'. This is almost guaranteed the option you will want. It's a great all purpose search type and by far the most tuned for every day querying. For those wanting more of an "autocomplete" type search, set this option to 'ngram'.

=back

=head4 Search::list

Search for lists by name and description.

	$api->Search::list({
		'query' => 'Test'
	});

I<Required Parameters>

=over 1

=item *

query

CGI escaped string

=back

I<Optional Parameters>

=over 1

=item *

page

Integer, default: 1

=item *

include_adult

Toggle the inclusion of adult lists.

=back

=head4 Search::company

Search for companies by name.

	print $api->Search::company({
		'query' => 'Lionsgate'
	});

I<Required Parameters>

=over 1

=item *

query

CGI escaped string

=back

I<Optional Parameters>

=over 1

=item *

page

Integer, default: 1

=back

=head4 Search::keyword

Search for keywords by name.

	print $api->Search::keyword({
		'query' => 'nihilism'
	});

I<Required Parameters>

=over 1

=item *

query

CGI escaped string

=back

I<Optional Parameters>

=over 1

=item *

page

Integer, default: 1

=back

=head3 Reviews

L<http://docs.themoviedb.apiary.io/#reviews>

=head4 Reviews::info

Get the full details of a review by ID.

	print $api->Reviews::info({
		'review_id' => '51c2850e760ee359400fda6d'
	});

I<Required Parameters>

=over 1

=item *

review_id

ID of the review

=back

=head3 Changes

L<http://docs.themoviedb.apiary.io/#changes>

=head4 Changes::movie

Get a list of movie ids that have been edited. By default we show the last 24 hours and only 100 items per page. The maximum number of days that can be returned in a single request is 14. You can then use the movie changes API to get the actual data that has been changed.

Please note that the change log system to support this was changed on October 5, 2012 and will only show movies that have been edited since.

	print $api->Changes::movie();

I<Optional Parameters>

=over 1

=item *

page

Integer, default: 1

=item *

start_date

YYYY-MM-DD

=item *

end_date

YYYY-MM-DD

=back

=head4 Changes::person

Get a list of people ids that have been edited. By default we show the last 24 hours and only 100 items per page. The maximum number of days that can be returned in a single request is 14. You can then use the person changes API to get the actual data that has been changed.

Please note that the change log system to support this was changed on October 5, 2012 and will only show people that have been edited since.

	print $api->Changes::person();

I<Optional Parameters>

=over 1

=item *

page

Integer, default: 1

=item *

start_date

YYYY-MM-DD

=item *

end_date

YYYY-MM-DD

=back

=head3 Jobs

L<http://docs.themoviedb.apiary.io/#jobs>

=head4 Jobs::list

Get a list of valid jobs.

	print $api->Jobs::list();

=head1 PREREQUISITES

WWW::TheMovieDB requires the following modules:

L<HTTP::Request|HTTP::Request>

L<LWP::UserAgent|LWP::UserAgent>

L<URI::Escape|URI::Escape>

L<JSON|JSON>

=head1 REFERENCE

Full TheMovieDB API Documentation: L<http://docs.themoviedb.apiary.io/>

API Key Sign-Up: L<https://www.themoviedb.org/account/signup>

ISO 639-1 Language Codes: L<https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes>

ISO 3166-1 Country Codes: L<https://en.wikipedia.org/wiki/List_of_ISO_3166-1_codes#Current_codes>

=head1 AUTHOR

Paul Jobson, E<lt>pjobson@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Paul Jobson

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
