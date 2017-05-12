#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'WWW::AtMovies' );
}

diag( "Testing WWW::AtMovies $WWW::AtMovies::VERSION, Perl $], $^X" );
