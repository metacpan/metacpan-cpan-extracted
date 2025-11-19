use strict;
use warnings;

use Test::More tests => 8;

BEGIN {
  use_ok 'Win32API::Console', qw(
    GetStdHandle
    GetConsoleDisplayMode
    GetConsoleScreenBufferInfo
    GetLargestConsoleWindowSize
    SetConsoleDisplayMode
    STD_ERROR_HANDLE
    :DISPLAY_MODE_
  );
}

use constant ERROR_CALL_NOT_IMPLEMENTED => 120;

# Get handle for STDOUT
my $hConsole = GetStdHandle(STD_ERROR_HANDLE);
ok(defined $hConsole, 'STD_ERROR_HANDLE is defined');

# Get current display mode (may fail depending on environment)
my $mode = 0;
my $r = GetConsoleDisplayMode(\$mode);
diag "$^E" if $^E;
SKIP: {
  skip 'GetConsoleDisplayMode not supported', 2 
    if $^E == ERROR_CALL_NOT_IMPLEMENTED;
  ok($r, 'GetConsoleDisplayMode returned true');
  ok(
    $mode >= 0 || $mode <= 2,
    "Display mode is either 0 (windowed) or 1,2 (fullscreen): $mode"
  );
};

# Get screen buffer info
my %info;
$r = GetConsoleScreenBufferInfo($hConsole, \%info);
diag "$^E" if $^E;
ok($r, 'GetConsoleScreenBufferInfo returned true');
plan skip_all => 'Cannot proceed if the size is unknown' 
  unless $info{dwSize};

# Attempt to set display mode (may fail depending on environment)
my %dimension;
my $flags = $mode ? CONSOLE_WINDOWED_MODE : CONSOLE_FULLSCREEN_MODE;
$r = SetConsoleDisplayMode($hConsole, $flags, \%dimension);
diag "$^E" if $^E;
SKIP: {
  skip 'SetConsoleDisplayMode not supported', 3 
    if $^E == ERROR_CALL_NOT_IMPLEMENTED;
  ok($r, 'SetConsoleDisplayMode reapplied current mode');
  ok(
    $info{dwSize}{X} != $dimension{X} 
      ||
    $info{dwSize}{Y} != $dimension{Y},
    'SetConsoleDisplayMode changed the current mode'
  );
  $r = SetConsoleDisplayMode(
    $hConsole, 
    $mode ? CONSOLE_FULLSCREEN_MODE : CONSOLE_WINDOWED_MODE,
    \%dimension
  );
  diag "$^E" if $^E;
  ok($r, 'Display mode successfully restored');
}

done_testing();
