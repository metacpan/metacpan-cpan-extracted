package WWW::TheMovieDB::Search;

use 5.008009;
use strict;
use warnings;
use LWP::Simple;
use URI::Escape;
use Switch;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use WWW::TheMovieDB::Search ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	Movie_getInfo
	Movie_browse
	Movie_getImages
	Movie_getLatest
	Movie_getTranslations
	Movie_getVersion
	Movie_imdbLookup
	Movie_search
	Person_getInfo
	Person_getLatest
	Person_getVersion
	Person_search
	Genres_getList
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

our $VERSION = '0.04';


sub new {
	my $package = shift;
	
	$package::key	= '';
	$package::lang	= 'en';	
	$package::ver	= '2.1';
	$package::type	= 'xml';
	$package::uri	= 'http://api.themoviedb.org';
	
	if ($_[0]) {
		$package->key($_[0]);
	}
	
	return bless({}, $package);
}

sub lang {
	my $package = shift;
	$package::lang = shift;
	return;
}

sub ver {
	my $package = shift;
	$pacakge::ver = shift;
	return;
}

sub key {
	my $package = shift;
	$package::key = shift;
	return;
}

sub type {
	my $package = shift;
	$package::type = shift;
	return;
}

sub buildURL {
	my ($package,$method) = @_;
	
	my $url = $package::uri ."/". $package::ver ."/". $method ."/". $package::lang ."/". $package::type ."/". $package::key;
	
	return $url;
}

sub Movie_browse {
	my ($package,%data) = @_;
	
	
	my $url  = $package->buildURL("Movie.browse");
	$url .= "?";
	
	unless ((exists $data{'order'} && $data{'order'} =~ m/^(asc|desc)$/) && (exists $data{'order_by'} && $data{'order_by'} =~ m/^(rating|release|title)$/)) {
		return "Missing order and/or order_by.";
	}
	
	foreach my $key (sort keys %data) {
		$url .= '&order='.				$data{'order'}				if ($key eq 'order');
		$url .= '&order_by='.			$data{'order_by'}			if ($key eq 'order_by');
		
		$url .= '&certifications='.		$data{'certifications'}		if ($key eq 'certifications'	&& $data{'certifications'} ne "");
		$url .= '&companies='.			$data{'companies'}			if ($key eq 'companies'			&& $data{'companies'} =~ m/(\d+,)*\d+$/);
		$url .= '&countries='.			$data{'countries'}			if ($key eq 'countries'			&& $data{'countries'} ne "");
		$url .= '&genres='.				$data{'genres'}				if ($key eq 'genres'			&& $data{'genres'} =~ m/(\d+,)*\d+$/);
		$url .= '&genres_selector='.	$data{'genres_selector'}	if ($key eq 'genres_selector'	&& $data{'genres_selector'} =~ m/^(and|or)$/);
		$url .= '&min_votes='.			$data{'min_votes'}			if ($key eq 'min_votes'			&& $data{'min_votes'} =~ m/^(\d+)$/);
		$url .= '&page='.				$data{'page'}				if ($key eq 'page'				&& $data{'page'} =~ m/^\d+$/);
		$url .= '&per_page='.			$data{'per_page'}			if ($key eq 'per_page'			&& $data{'per_page'} =~ m/^\d+$/);
		$url .= '&query='.				uri_escape($data{'query'})	if ($key eq 'query'				&& $data{'query'} ne "");
		$url .= '&rating_max='.			$data{'rating_max'}			if ($key eq 'rating_max'		&& $data{'rating_max'} =~ m/^\d*\.{0,1}\d+$/);
		$url .= '&rating_min='.			$data{'rating_min'}			if ($key eq 'rating_min'		&& $data{'rating_min'} =~ m/^\d*\.{0,1}\d+$/);
		$url .= '&release_max='.		$data{'release_max'}		if ($key eq 'release_max'		&& $data{'release_max'} =~ m/^-{0,1}\d+$/);
		$url .= '&release_min='.		$data{'release_min'}		if ($key eq 'release_min'		&& $data{'release_min'} =~ m/^-{0,1}\d+$/);
		$url .= '&year='.				$data{'year'}				if ($key eq 'year'				&& $data{'year'} =~ m/^\d+$/);
	}
	
	
	my $content = get($url) || "";
	return $content;
}

