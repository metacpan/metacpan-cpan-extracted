#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Test::Pcuke' ) || print "Bail out!
";
}

diag( "Testing Test::Pcuke $Test::Pcuke::VERSION, Perl $], $^X" );
