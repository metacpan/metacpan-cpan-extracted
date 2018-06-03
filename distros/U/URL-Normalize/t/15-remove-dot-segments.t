#!/usr/bin/env perl
#
use 5.006;
use strict;
use warnings FATAL => 'all';

use Test::More;

BEGIN {
    use_ok( 'URL::Normalize' );
}

{
    #
    # Removing dot-segments. The segments ".."" and "." can be removed from
    # a URL according to the algorithm described in RFC 3986 (or a similar
    # algorithm).
    #
    my %urls = (
        'http://www.example.com/'                                                            => 'http://www.example.com/',
        'http://www.example.com/../a/b/../c/./d.html'                                        => 'http://www.example.com/a/c/d.html',
        'http://www.example.com/../a/b/../c/./d.html?foo=../bar'                             => 'http://www.example.com/a/c/d.html?foo=../bar',
        'http://www.example.com/foo/../bar'                                                  => 'http://www.example.com/bar',
        'http://www.example.com/foo/../bar/'                                                 => 'http://www.example.com/bar/',
        'http://www.example.com/../foo'                                                      => 'http://www.example.com/foo',
        'http://www.example.com/../foo/..'                                                   => 'http://www.example.com/',
        'http://www.example.com/../../'                                                      => 'http://www.example.com/',
        'http://www.example.com/../../foo'                                                   => 'http://www.example.com/foo',
        'http://go.dagbladet.no/ego.cgi/dbf_tagcloud/http://www.dagbladet.no/tag/adam+lanza' => 'http://go.dagbladet.no/ego.cgi/dbf_tagcloud/http://www.dagbladet.no/tag/adam+lanza',
        'http://www.example.org/a/b/../../index.html'                                        => 'http://www.example.org/index.html',
        'http://www.example.com/a/.../b'                                                     => 'http://www.example.com/a/b',
        'http://www.example.com/path/page/#anchor'                                           => 'http://www.example.com/path/page/#anchor',
        'http://www.example.com/path/page/../#anchor'                                        => 'http://www.example.com/path/#anchor',
        'http://www.example.com/path/page/#anchor/page'                                      => 'http://www.example.com/path/page/#anchor/page',
        'http://www.example.com/path/page/../#anchor/page'                                   => 'http://www.example.com/path/#anchor/page',
        'HTTPS://www.example.com:443/../test/../foo/index.html'                              => 'https://www.example.com/foo/index.html',
        'https://WWW.EXAMPLE.COM/./foo/index.html'                                           => 'https://www.example.com/foo/index.html',
        'https://www.example.com/%66%6f%6f/index.html'                                       => 'https://www.example.com/foo/index.html',
        'https://www.example.com/foo/index.html'                                             => 'https://www.example.com/foo/index.html',

        '/'                                                            => '/',
        '/../a/b/../c/./d.html'                                        => '/a/c/d.html',
        '/../a/b/../c/./d.html?foo=../bar'                             => '/a/c/d.html?foo=../bar',
        '/foo/../bar'                                                  => '/bar',
        '/foo/../bar/'                                                 => '/bar/',
        '/../foo'                                                      => '/foo',
        '/../foo/..'                                                   => '/',
        '/../../'                                                      => '/',
        '/../../foo'                                                   => '/foo',
        '/ego.cgi/dbf_tagcloud/http://www.dagbladet.no/tag/adam+lanza' => '/ego.cgi/dbf_tagcloud/http://www.dagbladet.no/tag/adam+lanza',
        '/a/b/../../index.html'                                        => '/index.html',
        '/a/.../b'                                                     => '/a/b',
        '/path/page/#anchor'                                           => '/path/page/#anchor',
        '/path/page/../#anchor'                                        => '/path/#anchor',
        '/path/page/#anchor/page'                                      => '/path/page/#anchor/page',
        '/path/page/../#anchor/page'                                   => '/path/#anchor/page',
    );

    foreach ( keys %urls ) {
        my $normalizer = URL::Normalize->new( $_ );

        $normalizer->remove_dot_segments;

        # ok( $normalizer->get_url eq $urls{$_}, "$_ eq $urls{$_} - got " . $normalizer->get_url );
        ok( $normalizer->url eq $urls{$_}, "$_ eq $urls{$_} - got " . $normalizer->url );
    }
}

done_testing;
