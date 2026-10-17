#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Time::Keeper::Zone;

sub days {
    my ($y, $m, $d) = @_;
    $y -= $m <= 2;
    my $era = int(($y >= 0 ? $y : $y - 399) / 400);
    my $yoe = $y - $era * 400;
    my $doy = int((153 * ($m > 2 ? $m - 3 : $m + 9) + 2) / 5) + $d - 1;
    return $era * 146097 + $yoe * 365 + int($yoe / 4) - int($yoe / 100) + $doy - 719468;
}
sub at { my ($y, $m, $d, $h, $mi, $s) = @_; days($y, $m, $d) * 86400 + ($h // 0) * 3600 + ($mi // 0) * 60 + ($s // 0) }
sub off { join ' ', Time::Keeper::Zone::_offset_at(@_) }

is(off('Europe/London', at(2026, 1, 15, 12)), '0 0 GMT', 'London in winter');
is(off('Europe/London', at(2026, 7, 15, 12)), '3600 1 BST', 'London in summer');
is(off('Europe/London', at(2026, 3, 29, 0, 59, 59)), '0 0 GMT', 'London the second before the clocks go forward');
is(off('Europe/London', at(2026, 3, 29, 1)), '3600 1 BST', 'and the second they do');
is(off('Europe/London', at(2026, 10, 25, 0, 59, 59)), '3600 1 BST', 'the second before they go back');
is(off('Europe/London', at(2026, 10, 25, 1)), '0 0 GMT', 'and the second they do');
is(off('Europe/London', at(1800, 1, 1)), '-75 0 LMT', 'London before 1847 kept local mean time');
is(off('Europe/London', at(1944, 6, 1)), '7200 1 BDST', 'double summer time in the war');
is(off('Europe/London', at(1970, 1, 1)), '3600 0 BST', 'British Standard Time, 1968 to 1971');
is(off('Europe/London', at(2100, 7, 1)), '3600 1 BST', 'summer time in 2100, from the rule');
is(off('Europe/London', at(2500, 1, 1)), '0 0 GMT', 'and winter in 2500');
is(off('Europe/london', at(2026, 7, 1)), '3600 1 BST', 'a name in the wrong case');
is(off('GB', at(2026, 7, 1)), '3600 1 BST', 'a link');

is(off('America/New_York', at(2026, 3, 8, 6, 59, 59)), '-18000 0 EST', 'New York before spring forward');
is(off('America/New_York', at(2026, 3, 8, 7)), '-14400 1 EDT', 'and after');
is(off('America/New_York', at(2026, 11, 1, 5, 59, 59)), '-14400 1 EDT', 'before falling back');
is(off('America/New_York', at(2026, 11, 1, 6)), '-18000 0 EST', 'and after');
is(off('America/New_York', at(1945, 8, 15)), '-14400 1 EPT', 'Eastern Peace Time');

is(off('Australia/Lord_Howe', at(2026, 1, 15)), '39600 1 +11', 'Lord Howe in summer, half an hour on');
is(off('Australia/Lord_Howe', at(2026, 7, 15)), '37800 0 +1030', 'and in winter');

is(off('Europe/Dublin', at(2026, 7, 15)), '3600 0 IST', 'Dublin in summer: Irish Standard Time');
is(off('Europe/Dublin', at(2026, 1, 15)), '0 1 GMT', 'and in winter GMT, which is the daylight time');

is(off('Pacific/Apia', at(2011, 12, 30, 9, 59, 59)), '-36000 1 -10', 'Samoa at 23:59:59 on 29 December 2011, on the American side of the date line');
is(off('Pacific/Apia', at(2011, 12, 30, 10)), '50400 1 +14', 'and a second later midnight on the 31st, the 30th skipped');

is(off('Asia/Kathmandu', at(2026, 1, 1)), '20700 0 +0545', 'Kathmandu, five hours forty-five');
is(off('Asia/Kathmandu', at(1985, 1, 1)), '19800 0 +0530', 'five thirty before 1986');

is(off('Asia/Tokyo', at(2026, 7, 1)), '32400 0 JST', 'Tokyo, no daylight time');
is(off('Etc/UTC', at(-1000, 1, 1)), '0 0 UTC', 'UTC a thousand years before Christ');
is(off('Etc/GMT+5', at(2026, 1, 1)), '-18000 0 -05', 'Etc/GMT+5 is five hours BEHIND');

is(off('Africa/Casablanca', at(2026, 2, 25)), '0 1 +00', 'Morocco during Ramadan 2026: negative DST');
is(off('Africa/Casablanca', at(2026, 6, 1)), '3600 0 +01', 'and after it');

is(off('America/Sao_Paulo', at(2026, 1, 1)), '-10800 0 -03', 'Sao Paulo, no daylight time since 2019');
is(off('America/Sao_Paulo', at(2018, 12, 1)), '-7200 1 -02', 'and with it in 2018');

ok(!eval { Time::Keeper::Zone::_offset_at('Nowhere/Special', 0); 1 }, 'a zone that is not there');

is(Time::Keeper::Zone::_next_change('Europe/London', at(2026, 1, 1)), at(2026, 3, 29, 1), 'London\'s next change from New Year 2026');
is(Time::Keeper::Zone::_next_change('Europe/London', at(2026, 3, 29, 1)), at(2026, 10, 25, 1), 'and from that one, the next');
is(Time::Keeper::Zone::_next_change('Asia/Tokyo', at(2026, 1, 1)), undef, 'Tokyo never changes again');
is(Time::Keeper::Zone::_next_change('Etc/UTC', at(1900, 1, 1)), undef, 'nor does UTC');

{
    my @c = Time::Keeper::Zone::_changes('Europe/London', at(2026, 1, 1), at(2027, 12, 31));
    is(scalar @c, 4, 'London changes four times in 2026 and 2027');
    is_deeply([map { $_->[3] } @c], [qw(BST GMT BST GMT)], 'to summer and back each year');
}
{
    my @c = Time::Keeper::Zone::_changes('Europe/London', at(2101, 1, 1), at(2101, 12, 31));
    is_deeply([map { $_->[0] } @c], [at(2101, 3, 27, 1), at(2101, 10, 30, 1)],
              'in 2101, on the last Sundays of March and October');
}

done_testing;
