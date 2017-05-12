#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Text::Matrix' ) || print "Bail out!
";
}

diag( "Testing Text::Matrix $Text::Matrix::VERSION, Perl $], $^X" );
