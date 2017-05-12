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
    # Converting the scheme and host to lower case. The scheme and host
    # components of the URL are case-insensitive. Most normalizers will
    # convert them to lowercase.
    #
    my %urls = (
        'HTTP://www.Example.com'  => 'http://www.example.com/',
        'HTTP://www.Example.com/' => 'http://www.example.com/',
        'http://www.example.com'  => 'http://www.example.com/',
        'http://www.example.com/' => 'http://www.example.com/',
    );

    foreach ( keys %urls ) {
        my $Normalizer = URL::Normalize->new(
            url => $_,
        );

        $Normalizer->make_canonical;

        ok( $Normalizer->url eq $urls{$_}, "$_ eq $urls{$_} - got " . $Normalizer->url );
    }
}

{
    #
    # Capitalizing letters in escape sequences. All letters within a
    # percent-encoding triplet (e.g., "%3A") are case-insensitive, and
    # should be capitalized.
    #
    my %urls = (
        'http://www.example.com/a%c2%b1b'    => 'http://www.example.com/a%C2%B1b',
        'HTTP://www.example.com:80/a%c2%b1b' => 'http://www.example.com/a%C2%B1b',
    );

    foreach ( keys %urls ) {
        my $Normalizer = URL::Normalize->new(
            url => $_,
        );

        $Normalizer->make_canonical;

        ok( $Normalizer->url eq $urls{$_}, "$_ eq $urls{$_} - got " . $Normalizer->url );
    }
}

{
    #
    # Decoding percent-encoded octets of unreserved characters. For consistency,
    # percent-encoded octets in the ranges of ALPHA (%41–%5A and %61–%7A),
    # DIGIT (%30–%39), hyphen (%2D), period (%2E), underscore (%5F), or
    # tilde (%7E) should not be created by URI producers and, when found in a
    # URI, should be decoded to their corresponding unreserved characters by URI
    # normalizers.
    #
    my %urls = (
        'http://www.example.com/%7Eusername/'    => 'http://www.example.com/~username/',
        'http://www.example.com/%7eusername/'    => 'http://www.example.com/~username/',
        'HTTP://www.example.com:80/%7eusername/' => 'http://www.example.com/~username/',
    );

    foreach ( keys %urls ) {
        my $Normalizer = URL::Normalize->new(
            url => $_,
        );

        $Normalizer->make_canonical;

        ok( $Normalizer->url eq $urls{$_}, "$_ eq $urls{$_} - got " . $Normalizer->url );
    }
}

{
    #
    # Removing the default port. The default port (port 80 for the “http” scheme)
    # may be removed from (or added to) a URL.
    #
    my %urls = (
        'http://www.example.com:'            => 'http://www.example.com/',
        'http://www.example.com:/'           => 'http://www.example.com/',
        'http://www.example.com:80'          => 'http://www.example.com/',
        'http://www.example.com:80/'         => 'http://www.example.com/',
        'http://www.example.com:80/bar.html' => 'http://www.example.com/bar.html',
    );

    foreach ( keys %urls ) {
        my $Normalizer = URL::Normalize->new(
            url => $_,
        );

        $Normalizer->make_canonical;

        ok( $Normalizer->url eq $urls{$_}, "$_ eq $urls{$_} - got " . $Normalizer->url );
    }
}

done_testing;
