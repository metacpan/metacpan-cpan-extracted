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
    my %urls = (
        'http://www.example.com//'             => 'http://www.example.com/',
        'http://www.example.com///'            => 'http://www.example.com/',
        'http://www.example.com/foo//bar.html' => 'http://www.example.com/foo/bar.html',
        'http://www.example.com/?key=//'       => 'http://www.example.com/?key=//',
        'http://www.example.com/?key=foo//'    => 'http://www.example.com/?key=foo//',
    );

    foreach ( keys %urls ) {
        my $normalizer = URL::Normalize->new(
            url => $_,
        );

        $normalizer->remove_duplicate_slashes;

        ok( $normalizer->url eq $urls{$_}, "$_ eq $urls{$_} - got " . $normalizer->url );
    }
}

done_testing;
