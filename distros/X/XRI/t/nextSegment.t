# -*- perl -*-
# Copyright (C) 2004 Identity Commons.  All Rights Reserved
# See LICENSE for licensing details

# Author: Fen Labalme <fen@idcommons.net>, <fen@comedia.com>

use Test::More;
plan tests => scalar keys %tests;

use XRI::Parse;

while (my ($xri, $ref) = each %tests) {
    my @result = ();
    my $XRI = new XRI::Parse $xri;
    while (my $seg = $XRI->nextSegment) {
        push @result, $seg;
    }
    is_deeply(\@result, $ref, $xri);
}

BEGIN {
    %tests = ( "xri://foo*bah/doo*dah"
               => [[ qw( // foo * bah ) ],
                   [ qw( /* doo * dah ) ]],
               "xri://foo.baz*bah/doo*dah/"
               => [[ qw( // foo.baz * bah ) ],
                   [ qw( /* doo * dah ) ],
                   [ qw( /* ) ]],
               "xri:\@baz*bah/:foo*bah/blah"
               => [[ qw( @ * baz * bah ) ],
                   [ qw( /: foo * bah ) ],
                   [ qw( /* blah ) ]],
               "/foo*bah/bar*baz.zap.it"
               => [[ qw( /* foo * bah ) ],
                   [ qw( /* bar * baz.zap.it ) ]],
               );
}
