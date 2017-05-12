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
    # Remove well-known directory indexes.
    my @indexes = qw(
        index.html
        index.htm
        index.shtml
        index.php
        index.php5
        index.php4
        index.php3
        index.cgi
        default.html
        default.htm
        home.html
        home.htm
        Index.html
        Index.htm
        Index.shtml
        Index.php
        Index.cgi
        Default.html
        Default.htm
        Home.html
        Home.htm
    );

    my %urls = ();

    foreach my $index ( @indexes ) {
        $urls{ 'http://www.example.com/' . $index                     } = 'http://www.example.com/';
        $urls{ 'http://www.example.com/' . $index . '?foo=/' . $index } = 'http://www.example.com/?foo=/' . $index;
    }

    foreach ( keys %urls ) {
        my $normalizer = URL::Normalize->new(
            url => $_,
        );

        $normalizer->remove_directory_index;

        ok( $normalizer->url eq $urls{$_}, "$_ eq $urls{$_} - got " . $normalizer->url );
    }
}

done_testing;
