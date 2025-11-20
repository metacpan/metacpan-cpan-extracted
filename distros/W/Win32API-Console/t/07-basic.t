use strict;
use warnings;

use Test::More tests => 8;
use FindBin;
use lib "$FindBin::Bin/lib";

BEGIN {
  use_ok 'TestConsole', qw( GetConsoleOutputHandle );
  use_ok 'Win32API::Console', qw(
    GetConsoleWindow
    GetOSVersion
    INVALID_HANDLE_VALUE
  );
}

# Get a handle to the current console output
my $hConsole = GetConsoleOutputHandle();
diag "$^E" if $^E;
TODO: {
  todo_skip 'No real console output handle available' => 1 unless $hConsole;
  isnt($hConsole, INVALID_HANDLE_VALUE, 'Obtained console handle');
}

# Test: GetConsoleWindow
my $hwnd = GetConsoleWindow();
diag "$^E" if $^E;
ok(defined $hwnd, 'GetConsoleWindow returned a window handle');
isnt($hwnd, INVALID_HANDLE_VALUE, 'Console window handle is valid');

# Test: GetOSVersion
my @osinfo = GetOSVersion();
diag "$^E" if $^E;
ok(@osinfo >= 5, 'GetOSVersion returned at least 5 elements');
ok(defined $osinfo[0], 'OS name looks valid');
ok($osinfo[1] > 0, 'Major version is > 0');

done_testing();
