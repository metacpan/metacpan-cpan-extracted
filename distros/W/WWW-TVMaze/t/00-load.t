#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'WWW::TVMaze' ) || print "Bail out!\n";
}

diag( "Testing WWW::TVMaze $WWW::TVMaze::VERSION, Perl $], $^X" );
