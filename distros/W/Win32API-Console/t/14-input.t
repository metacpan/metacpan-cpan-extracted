use strict;
use warnings;

use Test::More tests => 11;

BEGIN {
  use_ok 'Win32API::Console', qw(
    GetStdHandle
    FlushConsoleInputBuffer
    ReadConsoleInputA
    ReadConsoleInputW
    PeekConsoleInputA
    PeekConsoleInputW
    WriteConsoleInputA
    WriteConsoleInputW
    STD_INPUT_HANDLE
    KEY_EVENT
  );
}

use constant VK_PACKET => 0xe7;

my $hInput = GetStdHandle(STD_INPUT_HANDLE);
ok(defined $hInput, 'STD_INPUT_HANDLE is defined');

subtest 'FlushConsoleInputBuffer' => sub {
  ok(FlushConsoleInputBuffer($hInput), 'FlushConsoleInputBuffer returned TRUE')
};

my $event;
subtest 'WriteConsoleInputA' => sub {
  $event = {
    EventType => KEY_EVENT,
    Event     => {
      bKeyDown          => 1,
      wRepeatCount      => 1,
      wVirtualKeyCode   => ord('A'),
      wVirtualScanCode  => 0,
      uChar             => ord('A'),
      dwControlKeyState => 0,
    }
  };

  my $written = WriteConsoleInputA($hInput, $event);
  ok($written, 'WriteConsoleInputA wrote event');
};

subtest 'PeekConsoleInputA' => sub {
  my %peeked;
  my $r = PeekConsoleInputA($hInput, \%peeked);
  ok($r, 'PeekConsoleInputA returned events');
  is($peeked{EventType}, KEY_EVENT, 'Peeked event is KEY_EVENT');
  ok(exists $peeked{Event}, 'Field Event exists');
};

subtest 'ReadConsoleInputA' => sub {
  my %read;
  my $r = ReadConsoleInputA($hInput, \%read);
  ok($r, 'ReadConsoleInputA returned events');
  is($read{EventType}, KEY_EVENT, 'Read event is KEY_EVENT');
  is_deeply(\%read, $event, 'Read key successfully');
};

subtest 'FlushConsoleInputBuffer' => sub {
  ok(FlushConsoleInputBuffer($hInput), 'FlushConsoleInputBuffer returned TRUE')
};

subtest 'WriteConsoleInputW' => sub {
  $event = {
    EventType => KEY_EVENT,
    Event     => {
      bKeyDown          => 1,
      wRepeatCount      => 1,
      wVirtualKeyCode   => VK_PACKET,
      wVirtualScanCode  => 0,
      uChar             => 0x2592,        # Medium Shade Block
      dwControlKeyState => 0,
    }
  };

  my $written = WriteConsoleInputW($hInput, $event);
  ok($written, 'WriteConsoleInputA wrote event');
};

subtest 'PeekConsoleInputW' => sub {
  my %peeked;
  my $r = PeekConsoleInputW($hInput, \%peeked);
  ok($r, 'PeekConsoleInputW returned events');
  is($peeked{EventType}, KEY_EVENT, 'Peeked event is KEY_EVENT');
  ok(exists $peeked{Event}, 'Field Event exists');
};

subtest 'ReadConsoleInputW' => sub {
  my %read;
  my $r = ReadConsoleInputW($hInput, \%read);
  ok($r, 'ReadConsoleInputW returned events');
  is($read{EventType}, KEY_EVENT, 'Read event is KEY_EVENT');
  is_deeply(\%read, $event, 'Read key successfully');
};

subtest 'Wrapper for the Unicode and ANSI functions' => sub {
  can_ok('Win32API::Console', 'ReadConsoleInput');
  can_ok('Win32API::Console', 'PeekConsoleInput');
  can_ok('Win32API::Console', 'WriteConsoleInput');
};

done_testing();
