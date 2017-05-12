# $Id: MoviePosterDB.pm 6486 2011-06-13 13:42:02Z chris $

=head1 NAME

WebService::MoviePosterDB - OO Perl interface to the movie poster database MoviePosterDB.


=head1 SYNOPSIS

    use WebService::MoviePosterDB;

    my $ws = WebService::MoviePosterDB->new(api_key => "key", api_secret => "secret", cache => 1, cache_exp => "12h");

    my $movie = $ws->search(type => "Movie", imdbid => "tt0114814", width => 300);

    print $movie->title(), ": \n\n";
    print $movie->page(), "\n\n";

    foreach ( @{$movie->posters()} ) {
        print $_->image_location(), "\n";
    }


=head1 DESCRIPTION

WebService::MusicBrainz is an object-oriented interface to MoviePosterDB.  It can
be used to retrieve artwork for IMDB titles.

=cut


package WebService::MoviePosterDB;

use strict;
use warnings;

our $VERSION = '0.18';

use Cache::FileCache;

use Carp;

use Digest::MD5 qw(md5_hex);

use File::Spec::Functions qw(tmpdir);

use JSON;
use LWP::UserAgent;
use URI;

use WebService::MoviePosterDB::Movie;

=head1 METHODS

=head2 new(%opts)

Constructor.

%opts can contain:

=over 4

=item api_key, api_secret

A key and secret are required to use the API.  Contact movieposterdb.com for details.

=item cache

Whether to cache responses.  Defaults to true

=item cache_root

The root dir for the cache.  Defaults to tmpdir();

=item cache_exp

How long to cache responses for.  Defaults to "1h"

=back

=cut

sub new {
    my $class = shift;
    my %args = @_;
    my $self = {};

    bless $self, $class;

    if ((!exists $args{'api_version'} || !defined $args{'api_version'} || $args{'api_version'} == 1) && !exists $args{'api_key'}) {
	carp "version 1 API is no longer available, using demo credentials";
	$self->{'api_key'} = "demo";
	$self->{'api_secret'} = "demo";
    } else {
	$self->{'api_key'} = $args{'api_key'};
	$self->{'api_secret'} = $args{'api_secret'};
    }

    if (!defined $self->{'api_key'} || !defined $self->{'api_secret'}) {
	croak "api_key and/or api_secret missing";
    }

    $self->{'_cache_root'} = $args{'cache_root'} || tmpdir();
    $self->{'_cache_exp'} = $args{'cache_exp'} || "1h";
    $self->{'_cache'} = defined $args{'cache'} ? $args{'cache'} : 1;

    if ($self->{'_cache'}) {
	$self->{'_cacheObj'} = Cache::FileCache->new( {'cache_root' => $self->{'_cache_root'}, 'namespace' => "WebService-MoviePosterDB", 'default_expires_in' => $self->{'_cache_exp'}} );
    }

    $self->{'_useragent'} = LWP::UserAgent->new();
    $self->{'_useragent'}->env_proxy();
    $self->{'_useragent'}->agent("WebService::MoviePosterDB/$VERSION");

    return $self;
}


=head2 search(type => "Movie", %args)

Accesses MoviePosterDB and returns a WebService::MoviePosterDB::Movie object.

%args can contain:

=over 4

=item type

Controls the type of resource being requested.  Currently only supports "Movie".

=item tconst

IMDB id for the title, e.g. tt0114814

=item imdbid

Alias for tconst

=item title

Name of the title

=item width

Image width for returned artwork

=back

=cut

