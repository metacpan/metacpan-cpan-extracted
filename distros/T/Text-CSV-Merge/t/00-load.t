#!/usr/bin/env perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Text::CSV::Merge' ) || print "Could not load Text::CSV::Merge!\n";
}

diag( "Text::CSV::Merge, Perl $^V, $^X" );
