#!perl
use 5.010;
use strict;
use warnings;
use utf8;
use Test::More;

use Time::Keeper;

my $K = 'Time::Keeper';
my $t = $K->new(year => 2026, month => 10, day => 15, hour => 21, minute => 5, second => 7,
                nanosecond => 123_456_789, zone => 'America/New_York');

my @cases = (
    [G => 'AD'], [GG => 'AD'], [GGG => 'AD'], [GGGG => 'Anno Domini'], [GGGGG => 'A'],
    [y => '2026'], [yy => '26'], [yyy => '2026'], [yyyy => '2026'], [yyyyy => '02026'],
    [u => '2026'], [uuuuu => '02026'],
    [Y => '2026'], [YY => '26'], [YYYY => '2026'],
    [Q => '4'], [QQ => '04'], [QQQ => 'Q4'], [QQQQ => '4th quarter'], [QQQQQ => '4'],
    [q => '4'], [qqq => 'Q4'], [qqqq => '4th quarter'],
    [M => '10'], [MM => '10'], [MMM => 'Oct'], [MMMM => 'October'], [MMMMM => 'O'],
    [L => '10'], [LLL => 'Oct'], [LLLL => 'October'], [LLLLL => 'O'],
    [w => '42'], [ww => '42'], [W => '3'],
    [d => '15'], [dd => '15'], [D => '288'], [DDDD => '0288'], [F => '3'],
    [g => '61328'],
    [E => 'Thu'], [EEE => 'Thu'], [EEEE => 'Thursday'], [EEEEE => 'T'],
    [e => '5'], [ee => '05'], [eee => 'Thu'], [eeee => 'Thursday'],
    [c => '5'], [ccc => 'Thu'], [cccc => 'Thursday'], [ccccc => 'T'],
    [a => 'PM'], [aaaa => 'PM'], [aaaaa => 'p'],
    [h => '9'], [hh => '09'], [H => '21'], [HH => '21'], [K => '9'], [KK => '09'], [k => '21'], [kk => '21'],
    [j => '9'], [jj => '09'],
    [m => '5'], [mm => '05'], [s => '7'], [ss => '07'],
    [S => '1'], [SSS => '123'], [SSSSSS => '123456'], [SSSSSSSSSSS => '12345678900'],
    [A => '75907123'],
    [z => 'EDT'], [zzz => 'EDT'], [zzzz => 'Eastern Daylight Time'],
    [Z => '-0400'], [ZZZ => '-0400'], [ZZZZ => 'GMT-04:00'], [ZZZZZ => '-04:00'],
    [O => 'GMT-4'], [OOOO => 'GMT-04:00'],
    [X => '-04'], [XX => '-0400'], [XXX => '-04:00'], [XXXX => '-0400'], [XXXXX => '-04:00'],
    [x => '-04'], [xxx => '-04:00'],
    [VV => 'America/New_York'],
);
for my $c (@cases) {
    is($t->format($c->[0]), $c->[1], "$c->[0] is '$c->[1]'");
}

is($t->format("h 'o''clock' a"), "9 o'clock PM", 'quoted text, with a quote inside');
is($t->format("''HH''"), "'21'", "'' outside quotes is a quote");
is($t->format("'yyyy' yyyy"), 'yyyy 2026', 'letters in quotes are text');
is($t->format('EEEE, MMMM d, y \'at\' h:mm a'), 'Thursday, October 15, 2026 at 9:05 PM', 'a whole pattern');
is($t->format('#@!'), '#@!', 'other characters are text');
is($t->format('y-MM-dd'), '2026-10-15', 'separators');

is($t->format_date('full'), 'Thursday, October 15, 2026', 'format_date full');
is($t->format_date('long'), 'October 15, 2026', 'long');
is($t->format_date, 'Oct 15, 2026', 'medium by default');
is($t->format_date('short'), '10/15/26', 'short');
is($t->format_time('short'), "9:05\x{202F}PM", 'format_time short');
is($t->format_time('full'), "9:05:07\x{202F}PM Eastern Daylight Time", 'full, with the zone');
is($t->format_datetime('short'), "10/15/26, 9:05\x{202F}PM", 'format_datetime short');
is($t->format_datetime, "Oct 15, 2026, 9:05:07\x{202F}PM", 'medium by default');
ok(!eval { $t->format_date('huge'); 1 }, 'a length that is not one');
is($t->format_skeleton('yMMMd'), 'Oct 15, 2026', 'format_skeleton');
is($t->format_skeleton('Hm'), '21:05', 'a 24-hour skeleton');
ok(!eval { $t->format_skeleton('qqqqQQQQ'); 1 }, 'a skeleton the locale has no format for');
like($@, qr/no format for the skeleton/, 'says so');

is_deeply([map { $t->$_ } qw(month_name month_abbr day_name day_abbr am_pm era_name era_abbr quarter_name quarter_abbr)],
          ['October', 'Oct', 'Thursday', 'Thu', 'PM', 'Anno Domini', 'AD', '4th quarter', 'Q4'], 'the names');
is($K->new(year => -44)->era_abbr, 'BC', 'before Christ');
is($K->new(year => 0)->format('y G'), '0 BC', 'year 0 is 1 BC, written astronomically');
is($K->new(year => 2026, hour => 0)->format('h K k H'), '12 0 24 0', 'midnight in h, K, k and H');
is($K->new(year => 2026, hour => 12)->format('h K a'), '12 0 PM', 'and noon');
is($K->new(year => 2026, zone => 'floating')->format('z Z'), 'floating +0000', 'floating time');
is($K->new(year => 2026)->format('X x ZZZZZ ZZZZ O'), 'Z +00 Z GMT GMT', 'zero offsets in UTC');
is($K->new(year => 2026, zone => '+05:30')->format('X x O'), '+0530 +0530 GMT+5:30', 'X, x and O with minutes');

done_testing;
