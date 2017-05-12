#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Text::xSV::Slurp' );
}

diag( "Testing Text::xSV::Slurp $Text::xSV::Slurp::VERSION, Perl $], $^X" );
