use strict;
use warnings;
use utf8;

use Test::More tests => 6;
use FindBin;
use lib "$FindBin::Bin/lib";

BEGIN {
  use_ok 'TestConsole', qw( GetConsoleOutputHandle );
  use_ok 'Win32API::Console', qw(
    GetConsoleScreenBufferInfo
    SetConsoleScreenBufferSize
    ScrollConsoleScreenBufferA
    ScrollConsoleScreenBufferW
  );
}

# Get a handle to the current console output
my $hConsole = GetConsoleOutputHandle();
diag "$^E" if $^E;

SKIP: { 
  skip "No real console output handle available" => 3 unless $hConsole;

  my %info;
  subtest 'GetConsoleScreenBufferInfo' => sub {
    ok(
      GetConsoleScreenBufferInfo($hConsole, \%info), 
      'Retrieved original screen buffer info'
    );
    diag "$^E" if $^E;
    ok(
      $info{dwSize}{X} > 0 && $info{dwSize}{Y} > 0, 
      'Original buffer size is valid'
    );
  };

  subtest 'SetConsoleScreenBufferSize and restore' => sub {
    my %size = %{ $info{dwSize} };
    my %new_size = (
      X => $size{X},
      Y => $size{Y} + 50,  # increase height
    );

    # Set new and restore size
    ok(
      SetConsoleScreenBufferSize($hConsole, \%new_size), 
      'SetConsoleScreenBufferSize applied new size'
    );
    diag "$^E" if $^E;
    ok(
      SetConsoleScreenBufferSize($hConsole, \%size), 
      'Restored original buffer size'
    );
    diag "$^E" if $^E;
  };

  subtest 'ScrollConsoleScreenBuffer' => sub {
    my %rect = ( Left => 0, Top => 0, Right => 10, Bottom => 10 );
    my %coord = ( X => 0, Y => -1 );    # scroll up
    my $fill = unpack('L', pack('CxS', ord('*'), 0x07));

    select(undef, undef, undef, 0.5);
    my $r = ScrollConsoleScreenBufferA($hConsole, \%rect, undef, \%coord, $fill);
    diag "$^E" if $^E;
    ok($r, 'ScrollConsoleScreenBufferA ok region');

    $fill = unpack('L', pack('SS', ord("ö"), 0x07));

    select(undef, undef, undef, 0.5);
    $r = ScrollConsoleScreenBufferW($hConsole, \%rect, undef, \%coord, $fill);
    diag "$^E" if $^E;
    ok($r, 'ScrollConsoleScreenBufferW ok region');
  };
}

subtest 'Wrapper for the Unicode and ANSI functions' => sub {
  can_ok('Win32API::Console', 'ScrollConsoleScreenBuffer');
};

done_testing();
