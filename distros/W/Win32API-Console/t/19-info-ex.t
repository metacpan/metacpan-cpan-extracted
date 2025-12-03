use strict;
use warnings;

use Test::More tests => 5;
use File::Basename;
use lib dirname(__FILE__) . '\lib';

BEGIN {
  use_ok 'TestConsole', qw( GetConsoleOutputHandle );
  use_ok 'Win32API::Console', qw(
    GetConsoleScreenBufferInfoEx
    SetConsoleScreenBufferInfoEx
    GetOSVersion
  );
}

# Get a handle to the current console output
my $hConsole = GetConsoleOutputHandle();
diag "$^E" if $^E;

SKIP: {
  skip "No real console output handle available" => 1 unless $hConsole;

  SKIP: {
    skip 'Get/SetConsoleScreenBufferInfoEx not supported', 3 
      if (GetOSVersion)[1] < 6;
  
    # GetCurrentConsoleFontEx
    my %infoEx;
    my $r = GetConsoleScreenBufferInfoEx($hConsole, \%infoEx);
    diag "$^E" if $^E;
    ok($r, 'GetConsoleScreenBufferInfoEx returned extended buffer info');
    ok(defined $infoEx{ColorTable}[0], 'ColorTable is valid');

    # SetConsoleScreenBufferInfoEx
    $r = SetConsoleScreenBufferInfoEx($hConsole, \%infoEx);
    diag "$^E" if $^E;
    ok($r, 'Font info was successfully set by SetCurrentConsoleFontEx');
  }
}

done_testing();
