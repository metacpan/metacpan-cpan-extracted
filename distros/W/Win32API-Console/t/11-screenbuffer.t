use strict;
use warnings;

use Test::More tests => 8;
use File::Basename;
use lib dirname(__FILE__) . '\lib';

# force flush output
BEGIN { $| = 1 }

BEGIN {
  use_ok 'TestConsole', qw( GetConsoleOutputHandle );
  use_ok 'Win32API::Console', qw(
    GetConsoleScreenBufferInfo
    SetConsoleTextAttribute
    SetConsoleWindowInfo
    :FOREGROUND_
  );
}

# Get a handle to the current console output
my $hConsole = GetConsoleOutputHandle();
diag "$^E" if $^E;

SKIP: {
  skip "No real console output handle available" => 6 unless $hConsole;

  # Get screen buffer info
  my %info;
  my $got = GetConsoleScreenBufferInfo($hConsole, \%info);
  diag "$^E" if $^E;
  ok($got, 'GetConsoleScreenBufferInfo returned true');
  plan skip_all => 'Cannot proceed if the dimension is unknown' 
    unless $info{srWindow};

  # Save original window rectangle
  my %original_window = %{$info{srWindow}};
  ok(
    $original_window{Bottom} > $original_window{Top}, 
    'Original window height is valid'
  );

  # Change text attribute (e.g. bright white on black)
  my $attr = FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE 
    | FOREGROUND_INTENSITY;
  my $set_attr = SetConsoleTextAttribute($hConsole, $attr);
  diag "$^E" if $^E;
  ok($set_attr, 'SetConsoleTextAttribute applied new color');

  # Attempt to shrink visible window by 1 row
  my %new_window = (
    Left   => $original_window{Left},
    Top    => $original_window{Top},
    Right  => $original_window{Right},
    Bottom => $original_window{Bottom} - 1,
  );

  # 1 = absolute coordinates
  my $set_window = SetConsoleWindowInfo($hConsole, 1, \%new_window); 
  diag "$^E" if $^E;
  ok($set_window, 'SetConsoleWindowInfo successfully adjusted window');

  # Restore original window size
  my $restore = SetConsoleWindowInfo($hConsole, 1, \%original_window);
  diag "$^E" if $^E;
  ok($restore, 'SetConsoleWindowInfo restored original window size');

  $restore = SetConsoleTextAttribute($hConsole, $info{wAttributes});
  diag "$^E" if $^E;
  ok($restore, 'SetConsoleTextAttribute restored original color');
}

done_testing();
