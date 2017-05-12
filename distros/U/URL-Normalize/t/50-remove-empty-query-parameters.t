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
        'http://www.example.com/?a=1&b=&c=3'    => 'http://www.example.com/?a=1&c=3',
        'http://www.example.com/?a=&a=1&b=&c=3' => 'http://www.example.com/?a=1&c=3',
    );

    foreach ( keys %urls ) {
        my $normalizer = URL::Normalize->new(
            url => $_,
        );

        $normalizer->remove_empty_query_parameters;

        ok( $normalizer->url eq $urls{$_}, "$_ eq $urls{$_} - got " . $normalizer->url );
    }
}

done_testing;
