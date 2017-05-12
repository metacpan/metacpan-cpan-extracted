#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Wiktionary::Parser' ) || print "Bail out!\n";
}

diag( "Testing Wiktionary::Parser $Wiktionary::Parser::VERSION, Perl $], $^X" );
