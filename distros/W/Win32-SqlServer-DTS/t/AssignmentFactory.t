use Test::More tests => 2;
BEGIN { use_ok('Win32::SqlServer::DTS::AssignmentFactory') }

can_ok( 'Win32::SqlServer::DTS::AssignmentFactory', qw(create) );

