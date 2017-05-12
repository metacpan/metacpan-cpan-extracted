use Test::More tests => 2;

BEGIN { use_ok('Win32::SqlServer::DTS::Assignment::Destination') }

can_ok(
    'Win32::SqlServer::DTS::Assignment::Destination',
    qw(new
      initialize
      get_destination
      get_string
      get_raw_string
      set_string
      changes)
);

