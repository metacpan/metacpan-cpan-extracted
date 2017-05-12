use Test::More tests => 2;
BEGIN { use_ok('Win32::SqlServer::DTS::Connection') }

can_ok(
    'Win32::SqlServer::DTS::Connection',
    qw(new get_name get_description get_type get_datasource get_catalog get_id get_provider
      get_user get_password get_oledb to_string)
);
