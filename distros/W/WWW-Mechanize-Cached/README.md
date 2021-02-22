# NAME

WWW::Mechanize::Cached - Cache response to be polite

# VERSION

version 1.55

# SYNOPSIS

    use WWW::Mechanize::Cached;

    my $cacher = WWW::Mechanize::Cached->new;
    $cacher->get( 'https://metacpan.org' );

    # or, with your own Cache object
    use CHI;
    use WWW::Mechanize::Cached;

    my $cache = CHI->new(
        driver   => 'File',
        root_dir => '/tmp/mech-example'
    );

    my $mech = WWW::Mechanize::Cached->new( cache => $cache );
    $mech->get("http://www.wikipedia.org");

# DESCRIPTION

Uses the [Cache::Cache](https://metacpan.org/pod/Cache%3A%3ACache) hierarchy by default to implement a caching Mech. This
lets one perform repeated requests without hammering a server impolitely.
Please note that [Cache::Cache](https://metacpan.org/pod/Cache%3A%3ACache) has been superseded by [CHI](https://metacpan.org/pod/CHI), but the default
has not been changed here for reasons of backwards compatibility.  For this
reason, you are encouraged to provide your own [CHI](https://metacpan.org/pod/CHI) caching object to
override the default.

# CONSTRUCTOR

## new

Behaves like, and calls, [WWW::Mechanize](https://metacpan.org/pod/WWW%3A%3AMechanize)'s `new` method. Any params, other
than those explicitly listed here are passed directly to WWW::Mechanize's
constructor.

You may pass in a `cache => $cache_object` if you wish. The
_$cache\_object_ must have `get()` and `set()` methods like the
`Cache::Cache` family.

The default Cache object is set up with the following params:

    my $cache_params = {
        default_expires_in => "1d", namespace => 'www-mechanize-cached',
    };

    $cache = Cache::FileCache->new( $cache_params );

This should be fine if you only want to use a disk-based cache, you only want
to cache results for 1 day and you're not in a shared hosting environment.
If any of this presents a problem for you, you should pass in your own Cache
object.  These defaults will remain unchanged in order to maintain backwards
compatibility.

For example, you may want to try something like this:

    use WWW::Mechanize::Cached;
    use CHI;

    my $cache = CHI->new(
        driver   => 'File',
        root_dir => '/tmp/mech-example'
    );

    my $mech = WWW::Mechanize::Cached->new( cache => $cache );
    $mech->get("http://www.wikipedia.org");

# METHODS

Most methods are provided by [WWW::Mechanize](https://metacpan.org/pod/WWW%3A%3AMechanize). See that module's
documentation for details.

## cache( $cache\_object )

Requires an caching object which has a get() and a set() method. Using the CHI
module to create your cache is the recommended way. See new() for examples.

## is\_cached()

Returns true if the current page is from the cache, or false if not. If it
returns `undef`, then you don't have any current request.

## positive\_cache( 0|1 )

As of v1.36 positive caching is enabled by default. Up to this point,
this module had employed a negative cache, which means it cached 404
responses, temporary redirects etc. In most cases, this is not what you want,
so the default behaviour now better reflects this. You can revert to the
negative cache quite easily:

    # cache everything (404s, all 300s etc)
    $mech->positive_cache( 0 );

## ref\_in\_cache\_key( 0|1 )

Allow the referring URL to be used when creating the cache key.  This is off
by default.  In almost all cases, you will not want to enable this, but it is
available to you for reasons of backwards compatibility and giving you enough
rope to hang yourself.

Previous to v1.36 the following was in the "BUGS AND LIMITATIONS" section:

    It may sometimes seem as if it's not caching something. And this may well
    be true. It uses the HTTP request, in string form, as the key to the cache
    entries, so any minor changes will result in a different key. This is most
    noticable when following links as L<WWW::Mechanize> adds a C<Referer>
    header.

See RT #56757 for a detailed example of the bugs this functionality can
trigger.

## cache\_undef\_content\_length( 0 | 'warn' | 1 )

This is configuration option which adjusts how caching behaviour performs when
the Content-Length header is not specified by the server.

Default behaviour is 0, which is not to cache.

Setting this value to 1, will cache pages even if the Content-Length header is
missing, which was the default behaviour prior to the addition of this feature.

And thirdly, you can set the value to the string 'warn', to warn if this
scenario occurs, and then not cache it.

## cache\_zero\_content\_length( 0 | 'warn' | 1 )

This is configuration option which adjusts how caching behaviour performs when
the Content-Length header is equal to 0.

Default behaviour is 0, which is not to cache.

Setting this value to 1, will cache pages even if the Content-Length header is
0, which was the default behaviour prior to the addition of this feature.

And thirdly, you can set the value to the string 'warn', to warn if this
scenario occurs, and then not cache it.

## cache\_mismatch\_content\_length( 0 | 'warn' | 1 )

This is configuration option which adjusts how caching behaviour performs when
the Content-Length header differs from the length of the content itself. ( Which
usually indicates a transmission error )

Setting this value to 0, will silently not cache pages with a Content-Length
mismatch.

Setting this value to 1, will cache pages even if the Content-Length header
conflicts with the content length, which was the default behaviour prior to the
addition of this feature.

And thirdly, you can set the value to the string 'warn', to warn if this
scenario occurs, and then not cache it. ( This is the default behaviour )

## invalidate\_last\_request()

Remove the last request from the cache.

The return value reveals whether the request was successfully removed from the
cache. 1 means it's still cached, 0 means it was removed, and undef means there
was nothing to remove (there was no request or it wasn't cached).

# UPGRADING FROM 1.40 OR EARLIER

Caching behaviour has changed since 1.40, and this may result in pages that were
previously cached start failing to cache, and in some cases, emit warnings.

To return to the 1.40 behaviour:

    $mech->cache_undef_content_length(1);  # Default is 0
    $mech->cache_zero_content_length(1);   # Default is 0
    $mech->cache_mismatch_content_length(1); # Default is 'warn'

# THANKS

Iain Truskett for writing this in the first place.
Andy Lester for graciously handing over maintainership.
Kent Fredric for adding content length handling.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Mechanize::Cached

- Search CPAN

    [https://metacpan.org/module/WWW::Mechanize::Cached](https://metacpan.org/module/WWW::Mechanize::Cached)

# SEE ALSO

[WWW::Mechanize](https://metacpan.org/pod/WWW%3A%3AMechanize), [WWW::Mechanize::Cached::GZip](https://metacpan.org/pod/WWW%3A%3AMechanize%3A%3ACached%3A%3AGZip).

# AUTHORS

- Iain Truskett (original author)
- Andy Lester <petdance@cpan.org> (2004 - July 2009)
- Olaf Alders <olaf@wundercounter.com> (current maintainer)

# COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Iain Truskett and Andy Lester.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