sub Movie_getImages {
	my ($package,$movieid) = @_;

	my $url  = $package->buildURL("Movie.getImages");
	$url .= "/". $movieid;
	my $content = get($url) || "";
	return $content;
}

sub Movie_getInfo {
	my ($package,$movieid) = @_;
	
	my $url  = $package->buildURL("Movie.getInfo");
	$url .= "/". $movieid;
	my $content = get($url) || "";
	
	return $content;
}

sub Movie_getLatest {
	my $package = shift;
	
	my $url  = $package->buildURL("Movie.getLatest");

	print $url;
	my $content = get($url) || "";
	
	return $content;
}

sub Movie_getTranslations {
	my ($package,$movieid) = @_;
	
	my $url  = $package->buildURL("Movie.getTranslations");
	$url .= "/". $movieid;
	my $content = get($url) || "";
	
	return $content;
}

sub Movie_getVersion {
	my ($package,$movieid) = @_;
	
	my $url  = $package->buildURL("Movie.getVersion");
	$url .= "/". $movieid;
	my $content = get($url) || "";
	
	return $content;
}

sub Movie_imdbLookup {
	my ($package,$imdbid) = @_;
	
	my $url  = $package->buildURL("Movie.imdbLookup");
	$url .= "/". $imdbid;
	my $content = get($url) || "";
	
	return $content;
}

sub Movie_search {
	my ($package,$query) = @_;
	$query = uri_escape($query);
	
	my $url  = $package->buildURL("Movie.search");
	$url .= "/". $query;
	
	my $content = get($url) || "";
	
	return $content;
}

sub Person_getInfo {
	my ($package,$personid) = @_;
	
	my $url  = $package->buildURL("Person.getInfo");
	$url .= "/". $personid;
	
	my $content = get($url) || "";
	
	return $content;
}

sub Person_getLatest {
	my $package = shift;
	
	my $url  = $package->buildURL("Person.getLatest");

	print $url;
	my $content = get($url) || "";
	
	return $content;
	
}

sub Person_getVersion {
	my ($package,$personid) = @_;
	
	my $url  = $package->buildURL("Person.getInfo");
	$url .= "/". $personid;
	
	my $content = get($url) || "";
	
	return $content;
}

sub Person_search {
	my ($package,$query) = @_;
	$query = uri_escape($query);
	
	my $url  = $package->buildURL("Person.search");
	$url .= "/". $query;
	
	my $content = get($url) || "";
	
	return $content;
}

sub Genres_getList {
	my $package = shift;
	
	my $url = $package->buildURL("Genres.getList");
	
	my $content = get($url) || "";
	
	return $content;
}


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

WWW::TheMovieDB::Search - Perl client to the TMDb API C<< <http://api.themoviedb.org/2.1> >>

=head1 SYNOPSIS

A TMDb Search client.

=head1 DESCRIPTION

WARNING -- September 15, 2013 -- THE 2.1 API WILL BE DEPRECATED AND THIS MODULE WILL BE USELESS.

Good News -- This module has been replaced, please use WWW::TheMovieDB 

This client lets you retrieve data from the TMDb API; I currently have not implemented methods to write to the API, I don't really plan on it, unless someone really wants the feature.

It requires that you have a TMDb API key, which you can generate by getting an account at C<< <http://api.themoviedb.org/2.1> >>.

=head1 NOTE

Most of this documentation is copied nearly verbatim from The Movie DB API documentation.

=head1 PUBLIC METHODS

=over 1

=item new( $key )

Returns a new instance of this class. You are able to pass your API Key here or using the key method.

	my $api = new WWW::TheMovieDB::Search;
	my $api = new WWW::TheMovieDB::Search('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');

=item lang( $lang )

Sets the search language type, default is en-US if none passed.

