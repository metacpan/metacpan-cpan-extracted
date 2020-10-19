#!perl -T
use 5.004;
use strict;
use warnings;
use Test::More;

# =========================================================================

plan tests => 1;

BEGIN {
    use_ok( 'Text::Indent::Tiny' ) || print "Bail out!\n";
}

diag( "Testing Text::Indent::Tiny $Text::Indent::Tiny::VERSION, Perl $], $^X" );

# =========================================================================

# EOF
