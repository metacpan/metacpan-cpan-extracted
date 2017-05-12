#!/usr/bin/perl 

use Test::More;

diag( "Testing WebService::Embedly  $WebService::Embedly::VERSION, Perl $], $^X" );

BEGIN { use_ok( 'Any::Moose' ); }
BEGIN { use_ok( 'JSON') ; }
BEGIN { use_ok( 'LWP::UserAgent') ; }
BEGIN { use_ok( 'URI::Escape') ; }
BEGIN { use_ok( 'Ouch') ; }
BEGIN { use_ok( 'Regexp::Common') ; }
BEGIN { use_ok( 'WebService::Embedly') ; }

done_testing();
