package WebService::Audioscrobbler::DataFetcher;
use warnings;
use strict;
use CLASS;
use base 'Class::Accessor::Fast';

use Cache::FileCache;
use URI;

require LWP::Simple;
require XML::Simple;

=head1 NAME

WebService::Audioscrobbler::DataFetcher - Cached data fetching provider

=cut

our $VERSION = '0.08';

# object accessors
CLASS->mk_accessors(qw/base_url cache_root cache/);

=head1 SYNOPSIS

This is responsible for fetching and caching all data requested from Audioscrobbler
WebServices, as recommended by their usage policy.

It can actually function as a generic XML-fetcher-and-converter-to-hashrefs and has
no limitations regarding being used only for Audioscrobbler WebServices. In the future,
it might even became a completely separate module.

    use WebService::Audioscrobbler::DataFetcher;

    my $data_fetcher = WebService::Audioscrobbler::DataFetcher->new(
        "http://www.my-base-url.com/base_dir/"
    );

    # retrieves "http://www.my-base-url.com/base_dir/myown/resource.xml"
    # and parses it through XML::Simple::XMLin so we get a hashref
    my $data = $data_fetcher->fetch("myown/resource.xml")

=cut

=head1 FIELDS

=head2 C<base_url>

This is the base URL from where data will be fetched.

=head2 C<cache>

This is the underlying cache object. By default, this will be a 
L<Cache::FileCache> object.

=head2 C<cache_root>

This is the root directory where the cache will be created. It should only be
set as a parameter to C<new()>, setting it afterwards won't have any effect.

=cut

=head1 METHODS

=cut

=head2 C<new($base_url)>

=head2 C<new(\%fields)>

Creates a new object using either the given C<$base_url> or the C<\%fields> 
hashref. Any of the above fields can be specified. If the C<cache> field is 
undefined, C<create_cache> will be called after object construction.

=cut

sub new {
    my $class = shift;
    my $base_or_params = shift;
    
    my $self = $class->SUPER::new(
        ref $base_or_params eq 'HASH' ? $base_or_params : { base_url => $base_or_params }
    );

    # base_url is mandatory
    $self->croak("base_url not set")
        unless defined $self->base_url;

    # guarantee it's an URI object
    $self->base_url(URI->new($self->base_url))
        unless $self->base_url->isa('URI');

    # crate a new cache object, unless we're already given one
    $self->create_cache unless $self->cache;

    return $self;
}

=head2 C<create_cache>

Creates a new L<Cache::FileCache> object and saves it in the C<cache> field.
The cache has a daily auto purging turned on and data will expire by default
in 3 days, which is reasonable since most of Audioscrobbler data changes at
most weekly. The cache root will be as specified by the C<cache_root> field 
(if it's undefined, L<Cache::FileCache> defaults will be used).

=cut

sub create_cache {
    my $self = shift;
    $self->cache(
        Cache::FileCache->new( {
            auto_purge_on_set   => 1,
            auto_purge_interval => 86400,  # 1 day
            default_expires_in  => 259200, # 3 days
            cache_root          => $self->cache_root
        } )
    )
}

=head2 C<fetch($resource)>

Actually fetches a XML resource URL. If the resource is not already cached, 
C<retrieve_data> is called it's results are then cached. The results are then
processed by C<XML::Simple::XMLin> so we end up with a nice hashref as our 
return value.

=cut

sub fetch {
    my ($self, $resource) = @_;
    
    # build and normalize the URL
    my $uri = $self->base_url->clone;
    $uri->path_segments(grep {length} $uri->path_segments, split '/', $resource);

    # try to fetch a cached copy of the data
    my $data = $self->cache->get($uri);

    # not in cache
    unless (defined $data) {
        my $resp = $self->retrieve_data($uri);
        
        # parse it into a hashref
        $data = XML::Simple::XMLin($resp);

        # cache it for future references
        $self->cache->set($uri, $data);
    }

    return $data;

}

=head2 C<retrieve_data($uri)>

Retrieves data from the specified $uri using L<LWP::Simple> and returns it.

=cut

sub retrieve_data {
    my ($self, $uri) = @_;
   
    # warn "\nRetrieving data from $uri...\n";
    
    my $resp = LWP::Simple::get($uri) 
        or $self->croak("Error while fetching data from '$uri'");

    utf8::upgrade($resp);

    return $resp;
}

=head2 C<croak>

Shortcut for C<Carp::croak> which can be called as a method.

=cut

sub croak {
    shift if $_[0]->isa(CLASS);
    require Carp;
    Carp::croak(@_);
}

=head1 AUTHOR

Nilson Santos Figueiredo Junior, C<< <nilsonsfj at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2006-2007 Nilson Santos Figueiredo Junior, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of WebService::Audioscrobbler::DataFetcher