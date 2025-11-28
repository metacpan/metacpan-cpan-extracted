use strict;
use warnings;

use Test::More tests => 5;
use Encode qw( encode decode );

BEGIN {
  use_ok 'Win32API::Console', qw(
    GetConsoleOriginalTitleA
    GetConsoleOriginalTitleW
    GetConsoleTitleA
    GetConsoleTitleW
    SetConsoleTitleA
    SetConsoleTitleW
  );
}

subtest 'Set and Get Console Title (A)' => sub {
  my $new_title = "Perl Console Test " . time;
  select(undef, undef, undef, 0.25);
  ok(SetConsoleTitleA($new_title), 'SetConsoleTitleA applied new title');
  diag "$^E" if $^E;

  my $current_title;
  select(undef, undef, undef, 0.25);
  my $ok = GetConsoleTitleA(\$current_title, length($new_title));
  diag "$^E" if $^E;
  ok($ok, 'GetConsoleTitleA returned a value');
  is($current_title, $new_title, 'Console title matches the one set');
};

subtest 'Set and Get Console Title (W)' => sub {
  my $new_title = encode('UTF-16LE', "Perl Console Test " . time);
  select(undef, undef, undef, 0.25);
  ok(SetConsoleTitleW($new_title), 'SetConsoleTitleW applied new title');
  diag "$^E" if $^E;

  my $current_title;
  my $ok = GetConsoleTitleW(\$current_title, length($new_title));
  diag "$^E" if $^E;
  ok($ok, 'GetConsoleTitleW returned a value');
  is($current_title, $new_title, 'Console title matches the one set');
};

subtest 'Get Original Console Title' => sub {
  my $original_titleA;
  select(undef, undef, undef, 0.25);
  my $ok = GetConsoleOriginalTitleA(\$original_titleA, 1024);
  diag "$^E" if $^E;
  ok($ok, 'GetConsoleOriginalTitleA returned a value');
  ok(defined $original_titleA, 'Original title (A) is not empty');

  my $original_titleW;
  select(undef, undef, undef, 0.25);
  $ok = GetConsoleOriginalTitleW(\$original_titleW, 1024);
  diag "$^E" if $^E;
  ok($ok, 'GetConsoleOriginalTitleW returned a value');
  ok(defined $original_titleW, 'Original title (W) is not empty');
  is(
    $original_titleA, 
    decode('UTF16-LE', $original_titleW), 
    'Both titles matches'
  );
};

subtest 'Wrapper for the Unicode and ANSI functions' => sub {
  can_ok('Win32API::Console', 'GetConsoleOriginalTitle');
  can_ok('Win32API::Console', 'GetConsoleTitle');
  can_ok('Win32API::Console', 'SetConsoleTitle');
};

done_testing();
