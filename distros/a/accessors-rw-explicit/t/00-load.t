#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'accessors::rw::explicit' ) || print "Bail out!
";
}

diag( "Testing accessors::rw::explicit $accessors::rw::explicit::VERSION, Perl $], $^X" );
