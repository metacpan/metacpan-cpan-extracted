#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Test::MockObject::Universal' ) || print "Bail out!
";
}

diag( "Testing Test::MockObject::Universal $Test::MockObject::Universal::VERSION, Perl $], $^X" );
