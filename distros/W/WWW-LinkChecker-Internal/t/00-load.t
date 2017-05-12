#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'WWW::LinkChecker::Internal' ) || print "Bail out!\n";
}

diag( "Testing WWW::LinkChecker::Internal $WWW::LinkChecker::Internal::VERSION, Perl $], $^X" );
