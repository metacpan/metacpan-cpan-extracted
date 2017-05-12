#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Text::Authinfo' ) || print "Bail out!\n";
}

diag( "Testing Text::Authinfo $Text::Authinfo::VERSION, Perl $], $^X" );
