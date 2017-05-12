#!/usr/bin/env perl

use Test::More;

use URI;
use URI::Normalize qw( normalize_uri remove_dot_segments );

{
    my @data = qw(
        HTTPS://www.example.com:443/../test/../foo/index.html
        https://WWW.EXAMPLE.COM/./foo/index.html
        https://www.example.com/%66%6f%6f/index.html
        https://www.example.com/foo/index.html
    );
    my $expect = $data[-1];

    is normalize_uri($_), $expect, "$_ normalizes" for @data;
}

{
    my @data = qw(
        HTTPS://www.example.com:443/../test/../foo/index.html
        HTTPS://www.example.com:443/foo/index.html

        https://WWW.EXAMPLE.COM/./foo/index.html
        https://WWW.EXAMPLE.COM/foo/index.html

        https://www.example.com/%66%6f%6f/index.html
        https://www.example.com/%66%6f%6f/index.html

        https://www.example.com/foo/index.html
        https://www.example.com/foo/index.html

        https://www.example.com/..
        https://www.example.com/

        https://www.example.com/.
        https://www.example.com/

        https://www.example.com/foo/..
        https://www.example.com/

        https://www.example.com/foo/.././../../bar/../baz
        https://www.example.com/baz
    );
    my $expect = $data[-1];

    while (my ($start, $expect) = splice @data, 0, 2) {
        is remove_dot_segments($start), $expect, "$start remove_dot_segments works";
    }
}

done_testing;
