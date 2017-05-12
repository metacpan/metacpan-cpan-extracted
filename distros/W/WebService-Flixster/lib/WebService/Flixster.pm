# $Id: Flixster.pm 7373 2012-04-09 18:00:33Z chris $

=head1 NAME

WebService::Flixster - OO Perl interface to flixster.com


=head1 SYNOPSIS


    use WebService::Flixster;

    my $ws = WebService::Flixster->new(cache => 1, cache_exp => "12h");

    my $movie = $ws->search(type => "Movie", tconst => "tt0033467");

    print $movie->title(), ": \n\n";
    print $movie->synopsis(), "\n\n";

=cut

package WebService::Flixster;

use strict;
use warnings;

our $VERSION = '0.02';

use base qw(Class::Accessor);

use Cache::FileCache;

use Carp;

use File::Spec::Functions qw(tmpdir);

use JSON;

use LWP::ConnCache;
use LWP::UserAgent;

use WebService::Flixster::Actor;
use WebService::Flixster::Movie;

use URI;

__PACKAGE__->mk_accessors(qw(
    _cache
    _cache_exp
    _cache_root
    _cache_obj
    _domain
    _useragent
));


=head1 METHODS

=head2 new(%opts)

Constructor.

%opts can contain:

=over 4

=item cache - Whether to cache responses.  Defaults to true

=item cache_root - The root dir for the cache.  Defaults to tmpdir();

=item cache_exp - How long to cache responses for.  Defaults to "1h"

=item domain - Domain from which to request data.  Defaults to "api.flixster.com"

=back

=cut

sub new {
    my $class = shift;
    my %args = @_;
    my $self = {};

    bless $self, $class;

    $self->_cache_root($args{'cache_root'} || tmpdir());
    $self->_cache_exp($args{'cache_exp'} || "1h");
    $self->_cache(defined $args{'cache'} ? $args{'cache'} : 1);

    $self->_domain($args{'domain'} || "api.flixster.com");

    if ($self->_cache()) {
	$self->_cache_obj( Cache::FileCache->new( {'cache_root' => $self->_cache_root(), 'namespace' => "WebService-Flixster", 'default_expires_in' => $self->_cache_exp()} ) );
    }

    $self->_useragent(LWP::UserAgent->new());
    $self->_useragent()->env_proxy();
    $self->_useragent()->agent("WebService::Flixster/$VERSION");
    $self->_useragent()->conn_cache(LWP::ConnCache->new());
    $self->_useragent()->conn_cache()->total_capacity(3);

    return $self;
}


=head2 search(%args)

%args can contain:

=over 4

=item type - Resource type: "Movie", "Actor"

=item id - Flixster id e.g. "10074" (Movie, Actor)

=item imdbid - IMDB tconst/nconst e.g. "tt0000001", "nm0000002" (Movie, Actor)

=back

=cut

sub search {
    my $self = shift;
    my $q = { @_ };

    if (!exists $q->{'type'}) {
	croak "TODO: Return generic resultset";
    } elsif ($q->{'type'} eq "Actor") {
	delete $q->{'type'};
	return WebService::Flixster::Actor->_new($self, $q);
    } elsif ($q->{'type'} eq "Movie") {
	delete $q->{'type'};
	return WebService::Flixster::Movie->_new($self, $q);
    } else {
	croak "Unknown resource type '" . $q->{'type'} . "'";
    }

}


sub _request_cache_key {
    my $request = shift;
    my $type = shift;

    my $version = "0"; # Use a version number as the first part of the key to avoid collisions should we change the structure of the key later.

    # Using | as field separator as this shouldn't ever appear in a URL (or any of the other fields).
    my $cache_key = $version . "|" . $type . "|" . $request->method() . "|" . $request->uri();
    if ($request->method() eq "POST") {
	$cache_key .= "|" . $request->content();
    }

    return $cache_key;
}

sub _response {
    my $self = shift;
    my $request = shift;
    my $cacheCodes = shift || {'404' => 1}; # Only cache 404 responses by default

    my $cache_key = _request_cache_key($request, "RESPONSE");

    my $response;

    if ($self->_cache()) {
	$response = $self->_cache_obj()->get($cache_key);
    }

    if (!defined $response) {
	$response = $self->_useragent()->request($request);

	if ($self->_cache() && exists $cacheCodes->{$response->code()}) {
 	    $self->_cache_obj()->set($cache_key, $response);
	}

    }

    return $response;

}

sub _response_decoded_content {
    my $self = shift;
    my $request = shift;

    my $saveToCache = shift;
    if (!defined $saveToCache) { $saveToCache = 1; }

    my $cache_key = _request_cache_key($request, "DECODED_CONTENT");

    my $content;

    if ($self->_cache()) {
	$content = $self->_cache_obj()->get($cache_key);
    }

    if (!defined $content) {

	my $response = $self->_response($request);

	if($response->code() ne "200") {
	    croak "URL (", $request->uri(), ") Request Failed - Code: ", $response->code(), " Error: ", $response->message(), "\n";
	}

	$content = $response->decoded_content();

	if ($self->_cache() && $saveToCache) {
	    $self->_cache_obj()->set($cache_key, $content);
	}
    }

    return $content;

}

sub _response_decoded_json {
    my $self = shift;
    my $request = shift;

    my $content = $self->_response_decoded_content($request);

    my $json = JSON->new();
    $json->utf8(0);

    my $resp = $json->decode($content);

    if (ref $resp eq "HASH" && exists $resp->{'error'}) { # Some pages (e.g. photos) return an array as the top level object.
	croak $resp->{'error'}->{'status'} . " " . $resp->{'error'}->{'code'} . ": " . $resp->{'error'}->{'message'};
    } else {
	return $resp;
    }

}

1;
