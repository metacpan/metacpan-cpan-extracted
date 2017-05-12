#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'XMLRPC::Transport::HTTP::Server' ) || print "Bail out!\n";
}

diag( "Testing XMLRPC::Transport::HTTP::Server $XMLRPC::Transport::HTTP::Server::VERSION, Perl $], $^X" );
