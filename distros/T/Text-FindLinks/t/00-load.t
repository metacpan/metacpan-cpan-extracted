#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Text::FindLinks' );
}

diag( "Testing Text::FindLinks $Text::FindLinks::VERSION, Perl $], $^X" );
