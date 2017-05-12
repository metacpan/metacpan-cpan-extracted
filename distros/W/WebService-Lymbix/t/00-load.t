#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'WebService::Lymbix' ) || print "Bail out!\n";
}

diag( "Testing WebService::Lymbix $WebService::Lymbix::VERSION, Perl $], $^X" );
