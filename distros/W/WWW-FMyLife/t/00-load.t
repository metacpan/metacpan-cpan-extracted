#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'WWW::FMyLife' );
}

diag( "Testing WWW::FMyLife $WWW::FMyLife::VERSION, Perl $], $^X" );
