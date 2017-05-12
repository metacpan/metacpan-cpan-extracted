use Test::More tests => 2;
BEGIN { use_ok('Win32::SqlServer::DTS::Package::Step::Result') }

can_ok(
    'Win32::SqlServer::DTS::Package::Step::Result',
    qw(new
      to_string
      to_xml)
);
