use Test::More tests => 2;
BEGIN { use_ok('Win32::SqlServer::DTS') }

can_ok(
    'Win32::SqlServer::DTS',
    qw(get_sibling
      is_sibling_ok
	  kill_sibling
	  debug)
);
