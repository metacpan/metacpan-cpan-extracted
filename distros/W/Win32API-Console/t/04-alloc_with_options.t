use 5.014;
use warnings;

use Test::More tests => 8;

BEGIN {
  use_ok 'Win32';
  use_ok 'Win32API::Console', qw(
    AllocConsoleWithOptions
  );
}

use constant ERROR_PROC_NOT_FOUND => 127;

# Test: default mode (DEFAULT)
my $result;
my $r = AllocConsoleWithOptions(0, undef, \$result);
diag "$^E" if $^E;
SKIP: {
  skip "$^E", 6 if $^E == ERROR_PROC_NOT_FOUND;

  ok($r, 'AllocConsoleWithOptions(DEFAULT) returned a result');
  ok($result == 1 || $result == 2, 'Result is NEW_CONSOLE or EXISTING_CONSOLE');

  # Test: NEW_WINDOW with SW_SHOW
  $r = AllocConsoleWithOptions(1, 5, \$result);
  diag "$^E" if $^E;
  ok($r, 'AllocConsoleWithOptions(NEW_WINDOW, SW_SHOW) returned a result');
  ok($result == 1 || $result == 2, 'Result is NEW_CONSOLE or EXISTING_CONSOLE');

  # Test: NO_WINDOW
  $r = AllocConsoleWithOptions(2, undef, \$result);
  diag "$^E" if $^E;
  ok($r, 'AllocConsoleWithOptions(NO_WINDOW) returned a result');
  ok($result == 1 || $result == 2, 'Result is NEW_CONSOLE or EXISTING_CONSOLE');
}

done_testing();
