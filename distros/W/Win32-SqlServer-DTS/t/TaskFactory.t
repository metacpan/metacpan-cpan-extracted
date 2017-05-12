use Test::More tests => 2;
BEGIN { use_ok('Win32::SqlServer::DTS::TaskFactory') }
can_ok( 'Win32::SqlServer::DTS::TaskFactory', 'create' );
