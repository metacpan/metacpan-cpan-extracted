# -*- perl -*-
# Copyright (C) 2004 Identity Commons.  All Rights Reserved
# See LICENSE for licensing details

# Author: Fen Labalme <fen@idcommons.net>, <fen@comedia.com>

use Test::More tests => 6;
use Text::Balanced qw( extract_bracketed );

&testBracketed;                 # 6 tests

# really a test of Text::Balanced so that I could understand how it works...
sub testBracketed {
    my @tests = ( "(this is a cross ref) more test here",
                  "(this has (an embedded) crossref) more test here",
                  "(thisHas(noSpaces)inIt)moreTestHere"
                  );

    testBracketed1($tests[0], "(this is a cross ref)", " more test here");
    testBracketed1($tests[1], "(this has (an embedded) crossref)",  " more test here");
    testBracketed1($tests[2], "(thisHas(noSpaces)inIt)", "moreTestHere");
}
sub testBracketed1 {
    my ($t, $e, $r) = @_;
    my ($te,$tr) = extract_bracketed($t, '()');
    is( $e, $te );
    is( $r, $tr );
}
