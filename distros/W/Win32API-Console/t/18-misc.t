use strict;
use warnings;

use Test::More tests => 4;

BEGIN {
  use_ok 'Win32API::Console', qw(
    GetStdHandle
    GetLargestConsoleWindowSize
    GetConsoleMode
    SetConsoleMode
    STD_ERROR_HANDLE
  );
}

my $hConsole = GetStdHandle(STD_ERROR_HANDLE);
ok(defined $hConsole, 'STD_ERROR_HANDLE is defined');

subtest 'GetLargestConsoleWindowSize' => sub {
  my $size = GetLargestConsoleWindowSize($hConsole);
  diag "$^E" if $^E;
  ok($size->{X} > 0 && $size->{Y} > 0, 'Largest window size is valid');
};

subtest 'GetConsoleMode / SetConsoleMode' => sub {
  my $mode;
  my $ok = GetConsoleMode($hConsole, \$mode);
  diag "$^E" if $^E;
  ok($ok, 'GetConsoleMode returned a value');
  ok(defined $mode, 'GetConsoleMode returned a valid current mode');

  # reapply same mode
  $ok = defined($mode) && SetConsoleMode($hConsole, $mode);
  diag "$^E" if $^E;
  ok($ok, 'SetConsoleMode reapplied current mode');
};

done_testing();
