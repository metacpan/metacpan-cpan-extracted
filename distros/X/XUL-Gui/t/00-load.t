#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'XUL::Gui' );
}

diag( "Testing XUL::Gui $XUL::Gui::VERSION, Perl $], $^X" );
