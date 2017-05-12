use Test::More tests => 2;
BEGIN { use_ok('Win32::SqlServer::DTS::Task') }
can_ok( 'Win32::SqlServer::DTS::Task',
    qw(new get_name get_description get_type to_string ) );
