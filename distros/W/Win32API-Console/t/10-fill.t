use 5.012;
use strict;
use warnings;
use utf8;

use Test::More tests => 7;
use File::Basename;
use lib dirname(__FILE__) . '\lib';

BEGIN {
  use_ok 'TestConsole', qw( GetConsoleOutputHandle );
  use_ok 'Win32API::Console', qw(
    FillConsoleOutputCharacterW
    FillConsoleOutputCharacterA
  );
}

# Get a handle to the current console output
my $hConsole = GetConsoleOutputHandle();
diag "$^E" if $^E;

SKIP: {
  skip "No real console output handle available" => 4 unless $hConsole;

  # Define the write position and length
  my %coord = (X => 0, Y => 0);
  my $length = 10;
  my $written = 0;

  # Define the Unicode character to write (e.g., U+2592: Medium Shade Block)
  my $char = "\N{U+2592}";

  # Call the wrapper functions for FillConsoleOutputCharacter
  my $ok = FillConsoleOutputCharacterW(
    $hConsole,
    $char,
    $length,
    \%coord,
    \$written
  );
  diag "$^E" unless $ok;

  ok($ok, 'FillConsoleOutputCharacterW call succeeded');
  is($written, $length, 'Correct number of characters written');

  $char = 'ö';
  $coord{X} = $written;

  $ok = FillConsoleOutputCharacterA(
    $hConsole,
    $char,
    $length,
    \%coord,
    \$written
  );
  diag "$^E" unless $ok;

  ok($ok, 'FillConsoleOutputCharacterA call succeeded');
  is($written, $length, 'Correct number of characters written');
}

subtest 'Wrapper for the Unicode and ANSI functions' => sub {
  can_ok('Win32API::Console', 'FillConsoleOutputCharacter');
};

done_testing();
