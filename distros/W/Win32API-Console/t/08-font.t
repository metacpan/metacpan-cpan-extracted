use strict;
use warnings;

use Test::More tests => 10;
use File::Basename;
use lib dirname(__FILE__) . '\lib';

BEGIN {
  use_ok 'TestConsole', qw( GetConsoleOutputHandle );
  use_ok 'Win32API::Console', qw(
    GetCurrentConsoleFont
    GetCurrentConsoleFontEx
    GetConsoleFontSize
    GetNumberOfConsoleFonts
    GetOSVersion
    SetCurrentConsoleFontEx
  );
}

# Get a handle to the current console output
my $hConsole = GetConsoleOutputHandle();
diag "$^E" if $^E;

SKIP: {
  skip "No real console output handle available" => 6 unless $hConsole;

  my %font;
  # GetCurrentConsoleFont
  my $r = GetCurrentConsoleFont($hConsole, 0, \%font);
  diag "$^E" if $^E;
  ok($r, 'GetCurrentConsoleFont returned font info');
  ok($font{dwFontSize}{Y} > 0, 'Font height is greater than 0');

  # GetConsoleFontSize
  my $size = GetConsoleFontSize($hConsole, $font{nFont});
  diag "$^E" if $^E;
  SKIP: {
    skip 'GetConsoleFontSize not supported', 1 unless $size->{X};
    ok($size->{X} && $size->{Y}, 'GetConsoleFontSize returned valid size');
  }

  SKIP: {
    skip 'Get/SetCurrentConsoleFontEx not supported', 3 
      if (GetOSVersion)[1] < 6;
  
    # GetCurrentConsoleFontEx
    my %fontEx;
    $r = GetCurrentConsoleFontEx($hConsole, 0, \%fontEx);
    diag "$^E" if $^E;
    ok($r, 'GetCurrentConsoleFontEx returned extended font info');
    ok($fontEx{FaceName}, 'Face name is valid');

    # SetCurrentConsoleFontEx
    $r = SetCurrentConsoleFontEx($hConsole, 0, \%fontEx);
    diag "$^E" if $^E;
    ok($r, 'Font info was successfully set by SetCurrentConsoleFontEx');
  }
}

# GetNumberOfConsoleFonts
my $count = eval { GetNumberOfConsoleFonts() };
ok(!$@, 'GetNumberOfConsoleFonts called without exception');

SKIP: {
  skip 'GetNumberOfConsoleFonts not supported', 1 unless defined $count;
  pass('GetNumberOfConsoleFonts returned a number');
}

done_testing();
