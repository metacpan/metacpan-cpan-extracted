#!perl -T

use Test::More tests => 1;

BEGIN {
    local (*is, *isnt);
    use_ok( 'Test::Magic' ) || print "Bail out!
";
}

diag( "Testing Test::Magic $Test::Magic::VERSION, Perl $], $^X" );
