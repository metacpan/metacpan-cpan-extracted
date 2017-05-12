#!perl -T

use Test::More tests => 3;

BEGIN {
    use_ok( 'WebService::Linode::Base' );
    use_ok( 'WebService::Linode' );
    use_ok( 'WebService::Linode::DNS' );
}

diag( "Testing WebService::Linode $WebService::Linode::VERSION, Perl $], $^X" );
