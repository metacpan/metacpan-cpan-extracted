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
        'http://www.example.com/#'                                             => 'http://www.example.com/',
        'http://www.example.com/#foo'                                          => 'http://www.example.com/',
        'http://www.example.com/#foo#bar'                                      => 'http://www.example.com/',
        'http://www.example.com/#foo#bar#'                                     => 'http://www.example.com/',
        'http://www.example.com/bar.html#section1'                             => 'http://www.example.com/bar.html',
        'http://www.example.com/#ThisIsOK/'                                    => 'http://www.example.com/#ThisIsOK/',
        'http://www.example.com/#ThisIsOK/index.html'                          => 'http://www.example.com/#ThisIsOK/index.html',
        'http://www.example.com/#ThisIsOK/#foo'                                => 'http://www.example.com/#ThisIsOK/',
        'http://www.example.com/#ThisIsOK/index.html#foo'                      => 'http://www.example.com/#ThisIsOK/index.html',
        'http://www.example.com/#/something'                                   => 'http://www.example.com/#/something',
        'http://www.example.com/#/something#foo'                               => 'http://www.example.com/#/something',
        'http://www.example.com/#/something/#foo'                              => 'http://www.example.com/#/something/',
        'http://www.godt.no/#!/artikkel/23489346/queen-lanserer-sitt-eget-oel' => 'http://www.godt.no/#!/artikkel/23489346/queen-lanserer-sitt-eget-oel',

        '/#'                                                 => '/',
        '/#foo'                                              => '/',
        '/#foo#bar'                                          => '/',
        '/#foo#bar#'                                         => '/',
        '/bar.html#section1'                                 => '/bar.html',
        '/#ThisIsOK/'                                        => '/#ThisIsOK/',
        '/#ThisIsOK/index.html'                              => '/#ThisIsOK/index.html',
        '/#ThisIsOK/#foo'                                    => '/#ThisIsOK/',
        '/#ThisIsOK/index.html#foo'                          => '/#ThisIsOK/index.html',
        '/#/something'                                       => '/#/something',
        '/#/something#foo'                                   => '/#/something',
        '/#/something/#foo'                                  => '/#/something/',
        '/#!/artikkel/23489346/queen-lanserer-sitt-eget-oel' => '/#!/artikkel/23489346/queen-lanserer-sitt-eget-oel',
    );

    foreach ( keys %urls ) {
        my $normalizer = URL::Normalize->new(
            url => $_,
        );

        $normalizer->remove_fragment;

        ok( $normalizer->url eq $urls{$_}, "$_ eq $urls{$_} - got " . $normalizer->url );
    }
}

done_testing;
