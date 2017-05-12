# $Id: IMDB.pm 7370 2012-04-09 01:17:33Z chris $

=head1 NAME

WebService::IMDB - OO Perl interface to the Internet Movie Database imdb.com


=head1 SYNOPSIS


    use WebService::IMDB;

    my $ws = WebService::IMDB->new(cache => 1, cache_exp => "12h");

    my $movie = $ws->search(type => "Title", tconst => "tt0114814");

    print $movie->title(), ": \n\n";
    print $movie->synopsis(), "\n\n";

    foreach ( @{$movie->cast_summary()} ) {
        print $_->name()->name(), " : ", $_->char(), "\n";
    }


=head1 LEGAL

The data accessed via this API is provided by IMDB, and is currently supplied
with the following copyright notice.

=over 4

For use only by clients authorized in writing by IMDb.  Authors and users of unauthorized clients accept full legal exposure/liability for their actions.

=back

Anyone using WebService::IMDB must abide by the above requirements.

=cut

package WebService::IMDB;

use strict;
use warnings;

our $VERSION = '0.05';

use base qw(Class::Accessor);

use Cache::FileCache;

use Carp;

use File::Spec::Functions qw(tmpdir);

use HTTP::Request::Common;

use JSON;

use LWP::ConnCache;
use LWP::UserAgent;

use WebService::IMDB::Title;
use WebService::IMDB::Name;

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

=item domain - Domain from which to request data.  Defaults to "app.imdb.com"

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

    $self->_domain($args{'domain'} || "app.imdb.com");

    if ($self->_cache()) {
	$self->_cache_obj( Cache::FileCache->new( {'cache_root' => $self->_cache_root(), 'namespace' => "WebService-IMDB", 'default_expires_in' => $self->_cache_exp()} ) );
    }

    $self->_useragent(LWP::UserAgent->new());
    $self->_useragent()->env_proxy();
    $self->_useragent()->agent($args{'agent'} || "WebService::IMDB/$VERSION");
    $self->_useragent()->conn_cache(LWP::ConnCache->new());
    $self->_useragent()->conn_cache()->total_capacity(3);

    return $self;
}


=head2 search(%args)

%args can contain:

=over 4

=item type - Resource type: "Title", "Name

=item tconst - IMDB tconst e.g. "tt0000001" (Title)

=item nconst - IMDB nconst e.g. "nm0000002" (Name)

=item imdbid - More tolerant version of tconst, nconst e.g. "123", "0000456", "tt0000001", "nm0000002" (Title, Name)

=back

=cut

sub search {
    my $self = shift;
    my $q = { @_ };

    if (!exists $q->{'type'}) {
	croak "TODO: Return generic resultset";
    } elsif ($q->{'type'} eq "Title") {
	delete $q->{'type'};
	return WebService::IMDB::Title->_new($self, $q);
    } elsif ($q->{'type'} eq "Name") {
	delete $q->{'type'};
	return WebService::IMDB::Name->_new($self, $q);
    } else {
	croak "Unknown resource type '" . $q->{'type'} . "'";
    }

}

sub copyright {
    my $self = shift;

    my $request = GET sprintf("http://app.imdb.com/title/tt0033467/maindetails?ts=%d", time()); # Crude, use timestamp in query string to bypass our own caching

    return $self->_response_copyright($request);

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
    # TODO: Honour $resp->{'exp'}, and check $resp->{'copyright'}

    if (exists $resp->{'error'}) {
	croak $resp->{'error'}->{'status'} . " " . $resp->{'error'}->{'code'} . ": " . $resp->{'error'}->{'message'};
    } elsif (exists $resp->{'data'}) {
	return $resp->{'data'};
    } elsif (exists $resp->{'news'}) {
	return $resp->{'news'};
    } else {
	croak "Failed to parse response";
    }

}

sub _response_copyright {
    my $self = shift;
    my $request = shift;

    my $content = $self->_response_decoded_content($request);

    my $json = JSON->new();
    $json->utf8(0);

    my $resp = $json->decode($content);

    return $resp->{'copyright'};

}

1;
