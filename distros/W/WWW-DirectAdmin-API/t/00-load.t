#!perl 

use Test::More tests => 1;

BEGIN {
    use_ok( 'WWW::DirectAdmin::API' ) || print "Bail out!\n";
}

diag( "Testing WWW::DirectAdmin::API $WWW::DirectAdmin::API::VERSION, Perl $], $^X" );
