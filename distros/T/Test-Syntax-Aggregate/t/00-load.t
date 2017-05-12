#!perl -T

use Test::More tests => 2;

BEGIN {
    use_ok( 'Test::Syntax::Aggregate' ) || print "Bail out!\n";
    use_ok( 'Test::Syntax::Aggregate::Checker' ) || print "Bail out!\n";
}

diag( "Testing Test::Syntax::Aggregate $Test::Syntax::Aggregate::VERSION, Perl $], $^X" );
