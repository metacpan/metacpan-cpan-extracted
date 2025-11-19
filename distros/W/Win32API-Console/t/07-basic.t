use strict;
use warnings;

use Test::More tests => 8;

BEGIN {
  use_ok 'Win32API::Console', qw(
    GetStdHandle
    GetConsoleWindow
    GetOSVersion
    STD_ERROR_HANDLE
    INVALID_HANDLE_VALUE
  );
}

# Test: GetStdHandle
my $handle = GetStdHandle(STD_ERROR_HANDLE);
diag "$^E" if $^E;
ok(defined $handle, 'GetStdHandle(STD_ERROR_HANDLE) returned a handle');
isnt($handle, INVALID_HANDLE_VALUE, 'STD_ERROR_HANDLE is valid');

# Test: GetConsoleWindow
my $hwnd = GetConsoleWindow();
diag "$^E" if $^E;
ok(defined $hwnd, 'GetConsoleWindow returned a window handle');
isnt($hwnd, INVALID_HANDLE_VALUE, 'Console window handle is valid');

# Test: GetOSVersion
my @osinfo = GetOSVersion();
diag "$^E" if $^E;
ok(@osinfo >= 5, 'GetOSVersion returned at least 5 elements');
like($osinfo[0], qr/^Windows/, 'OS name looks valid');
ok($osinfo[1] > 0, 'Major version is > 0');

done_testing();
