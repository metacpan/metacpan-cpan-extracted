use Test::More tests => 2;
BEGIN { use_ok('Win32::SqlServer::DTS::Task::ExecutePackage') }
can_ok(
    'Win32::SqlServer::DTS::Task::ExecutePackage',
    qw(new get_name get_description get_type to_string get_package_id get_package_name
      get_package_password get_repository_database_name get_server_name get_server_password get_server_username
      get_file_name get_input_vars get_ref_input_vars uses_repository use_trusted)
);
