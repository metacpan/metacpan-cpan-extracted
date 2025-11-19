use strict;
use warnings;

use Test::More tests => 6;

BEGIN {
  use_ok 'Win32API::Console', qw(
    GetStdHandle
    GetConsoleCursorInfo
    SetConsoleCursorInfo
    STD_ERROR_HANDLE
  );
}

# Get handle for STDERR
my $hConsole = GetStdHandle(STD_ERROR_HANDLE);
ok(defined $hConsole, 'STD_ERROR_HANDLE is defined');

# Get current cursor info
my %cursor_info;
my $got = GetConsoleCursorInfo($hConsole, \%cursor_info);
diag "$^E" if $^E;
ok($got, 'GetConsoleCursorInfo returned true');
ok($cursor_info{dwSize} > 0, 'Cursor size is greater than 0');

# Toggle cursor visibility
my %new_cursor_info = (
  dwSize   => $cursor_info{dwSize},
  bVisible => $cursor_info{bVisible} ? 0 : 1,  # invert visibility
);

my $set = SetConsoleCursorInfo($hConsole, \%new_cursor_info);
diag "$^E" if $^E;
ok($set, 'SetConsoleCursorInfo successfully changed visibility');

$set = SetConsoleCursorInfo($hConsole, \%cursor_info);
diag "$^E" if $^E;
ok($set, 'Cursor info successfully restored');

done_testing();
