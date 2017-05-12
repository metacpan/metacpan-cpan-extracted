# -*- perl -*-
# Copyright (C) 2004 Identity Commons.  All Rights Reserved
# See LICENSE for licensing details

# Author: Fen Labalme <fen@idcommons.net>, <fen@comedia.com>

use Test::More;
plan tests => scalar( keys %pass ) + scalar( keys %fail );

use XRI::Parse;

doTests( \%pass );

TODO: {
    local $TODO = "don't have comments working yet";

    doTests( \%fail );
}

sub doTests {
    my $testRef = shift;

    while (my ($xri, $ref) = each %$testRef) {
        my @result = ();
        my $XRI = new XRI::Parse $xri;
        while (my $seg = $XRI->nextToken) {
            push @result, $seg;
        }
        is_deeply(\@result, $ref, $xri);
    }
}

BEGIN {
    %pass = ( "/foo/bah/doo"
              => [ qw( /* foo /* bah /* doo ) ],
              "xri://foo/bah/doo"
              => [ qw( // foo /* bah /* doo ) ],
              "xri://foo*foo/bah:bah/doo*doo"
              => [ qw( // foo * foo /* bah : bah /* doo * doo ) ],
              "xri://foo*bar/"
              => [ qw( // foo * bar /* ) ],
              "xri://(xri://foo/bah)/baz"
              => [ qw( // (xri://foo/bah) /* baz ) ],
              "xri://a*b*(xri://foo/bah)*doo/bar"
              => [ qw( // a * b * (xri://foo/bah) * doo /* bar ) ],
              "xri://(uri://foo/(http://www.foo.com))/yar"
              => [ qw( // (uri://foo/(http://www.foo.com)) /* yar ) ],
              "xri:*Fen/family"
              => [ qw( * * Fen /* family ) ],   # not sure this is correct...
              "xri:\@foo*bar"
              => [ qw( @ * foo * bar ) ],
              "xri:(!comment one)\@(!comment two)foo*bar",
              => [ qw( @ * foo * bar ) ],
              );

    %fail = ( 
              );
}