Primary language: 2-letter ISO-639 language code C<< <http://en.wikipedia.org/wiki/List_of_ISO_639-1_codes> >>

	$api->lang('en');
	$api->lang('en');
	$api->lang('es');
	$api->lang('fr');

=item ver( $version )

Sets the version of the API to use, default is 2.1 if none passed.

	$api->ver('2.1');

=item key( $key )

Sets or changes the API key to use.

	$api->key('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');

=item type( $type )

Sets the datatype to be returned, default is xml.

	$api->type('xml');
	$api->type('yaml');
	$api->type('json');

=item Movie_browse( %data )

C<< <http://api.themoviedb.org/2.1/methods/Movie.browse> >>

The Movie_browse method is probably the most powerful single method on the entire TMDb API. While it might not be used by all apps, it is a great place to start if you're interested in building any kind of a top 10 list.

This method requires you pass two keys: 

=over 2

=item order_by

Three options: C<rating>, C<release>, C<title>

=item order

Two options: C<asc>, C<desc>

=back

You must also pass one or more of the following keys.

=over 2

=item page

Results are paginated if you use the page & per_page parameters. You can quickly scan through multiple pages with these options. Value is expected to be an integer.

=item per_page

This value sets the number of results to display per page (or request). Without it, the default is 30 results. Value is expected to be an integer.

=item query

The search query parameter is used to search for some specific text from a title.

=item min_votes

Only return movies with a certain minimum number of votes. Expected value is an integer.

=item rating_min

If you'd only like to see movies with a certain minimum rating, use this. It is expected to be a float value and if used, rating_max is required.

=item rating_max

Used in conjunction with rating_min. Sets the upper limit of movies to return based on their rating. Expects this value to be a float.

=item genres

The genres parameter is to be passed the genres id(s) you want to search for. You can get these ids from the Genres_getList method. In the event you want to search for multiple genres, you have to pass the values as a comma separated value.

=item genres_selector

Two Options: C<and>, C<or>

Used when you search for more than 1 genre and useful to combine your genre searches.

=item release_min

Useful if you'd like to only search for movies from a particular date and on. If used, rating_max is required. The value is expected to be an epoch value.

=item release_max

Sets the upper date limit to search for. Like release_min this is expected to be an epoch value and if used, release_min is required.

=item year

If you'd only like to search for movies from a particular year, this if your option. Expects a single integer value.

=item certifications

Like genres, you can pass multiple values to this option. Comma separate them in this case. The values to be used here are the MPAA values like 'R' or 'PG-13'. When more than one value is passed, it is assumed to be an OR search.

=item companies

Useful if you'd like to find the movies from a particular studio. You can pass it more than one id which is expected to be comma separated. When more than one id is passed, it is assumed to be an OR search.

=item countries

If you'd like to limit your result set to movies from a particular country you can pass their 2 letter country code. You can pass more than one value and in this case make sure they are comma separated. When more than one id is passed, it is assumed to be an OR search.

=back
	
	# Returns all movies rated 10.
	my $data = $api->Movie_browse(
		order_by		=> 'rating',
		order			=> 'asc',
		rating_min		=> '10'
	);
	
	# Returns all movies containing "inception"
	my $data = $api->Movie_browse(
		order_by		=> 'rating',
		order			=> 'asc',
		query			=> 'inception'
	);


=item Movie_getImages( $movieid )

C<< <http://api.themoviedb.org/2.1/methods/Movie.getImages> >>

The Movie_getImages method is used to retrieve all of the backdrops and posters for a particular movie. This is useful to scan for updates, or new images if that's all you're after. No point on calling Movie_getInfo if you're only interested in images.

This method expects either a TMDb Movie ID or IMDB Movie ID.

	$api->Movie_getImages('550');
	$api->Movie_getImages('tt0137523');

=item Movie_getInfo( $movieid )

C<< <http://api.themoviedb.org/2.1/methods/Movie.getInfo> >>

The Movie_getInfo method is used to retrieve specific information about a movie. Things like overview, release date, cast data, genre's, YouTube trailer link, etc...

This method expects a TMDb Movie ID.

	$api->Movie_getInfo('550');

=item Movie_getLatest

