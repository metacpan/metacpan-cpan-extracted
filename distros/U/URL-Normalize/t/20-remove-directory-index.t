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
        default.htm
        Default.htm
        default.html
        Default.html
        Default.html.asp
        Default.html.aspx
        home.htm
        Home.htm
        home.html
        Home.html
        index.cgi
        Index.cgi
        index.htm
        Index.htm
        index.html
        Index.html
        Index.html.asp
        Index.html.php
        Index.jsp
        index.php
        Index.php
        index.php3
        index.php4
        index.php5
        index.shtml
        Index.shtml
        Welcome.htm
        Welcome.html
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
