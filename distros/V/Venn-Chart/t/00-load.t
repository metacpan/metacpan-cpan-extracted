#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Venn::Chart' ) || print "Bail out!
";
}

diag( "Testing Venn::Chart $Venn::Chart::VERSION, Perl $], $^X" );
