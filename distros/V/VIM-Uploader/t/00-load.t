#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'VIM::Uploader' );
}

diag( "Testing VIM::Uploader $VIM::Uploader::VERSION, Perl $], $^X" );
