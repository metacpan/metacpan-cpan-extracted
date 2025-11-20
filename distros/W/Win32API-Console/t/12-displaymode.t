use strict;
use warnings;

use Test::More tests => 8;
use FindBin;
use lib "$FindBin::Bin/lib";

BEGIN {
  use_ok 'TestConsole', qw( GetConsoleOutputHandle );
  use_ok 'Win32API::Console', qw(
    GetConsoleDisplayMode
    GetConsoleScreenBufferInfo
    GetLargestConsoleWindowSize
    SetConsoleDisplayMode
    :DISPLAY_MODE_
  );
}

use constant ERROR_CALL_NOT_IMPLEMENTED => 120;

# Get a handle to the current console output
my $hConsole = GetConsoleOutputHandle();
diag "$^E" if $^E;

SKIP: {
  skip "No real console output handle available" => 6 unless $hConsole;

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
}

done_testing();
