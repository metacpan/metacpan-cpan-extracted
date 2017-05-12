#!perl -T
use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
    use_ok( 'Test::Net::LDAP' ) || print "Bail out!\n";
}

diag( "Testing Test::Net::LDAP $Test::Net::LDAP::VERSION, Perl $], $^X" );
