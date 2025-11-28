use strict;
use warnings;
use utf8;

use Test::More tests => 9;
require bytes;
use Encode qw( encode );
use File::Basename;
use lib dirname(__FILE__) . '\lib';

BEGIN {
  use_ok 'TestConsole', qw( GetConsoleOutputHandle );
  use_ok 'Win32API::Console', qw(
    GetConsoleOutputCP
    SetConsoleCursorPosition
    WriteConsoleOutputAttribute
    ReadConsoleOutputAttribute
    WriteConsoleOutputCharacterA
    ReadConsoleOutputCharacterA
    WriteConsoleOutputCharacterW
    ReadConsoleOutputCharacterW
    WriteConsoleOutputA
    ReadConsoleOutputA
    WriteConsoleOutputW
    ReadConsoleOutputW
    :Struct
  );
}

use constant YELLOW_on_BLACK => 0x0e;

# Get a handle to the current console output
my $hConsole = GetConsoleOutputHandle();
diag "$^E" if $^E;

SKIP: {
  skip "No real console output handle available" => 6 unless $hConsole;

  ok(
    SetConsoleCursorPosition($hConsole, COORD(0,0)), 
    'SetConsoleCursorPosition call succeeded'
  );

  subtest 'WriteConsoleOutputAttribute / ReadConsoleOutputAttribute' => sub {
    my $attr  = pack('S*', (YELLOW_on_BLACK) x 3);
    my $coord = COORD(0,0);
    my $written;

    my $r = WriteConsoleOutputAttribute($hConsole, $attr, $coord, \$written);
    diag "$^E" if $^E;
    ok($r, 'WriteConsoleOutputCharacter call succeeded');
    ok($written == 3, 'WriteConsoleOutputAttribute wrote 3 attributes');

    my ($read_attr, $read);
    $r = ReadConsoleOutputAttribute($hConsole, \$read_attr, 3, $coord, \$read);
    diag "$^E" if $^E;
    ok($r, 'ReadConsoleOutputAttribute call succeeded');
    is(
      $read_attr, 
      $attr, 
      'ReadConsoleOutputAttribute returned expected attributes'
    );
  };

  subtest 'WriteConsoleOutputCharacterA / ReadConsoleOutputCharacterA' => sub {
    my $text  = Encode::ANSI::encode("Gruß", GetConsoleOutputCP());
    my $coord = COORD(0,0);
    my $written;

    my $r = WriteConsoleOutputCharacterA($hConsole, $text, $coord, \$written);
    diag "$^E" if $^E;
    ok($r, 'WriteConsoleOutputCharacterA call succeeded');
    cmp_ok(
      $written, '>=', length($text), 
      'WriteConsoleOutputCharacterA wrote correct number of characters'
    );

    my ($chars, $read);
    $r = ReadConsoleOutputCharacterA($hConsole, \$chars, length($text), 
      $coord, \$read);
    diag "$^E" if $^E;
    ok($r, 'ReadConsoleOutputCharacterA call succeeded');
    TODO: {
      local $TODO = 'Does not work with every code page' if $r;
      ok($read, 'ReadConsoleOutputCharacterA returned text');
      is($chars, $text, 'ReadConsoleOutputCharacterA returned expected text');
    }
  };

  subtest 'WriteConsoleOutputCharacterW / ReadConsoleOutputCharacterW' => sub {
    my $text = encode('UTF-16LE', "Olá");
    my $length = bytes::length($text) >> 1;
    my $coord = COORD(0,1);
    my $written;

    my $r = WriteConsoleOutputCharacterW($hConsole, $text, $coord, \$written);
    diag "$^E" if $^E;
    ok($r, 'WriteConsoleOutputCharacterW call succeeded');
    is(
      $written, 
      $length, 
      'WriteConsoleOutputCharacterW wrote correct number of characters'
    );

    my ($chars, $read);
    $r = ReadConsoleOutputCharacterW($hConsole, \$chars, $length, $coord, 
      \$read);
    diag "$^E" if $^E;
    ok($r, 'ReadConsoleOutputCharacterW call succeeded');
    is($chars, $text, 'ReadConsoleOutputCharacterW returned expected text');
  };

  subtest 'WriteConsoleOutputA / ReadConsoleOutputA' => sub {
    my $screen = pack('S*', 
      ord('H'), YELLOW_on_BLACK, 
      ord('e'), YELLOW_on_BLACK, 
      ord('j'), YELLOW_on_BLACK,
    );
    my $size   = COORD(3,1);
    my $coord  = COORD(0,0);
    my $region = SMALL_RECT((0,0), COORD::list($size));

    my $r = WriteConsoleOutputA($hConsole, $screen, $size, $coord, $region);
    diag "$^E" if $^E;
    ok($r, 'WriteConsoleOutputA call succeeded');

    my $buffer;
    $r = ReadConsoleOutputA($hConsole, \$buffer, $size, $coord, $region);
    diag "$^E" if $^E;
    ok($r, 'ReadConsoleOutputA call succeeded');
    is($buffer, $screen, 'ReadConsoleOutputA returned expected text');
  };

  subtest 'WriteConsoleOutputW / ReadConsoleOutputW' => sub {
    my $screen = pack('S*',
      ord('H'), YELLOW_on_BLACK, 
      ord('o'), YELLOW_on_BLACK, 
      ord('i'), YELLOW_on_BLACK,
    );
    my $size   = COORD(3,1);
    my $coord  = COORD(0,0);
    my $region = SMALL_RECT((0,0), COORD::list($size));

    my $r = WriteConsoleOutputW($hConsole, $screen, $size, $coord, $region);
    diag "$^E" if $^E;
    ok($r, 'WriteConsoleOutputW call succeeded');

    my $buffer;
    $r = ReadConsoleOutputW($hConsole, \$buffer, $size, $coord, $region);
    diag "$^E" if $^E;
    ok($r, 'ReadConsoleOutputW call succeeded');
    is($buffer, $screen, 'ReadConsoleOutputW returned expected text');
  };
}

subtest 'Wrapper for the Unicode and ANSI functions' => sub {
  can_ok('Win32API::Console', 'ReadConsoleOutput');
  can_ok('Win32API::Console', 'WriteConsoleOutput');
  can_ok('Win32API::Console', 'ReadConsoleOutputCharacter');
  can_ok('Win32API::Console', 'WriteConsoleOutputCharacter');
};

done_testing();
