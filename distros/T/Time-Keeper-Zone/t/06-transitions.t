#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Time::Local qw(timegm);

use Time::Keeper::Zone;

my $Z = 'Time::Keeper::Zone';

sub utc { my ($y, $m, $d, $h, $mi) = @_; timegm(0, $mi // 0, $h // 0, $d, $m - 1, $y) }

# The last Sunday of a month at 01:00 UTC: when London's clocks change.
sub last_sunday {
    my ($y, $m) = @_;
    my $t = $m == 12 ? utc($y + 1, 1, 1) : utc($y, $m + 1, 1);
    $t -= 86400;
    $t -= 86400 while (gmtime $t)[6] != 0;
    return $t + 3600;
}

my @t = $Z->transitions('Europe/London', utc(2026, 1, 1), utc(2027, 1, 1) - 1);
is_deeply(\@t, [
    [last_sunday(2026, 3), 0, 3600, 'BST', 1],
    [last_sunday(2026, 10), 3600, 0, 'GMT', 0],
], 'London 2026 has two transitions, each [epoch, before, after, abbr, is_dst]');

is($Z->previous_transition('Europe/London', $t[0][0]), last_sunday(2025, 10),
   'previous_transition of the first is in 2025');
is($Z->previous_transition('Europe/London', $t[0][0] + 1), $t[0][0], 'strictly before: a second after it gives it');
is($Z->next_transition('Europe/London', $t[0][0]), $t[1][0], 'next_transition is strictly after');
is($Z->next_transition('Europe/London', $t[0][0] - 1), $t[0][0], 'and a second before it gives it');
is($Z->previous_transition('Europe/London', last_sunday(1996, 3)), utc(1995, 10, 22, 1),
   'previous_transition steps from the footer back into the table');

my @want = map { (last_sunday($_, 3), last_sunday($_, 10)) } 1996 .. 2029;
is_deeply([map { $_->[0] } $Z->transitions('Europe/London', utc(1996, 1, 1), utc(2030, 1, 1))],
          \@want, 'London from 1996 to 2030 matches the footer, year by year');
is(scalar(() = $Z->transitions('Europe/London', $t[0][0], $t[0][0])), 1, 'both ends are included');

ok(!defined $Z->next_transition('Asia/Tokyo', utc(1952, 1, 1)), 'Tokyo has none after 1951');
is((gmtime $Z->previous_transition('Asia/Tokyo', utc(2026, 1, 1)))[5] + 1900, 1951, 'its last is in 1951');
is(scalar(() = $Z->transitions('Asia/Tokyo', utc(1952, 1, 1), utc(2026, 1, 1))), 0, 'and transitions lists none');

ok(!defined $Z->next_transition('Etc/GMT+5', 0), 'Etc/GMT+5: no next transition');
ok(!defined $Z->previous_transition('Etc/GMT+5', 0), 'nor a previous one');
is(scalar(() = $Z->transitions('Etc/GMT+5', utc(1500, 1, 1), utc(2400, 1, 1))), 0, 'nor any in a span');
is(scalar $Z->offset_at('Etc/GMT+5', 0), -18000, 'its offset is fixed');

my @d = $Z->transitions('Europe/London', utc(1983, 1, 1), utc(1983, 12, 31));
is($d[1][2], 0, 'a transition back to standard has the new offset');

is_deeply([$Z->offset_at('Europe/London', utc(2026, 7, 1))], [3600, 1, 'BST'], 'offset_at in list context');
is(scalar $Z->offset_at('Europe/London', utc(2026, 7, 1)), 3600, 'and the offset alone in scalar context');
is_deeply([$Z->offset_at('Europe/London', utc(2026, 1, 1))], [0, 0, 'GMT'], 'winter');
is(scalar $Z->offset_at('Europe/London', utc(2026, 3, 29, 1) - 0.5), 0, 'a fraction of a second counts as the second it is in');

is($Z->standard_offset_at('Europe/London', utc(2026, 7, 1)), 0, 'standard_offset_at in summer');
is($Z->standard_offset_at('America/New_York', utc(2026, 7, 1)), -18000, 'New York');
# 2026e: Europe/Dublin's standard time is IST, +01:00, and GMT in winter is
# its daylight time, a negative one.
is($Z->standard_offset_at('Europe/Dublin', utc(2026, 1, 15)), 3600, 'Dublin in winter is +01:00 standard');
is($Z->standard_offset_at('Europe/Dublin', utc(2026, 7, 15)), 3600, 'and in summer');
is_deeply([$Z->offset_at('Europe/Dublin', utc(2026, 1, 15))], [0, 1, 'GMT'], 'its winter GMT has the DST flag');
is($Z->standard_offset_at('Europe/Dublin', utc(1990, 1, 15)), 3600, 'before the footer too');
is($Z->standard_offset_at('Europe/London', utc(1970, 1, 1)), 3600, 'British Standard Time, 1968 to 1971');
is($Z->standard_offset_at('Asia/Kolkata', utc(2026, 1, 1)), 19800, 'Kolkata');

ok(!$Z->has_dst('Asia/Tokyo', 2026), 'has_dst: Tokyo 2026 no');
ok($Z->has_dst('Europe/London', 2026), 'London 2026 yes');
ok(!$Z->has_dst('Asia/Kolkata', 2026), 'Kolkata 2026 no');
ok($Z->has_dst('Asia/Tokyo', 1950), 'Tokyo 1950 yes');
ok(!$Z->has_dst('Europe/London', 1970), 'London 1970 no: British Standard Time all year');
ok(!$Z->has_dst('Etc/GMT+5', 2026), 'Etc/GMT+5 no');

is($Z->country_of('Europe/London'), 'GB', 'country_of');
is($Z->country_of('US/Eastern'), 'US', 'of a link, its zone\'s country');
is($Z->country_of('Europe/Oslo'), 'NO', 'a link zone.tab lists keeps its own');
is($Z->country_of('europe/london'), 'GB', 'in any case');
ok(!defined $Z->country_of('Etc/UTC'), 'undef for a zone of no country');
ok(!defined $Z->country_of('Nowhere'), 'and for a name that is not there');
ok(!defined $Z->country_of(undef), 'and for undef');

is($Z->windows_name('Europe/London'), 'GMT Standard Time', 'windows_name');
is($Z->windows_name('US/Eastern'), 'Eastern Standard Time', 'of a link, its zone\'s');
is($Z->windows_name('Asia/Kolkata'), 'India Standard Time', 'a zone CLDR names by a link');
ok(!defined $Z->windows_name('America/Detroit'), 'undef for a zone with no Windows name');
ok(!defined $Z->windows_name('Nowhere'), 'and for a name that is not there');
is($Z->windows_zone($Z->windows_name('Europe/Paris')), 'Europe/Paris', 'windows_zone takes it back');

for my $m (qw(transitions next_transition previous_transition offset_at standard_offset_at has_dst)) {
    my @a = $m eq 'transitions' ? (0, 1) : $m eq 'has_dst' ? (2026) : (0);
    ok(!eval { $Z->$m('Nowhere', @a); 1 }, "$m croaks for an unknown zone");
    like($@, qr/unknown time zone 'Nowhere'/, 'naming it');
}
ok(!eval { $Z->transitions('Europe/London', 10, 9); 1 }, 'transitions croaks when the end is before the start');
like($@, qr/end is before the start/, 'saying so');
ok(!eval { $Z->transitions('Europe/London', utc(1000, 1, 1), utc(2000, 1, 10)); 1 }, 'and on a span over 1,000 years');
like($@, qr/over 1,000 years/, 'saying so');
ok(eval { $Z->transitions('Europe/London', utc(1000, 1, 1), utc(2000, 1, 1)); 1 }, 'but 1,000 years is fine');
ok(!eval { $Z->offset_at('Europe/London', 9**9**9); 1 }, 'an infinite epoch croaks');

# The ABI's version 2 entries, called through its pointers.
sub abi { Time::Keeper::Zone::_abi_call(@_) }
is(Time::Keeper::Zone::_abi_version(), 2, 'the ABI is at version 2');
my $ny = abi('lookup', 'America/New_York');
my $ldn = abi('lookup', 'Europe/London');
is(abi('prev_change', $ldn, $t[1][0]), $t[0][0], 'prev_change');
ok(!defined abi('prev_change', 9999, 0), 'prev_change of a bad id');

my $over = utc(2026, 11, 1, 1, 30);
is_deeply([abi('resolve_local_all', $ny, $over)],
          [2, $over + 14400, -14400, $over + 18000, -18000], 'resolve_local_all: an overlap, earlier first');
my $gap = utc(2026, 3, 8, 2, 30);
is_deeply([abi('resolve_local_all', $ny, $gap)],
          [0, $gap + 18000, -18000, $gap + 14400, -14400], 'a gap: the offsets either side');
my $plain = utc(2026, 6, 1, 12);
is_deeply([abi('resolve_local_all', $ny, $plain)],
          [1, $plain + 14400, -14400, $plain + 14400, -14400], 'one reading in both slots');
is_deeply([abi('resolve_local_all', 9999, 0)], [-1], 'a bad id');
is_deeply([abi('standard_offset_at', $ny, $plain)], [1, -18000], 'standard_offset_at');
is_deeply([abi('standard_offset_at', 9999, 0)], [0], 'of a bad id');
is(abi('country_of', $ldn), 'GB', 'country_of');
ok(!defined abi('country_of', -1), 'of a bad id');
is(abi('windows_name', $ldn), 'GMT Standard Time', 'windows_name');
ok(!defined abi('windows_name', 9999), 'of a bad id');

done_testing;
