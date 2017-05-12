#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'arXiv' ) || print "Bail out!
";
}

diag( "Testing arXiv $arXiv::VERSION, Perl $], $^X" );
