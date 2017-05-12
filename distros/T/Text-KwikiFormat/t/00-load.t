#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Text::KwikiFormat' ) || print "Bail out!\n";
}

diag( "Testing Text::KwikiFormat $Text::KwikiFormat::VERSION, Perl $], $^X" );
