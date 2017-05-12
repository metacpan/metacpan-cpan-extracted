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
        'http://www.example.com/?c=4&a=1&a=2&b=3&a=1' => 'http://www.example.com/?c=4&a=1&a=2&b=3',

        '/?c=4&a=1&a=2&b=3&a=1' => '/?c=4&a=1&a=2&b=3',
    );

    foreach ( keys %urls ) {
        my $normalizer = URL::Normalize->new(
            url => $_,
        );

        $normalizer->remove_duplicate_query_parameters;

        ok( $normalizer->url eq $urls{$_}, "$_ eq $urls{$_} - got " . $normalizer->url );
    }
}

done_testing;
