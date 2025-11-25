use strict;
use warnings;

use Test::More tests => 4;
use File::Basename;
use lib dirname(__FILE__) . '\lib';

BEGIN {
  use_ok 'TestConsole', qw( GetConsoleOutputHandle );
  use_ok 'Win32API::Console', qw(
    GetLargestConsoleWindowSize
    GetConsoleMode
    SetConsoleMode
  );
}

# Get a handle to the current console output
my $hConsole = GetConsoleOutputHandle();
diag "$^E" if $^E;

SKIP: {
  skip "No real console output handle available" => 2 unless $hConsole;

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
}

done_testing();
