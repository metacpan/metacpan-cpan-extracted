#!perl -T

use Test::More tests => 1;
BEGIN { chdir 't' if -d 't' }

use lib '../lib';

use_ok( 'VKontakte::API' );
    
diag( "Testing VKontakte::API $VKontakte::API::VERSION, Perl $], $^X" );
