#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'XMLDB::SQLServer' )  
}

diag( "Testing XMLDB::SQLServer, $XMLDB::SQLServer::VERSION Perl $], $^X" );