C<< <http://api.themoviedb.org/2.1/methods/Movie.getLatest> >>

The Movie_getLatest method is a simple method. It returns the ID of the last movie created in the db. This is useful if you are scanning the database and want to know which id to stop at.

	$api->Movie_getLatest();

=item Movie_getTranslations( $movieid )

C<< <http://api.themoviedb.org/2.1/methods/Movie.getTranslations> >>

The Movie_getTranslations method will return the translations that a particular movie has. The languages returned can then be used with the Movie_search or Movie_getInfo methods. Remember though, just because the language was added to the movie it doesn't mean the data is complete.

This method expects a TMDb Movie ID.

	$api->Movie_getTranslations('550');

=item Movie_getVersion( $movieid )

C<< <http://api.themoviedb.org/2.1/methods/Movie.getVersion> >>

The Movie_getVersion method is used to retrieve the last modified time along with the current version number of the called object(s). This is useful if you've already called the object sometime in the past and simply want to do a quick check for updates. This method supports calling anywhere between 1 and 50 items at a time.

This method expects a single TMDb Movie ID or set of IDs.

	$api->Movie_getVersion('585');
	$api->Movie_getVersion('585,155,11,550');


=item Movie_imdbLookup( $imdbid )

C<< <http://api.themoviedb.org/2.1/methods/Movie.imdbLookup> >>

The Movie_imdbLookup method is the easiest and quickest way to search for a movie based on it's IMDb ID. You can use Movie.imdbLookup method to get the TMDb id of a movie if you already have the IMDB id.

This method expects an IMDB Movie ID.

	$api->Movie_imdbLookup('tt0137523');


=item Movie_search( $query )

C<< <http://api.themoviedb.org/2.1/methods/Movie.search> >>

The Movie_search method is the easiest and quickest way to search for a movie. It is a mandatory method in order to get the movie id to pass to (as an example) the Movie_getInfo method.

This method 

	$api->Movie_search('Transformers');
	$api->Movie_search('Transformers 2007');

=item Person_getInfo( $personid )

C<< <http://api.themoviedb.org/2.1/methods/Person.getInfo> >>

The Person_getInfo method is used to retrieve the full filmography, known movies, images and things like birthplace for a specific person in the TMDb database.

This method expects a TMDb Person ID.

	$api->Person_getInfo('500');


=item Person_getLatest

C<< <http://api.themoviedb.org/2.1/methods/Person.getLatest> >>

The Person_getLatest method is a simple method. It returns the ID of the last person created in the db. This is useful if you are scanning the database and want to know which id to stop at.

	$api->Person_getLatest();

=item Person_getVersion

C<< <http://api.themoviedb.org/2.1/methods/Person.getVersion> >>

The Person_getVersion method is used to retrieve the last modified time along with the current version number of the called object(s). This is useful if you've already called the object sometime in the past and simply want to do a quick check for updates. This method supports calling anywhere between 1 and 50 items at a time.

This method expects a single TMDb Person ID or set of IDs.

	$api->Person_getVersion('287');
	$api->Person_getVersion('287,5064,819');


=item Person_search( $query )

C<< <http://api.themoviedb.org/2.1/methods/Person.search> >>

The Person_search method is used to search for an actor, actress or production member.

This method expects a query.

	$api->Person_search('Brad Pitt');
	$api->Person_search('James Earl Jones');

=item Genres_getList

C<< <http://api.themoviedb.org/2.1/methods/Genres.getList> >>

The Genres_getList method is used to retrieve a list of valid genres within TMDb. You can also request the translated values by passing the language option.

	$api->Genres_getList();


=back


=head1 PRIVATE METHODS

=over 1

=item buildURL( $type )

Builds a URL based on type passed and set values from class, expects one of the following: Movie.browse, Movie.getImages, Movie.getInfo, Movie.getLatest, Movie.getTranslations, Movie.getVersion, Movie.imdbLookup, Movie.search, Person.getInfo, Person.getLatest, Person.getInfo, Person.search, Genres.getList

=back

=head1 AUTHOR

Paul Jobson, E<lt>pjobson@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Paul Jobson

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.


=cut
