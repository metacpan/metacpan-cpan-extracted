#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'URI::BNode' ) || print "Bail out!\n";
}

diag( "Testing URI::BNode $URI::BNode::VERSION, Perl $], $^X" );