sub search {
    my $self = shift;
    my %args = @_;

    croak "Unknown type" unless ($args{'type'} eq "Movie");

    my %_args;

    if (exists $args{'imdb_code'}) {
	$_args{'imdb_code'} = sprintf("%d", $args{'imdb_code'}); # Trim leading zeroes
    } elsif (exists $args{'tconst'} || exists $args{'imdbid'}) {
	my $tconst = exists $args{'tconst'} ?  $args{'tconst'} : $args{'imdbid'};
	my ($id) = $tconst =~ m/^tt(\d{6,7})$/ or croak "Unable to parse tconst '$tconst'";
	$_args{'imdb_code'} = sprintf("%d", $id); # Trim leading zeroes
    }
    if (exists $args{'title'}) { $_args{'title'} = $args{'title'}; }
    if (exists $args{'width'}) { $_args{'width'} = $args{'width'}; }

    # Ugly hack.  The demi api service appears to normalise the title key to lower case before returning the secret hash.
    if (exists $_args{'title'} && $self->{'api_key'} eq "demo" && $self->{'api_secret'} eq "demo") { $_args{'title'} = lc $_args{'title'}; }

    $_args{'api_key'} = $self->{'api_key'};
    $_args{'secret'} = $self->_get_secret(%_args);

    my $uri = URI->new();
    $uri->scheme("http");
    $uri->host("api.movieposterdb.com");
    $uri->path("json");
    $uri->query_form( map { my ($n, $v) = ($_, $_args{$_}); utf8::encode($n); utf8::encode($v); ($n => $v); } sort keys %_args );

    my $json = JSON->new()->decode($self->_get_page($uri->as_string()));

    return WebService::MoviePosterDB::Movie->_new($json);

}

sub _get_secret {
    my $self = shift;
    my %args = @_;

    if ($self->{'api_key'} eq "demo" && $self->{'api_secret'} eq "demo") {

	my %_args;

	if (exists $args{'title'}) {$_args{'title'} = $args{'title'}; }
	if (exists $args{'imdb_code'}) {$_args{'imdb_code'} = $args{'imdb_code'}; }

	$_args{'type'} = "JSON";
	$_args{'api_key'} = $self->{'api_key'};
	$_args{'api_secret'} = $self->{'api_secret'};

	my $uri = URI->new();
	$uri->scheme("http");
	$uri->host("api.movieposterdb.com");
	$uri->path("console");
	$uri->query_form( map { my ($n, $v) = ($_, $_args{$_}); utf8::encode($n); utf8::encode($v); ($n => $v); } sort keys %_args );

	my $page = $self->_get_page($uri->as_string());
	my ($s) = $page =~ m/secret=([a-f0-9]{12})/ or die "Failed to extract secret";

	return $s;

    } else {
	my $v = $self->{'api_secret'};
	if (exists $args{'imdb_code'}) { $v .= sprintf("%d", $args{'imdb_code'}); }
	if (exists $args{'title'}) { $v .= $args{'title'}; }

	utf8::encode($v);

	return substr(md5_hex($v), 10, 12);
    }

}

sub _get_page {
    my $self = shift;
    my $url = shift;

    my $content;

    if ($self->{'_cache'}) {
	$content = $self->{'_cacheObj'}->get($url);
    }

    if (! defined $content) {
	my $response = $self->{'_useragent'}->get($url);

	if($response->code() ne "200") {
	    croak "URL (", $url, ") Request Failed - Code: ", $response->code(), " Error: ", $response->message(), "\n";
	}

	$content = $response->decoded_content();

	if ($self->{'_cache'}) {
	    $self->{'_cacheObj'}->set($url, $content);
	}
    }

    return $content;
}

1;


=head1 NOTES

The version 1 API, previously used by default, stopped as of 2011-09-27, and credentials
are required to access the version 2 API.  It is possible to access the
version 2 API using test credentials (key, secret = "demo"), and this will be
done for legacy applications that try to use the version 1 API.  However, this
feature is only intended for test purposes: legacy applications should be adapted,
and new applications should not use it.


=head1 AUTHOR

Christopher Key <cjk32@cam.ac.uk>


=head1 COPYRIGHT AND LICENCE

Copyright (C) 2010-2011 Christopher Key <cjk32@cam.ac.uk>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
