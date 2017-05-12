use warnings;
use strict;
use Test::More tests => 2;

BEGIN { use_ok( 'WebService::HashiCorp::Vault::Sys' ) or BAIL_OUT('unable to load module') }
BEGIN { use_ok( 'WebService::HashiCorp::Vault' ) or BAIL_OUT('unable to load module') }

diag( "Testing WebService::HashiCorp::Vault $WebService::HashiCorp::Vault::VERSION, Perl $], $^X" );
