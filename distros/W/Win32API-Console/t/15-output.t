use strict;
use warnings;
use utf8;

use Test::More tests => 6;

BEGIN {
  use_ok 'Win32API::Console', qw(
    GetStdHandle
    WriteConsoleOutputCharacterA
    WriteConsoleOutputCharacterW
    ReadConsoleOutputCharacterA
    ReadConsoleOutputCharacterW
    WriteConsoleOutputAttribute
    ReadConsoleOutputAttribute
    SetConsoleCursorPosition
    STD_ERROR_HANDLE
    COORD
  );
}

my $hConsole = GetStdHandle(STD_ERROR_HANDLE);
ok(defined $hConsole, 'STD_ERROR_HANDLE is defined');
ok(
  SetConsoleCursorPosition($hConsole, COORD(0,0)), 
  'SetConsoleCursorPosition call succeeded'
);

subtest 'WriteConsoleOutputAttribute / ReadConsoleOutputAttribute' => sub {
  my $attr = 0x0e;  # Yellow on black
  my $coord = { X => 0, Y => 0 };
  my $written;

  my $ok = WriteConsoleOutputAttribute($hConsole, pack('S*', ($attr) x 3), 
    $coord, \$written);
  diag "$^E" if $^E;
  ok($ok, 'WriteConsoleOutputCharacter call succeeded');
  ok($written == 3, 'WriteConsoleOutputAttribute wrote 3 attributes');

  my $read_attr;
  my $read;
  $ok = ReadConsoleOutputAttribute($hConsole, \$read_attr, 3, $coord, \$read);
  diag "$^E" if $^E;
  ok($ok, 'ReadConsoleOutputAttribute call succeeded');
  is(
    $read_attr,
    pack('S*', ($attr) x 3),
    'ReadConsoleOutputAttribute returned expected attributes'
  );
};

subtest 'WriteConsoleOutputCharacterA / ReadConsoleOutputCharacterA' => sub {
  my $text = "Hallöchen";
  my $coord = { X => 0, Y => 0 };
  my $written;

  my $ok = WriteConsoleOutputCharacterA($hConsole, $text, $coord, \$written);
  diag "$^E" if $^E;
  ok($ok, 'WriteConsoleOutputCharacterA call succeeded');
  is(
    $written, 
    length($text), 
    'WriteConsoleOutputCharacterA wrote correct number of characters'
  );

  my $read_chars;
  my $read;
  $ok = ReadConsoleOutputCharacterA($hConsole, \$read_chars, $written, 
    $coord, \$read);
  diag "$^E" if $^E;
  ok($ok, 'ReadConsoleOutputCharacterA call succeeded');
  is($read_chars, $text, 'ReadConsoleOutputCharacterA returned expected text');
};

subtest 'WriteConsoleOutputCharacterW / ReadConsoleOutputCharacterW' => sub {
  my $text = "Olá";
  my $coord = { X => 0, Y => 1 };
  my $written;

  my $ok = WriteConsoleOutputCharacterW($hConsole, $text, $coord, \$written);
  diag "$^E" if $^E;
  ok($ok, 'WriteConsoleOutputCharacterW call succeeded');
  is(
    $written, 
    length($text), 
    'WriteConsoleOutputCharacterW wrote correct number of characters'
  );

  my $read_chars;
  my $read;
  $ok = ReadConsoleOutputCharacterW($hConsole, \$read_chars, length($text), 
    $coord, \$read);
  diag "$^E" if $^E;
  ok($ok, 'ReadConsoleOutputCharacterW call succeeded');
  is($read_chars, $text, 'ReadConsoleOutputCharacterW returned expected text');
};

done_testing();
