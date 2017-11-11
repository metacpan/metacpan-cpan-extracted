# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 5;

BEGIN { use_ok( 'Win32::Shortkeys' ) };
BEGIN { use_ok('Win32::Shortkeys::Kbh') };

my $object = Win32::Shortkeys->new ("example/kbhook.properties");
isa_ok ($object, 'Win32::Shortkeys');
is($^O, "MSWin32", "This module is limited to Windows");
can_ok("Win32::Shortkeys::Kbh", qw(send_string send_cmd register_hook set_key_processor));

