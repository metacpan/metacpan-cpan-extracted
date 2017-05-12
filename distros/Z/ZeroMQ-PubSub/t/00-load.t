#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'ZeroMQ::PubSub' ) || print "Bail out!\n";
}

diag( "Testing ZeroMQ::PubSub $ZeroMQ::PubSub::VERSION, Perl $], $^X" );
