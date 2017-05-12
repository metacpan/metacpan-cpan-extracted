#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'WWW::Txodds' ) || print "Bail out!\n";
}

diag( "Testing WWW::Txodds $WWW::Txodds::VERSION, Perl $], $^X" );
