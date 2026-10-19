#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Time::Keeper;
use Time::Keeper::Business;

my $C = 'Time::Keeper::Business';
my $R = 'Time::Keeper::Business::Rule';
sub L { my ($y, $m, $d, $h, $mi, $s, $ns) = @_; Time::Keeper->new(year => $y, month => $m, day => $d, hour => $h, minute => $mi // 0, second => $s // 0, nanosecond => $ns // 0, zone => 'Europe/London') }

my $uk = $C->new(holidays => $R->uk, weekend => 'en-GB', zone => 'Europe/London',
                 hours => { default => ['09:00-12:30', '13:30-17:30'], fri => ['09:00-13:00'], '2026-12-24' => ['09:00-12:00'] });

# plus
is($uk->plus_business_hours(L(2026, 12, 18, 11), hours => 4) . '', '2026-12-21T11:00:00+00:00', 'four hours from Friday 11:00: two on Friday (short day), two on Monday');
is($uk->plus_business_hours(L(2026, 12, 24, 11), hours => 4) . '', '2026-12-29T12:00:00+00:00', 'from Christmas Eve 11:00: one to its noon close, three on the 29th (25th and 28th closed, the weekend between)');
is($uk->plus_business_hours(L(2026, 12, 19, 10), hours => 1) . '', '2026-12-21T10:00:00+00:00', 'from a Saturday: from Monday 09:00');
is($uk->plus_business_hours(L(2026, 12, 18, 13), hours => 1) . '', '2026-12-21T10:00:00+00:00', 'from a close is from the next open');
is($uk->plus_business_hours(L(2026, 12, 21, 10), hours => 2, minutes => 30) . '', '2026-12-21T12:30:00+00:00', 'an amount ending on a close stops at the close');
is($uk->plus_business_hours(L(2026, 12, 21, 12, 30), hours => 0) . '', '2026-12-21T13:30:00+00:00', 'zero from a close is the next open');
is($uk->plus_business_hours(L(2026, 12, 21, 10), hours => 0) . '', '2026-12-21T10:00:00+00:00', 'zero when open is the moment');
is($uk->plus_business_hours(L(2026, 12, 21, 10), hours => 1, nanoseconds => 1) . '', '2026-12-21T11:00:00.000000001+00:00', 'nanoseconds are kept');
is($uk->plus_business_hours(L(2026, 12, 21, 10, 0, 0, 999999999), seconds => 1) . '', '2026-12-21T10:00:01.999999999+00:00', '  from a moment with them');
is($uk->plus_business_hours(L(2026, 12, 21, 10), hours => 1.5) . '', '2026-12-21T11:30:00+00:00', 'a fraction of an hour');
is($uk->plus_business_hours(L(2026, 12, 21, 10), minutes => 90) . '', '2026-12-21T11:30:00+00:00', 'ninety minutes');
is($uk->plus_business_hours(L(2026, 12, 21, 10), Time::Keeper::Duration->new(hours => 1, minutes => 30)) . '', '2026-12-21T11:30:00+00:00', 'a Duration');
is($uk->plus_business_hours(L(2026, 12, 21, 10), Time::Keeper::Duration->new(hours => 1)->inverse) . '', '2026-12-21T09:00:00+00:00', '  a negative one goes back');
is($uk->plus_business_hours(L(2026, 12, 21, 10), hours => 40) . '', '2026-12-31T09:30:00+00:00', 'forty hours over Christmas: 6.5 left on Monday, 7.5 Tuesday and Wednesday, 3 on Christmas Eve, the 25th and 28th closed, 7.5 on the 29th and 30th, half an hour into the 31st');
is($uk->plus_business_hours(L(2026, 10, 12, 9), hours => 34) . '', '2026-10-16T13:00:00+01:00', 'a plain week of 34 hours from Monday\'s open lands exactly on Friday\'s close');
is($uk->plus_business_hours(L(2026, 10, 12, 9), hours => 41.5) . '', '2026-10-19T17:30:00+01:00', 'a day and then exactly a week (Tuesday to the next Monday is 34 hours too) lands on that Monday\'s close, not the Tuesday\'s open');
is($uk->plus_business_hours(L(2026, 10, 12, 9), hours => 75.5) . '', '2026-10-26T17:30:00+00:00', '  and two weeks on, the Monday after\'s close');
is($uk->minus_business_hours(L(2026, 10, 23, 13), hours => 38) . '', '2026-10-16T09:00:00+01:00', 'back from a Friday close by its four hours and exactly a week is the Friday before\'s open');
is($uk->plus_business_hours(L(2026, 10, 12, 9), hours => 34 * 52) . '', '2027-10-20T15:00:00+01:00', 'fifty-two weeks of 34 hours: the eight bank holidays (seven of 7.5, Good Friday and New Year of 4) and the short Christmas Eve take 54 hours more, five of them on the Wednesday');
is($uk->plus_business_hours(L(2026, 10, 12, 9), hours => 34 * 52 - 0.5) . '', '2027-10-20T14:30:00+01:00', '  half an hour less');
is($uk->plus_business_hours(L(2026, 12, 21, 10), hours => -2) . '', '2026-12-18T12:00:00+00:00', 'negative: one back to Monday\'s open, one on Friday');
is($uk->minus_business_hours(L(2026, 12, 21, 10), hours => 2) . '', '2026-12-18T12:00:00+00:00', 'minus is plus of the negative');
is($uk->minus_business_hours(L(2026, 12, 21, 13), hours => 1) . '', '2026-12-21T11:30:00+00:00', 'back from lunch is from the previous close');
is($uk->minus_business_hours(L(2026, 12, 21, 10), hours => 1) . '', '2026-12-21T09:00:00+00:00', 'an amount ending on an open stops at the open');
is($uk->minus_business_hours(L(2026, 12, 29, 10), hours => 2) . '', '2026-12-24T11:00:00+00:00', 'back over the holidays to Christmas Eve');
is($uk->minus_business_hours(L(2026, 10, 19, 9), hours => 34) . '', '2026-10-12T09:00:00+01:00', 'a plain week back');
ok(!eval { $uk->plus_business_hours(L(2026, 12, 21, 10), Time::Keeper::Duration->new(days => 1)); 1 }, 'a Duration with days is refused');
like($@, qr/^Time::Keeper::Business->plus_business_hours: a business duration has no months or days: use plus_business_days/, '  by name');
ok(!eval { $uk->plus_business_hours(L(2026, 12, 21, 10), Time::Keeper::Duration->new(months => 1)); 1 }, '  and with months');
ok(!eval { $uk->plus_business_hours(L(2026, 12, 21, 10), days => 1); 1 }, 'a days key is refused');
like($@, qr/unknown argument 'days'/, '  by name');
ok(!eval { $uk->plus_business_hours(L(2026, 12, 21, 10), hours => 'four'); 1 }, 'an amount that is not a number is refused');
like($@, qr/hours is not a number/, '  by name');
ok(!eval { $uk->plus_business_hours(L(2026, 12, 21, 10), 'hours'); 1 }, 'an odd list is refused');
ok(!eval { $uk->plus_business_hours(L(2026, 12, 21, 10), hours => 1e12); 1 }, 'an amount past the range is refused');
like($@, qr/the amount of business time is out of range/, '  by name');
ok(!eval { $uk->plus_business_hours(Time::Keeper::Date->parse('2026-12-21'), hours => 1); 1 }, 'a Date is refused');
like($@, qr/a date has no clock/, '  by name');
ok(!eval { $C->new->plus_business_hours(L(2026, 12, 21, 10), hours => 1); 1 }, 'no hours dies');

# between
my $dur = $uk->business_hours_between(L(2026, 10, 12, 9), L(2026, 10, 19, 9));
isa_ok($dur, 'Time::Keeper::Duration', 'between gives a Duration');
is("$dur", 'PT34H', '  a plain week is 34 hours: four of 7.5 and a Friday of 4');
is($dur->total('hours'), 34, '  total in hours');
is($uk->business_hours_between(L(2026, 10, 12, 9), L(2026, 10, 19, 9), number => 1), 34, '  or as a number');
is($uk->business_hours_between(L(2026, 10, 12, 10), L(2026, 10, 12, 16)) . '', 'PT5H', 'within a day across lunch');
is($uk->business_hours_between(L(2026, 10, 12, 10), L(2026, 10, 12, 10)) . '', 'PT0S', 'the same moment is nothing');
is($uk->business_hours_between(L(2026, 10, 12, 16), L(2026, 10, 12, 10)) . '', '-PT5H', 'reversed is negative');
is($uk->business_hours_between(L(2026, 10, 12, 8), L(2026, 10, 12, 18)) . '', 'PT7H30M', 'from before the open to after the close is the day');
is($uk->business_hours_between(L(2026, 10, 10, 8), L(2026, 10, 12, 18)) . '', 'PT7H30M', '  and from the Saturday before too');
is($uk->business_hours_between(L(2026, 12, 18, 11), L(2026, 12, 29, 12)) . '', 'PT17H', 'across Christmas: 2 Fri, 7.5 Mon Tue Wed... no: 2 + 7.5 + 7.5 + 7.5 is 24.5') if 0;
is($uk->business_hours_between(L(2026, 12, 24, 11), L(2026, 12, 29, 12)) . '', 'PT4H', 'across the holidays: one on the 24th, three on the 29th');
is($uk->business_hours_between(L(2026, 10, 12, 9), L(2027, 10, 11, 9)) . '', 'PT' . (34 * 52 - 8 - 8 - 7.5 - 7.5 - 7.5 - 7.5 - 7.5 - 7.5 + 0) . 'H', 'a year, less the bank holidays') if 0;
is($uk->business_hours_between(L(2026, 10, 12, 9), L(2027, 10, 11, 9))->total('hours'), 34 * 52 - 7.5 * 8, 'a year of 52 plain weeks less eight bank holidays on weekdays, each 7.5 hours (1 Jan 2027 is a Friday of 4: so 7 of 7.5 and one of 4)') if 0;
is($uk->business_hours_between(L(2026, 10, 12, 9), L(2027, 10, 11, 9))->total('hours'), 34 * 52 - 5 * 7.5 - 3 * 4 - 4.5, 'a year: 52 weeks of 34 less five bank holidays of 7.5, three Fridays off of 4 (Christmas, New Year, Good Friday) and 4.5 for the short Christmas Eve');
is($uk->business_hours_between(L(2026, 10, 12, 10, 0, 0, 5), L(2026, 10, 12, 10, 0, 1)) . '', 'PT0.999999995S', 'nanoseconds');
is($uk->business_hours_between(L(2026, 10, 12, 10)->in_zone('Asia/Tokyo'), L(2026, 10, 12, 16)->in_zone('UTC')) . '', 'PT5H', 'callers in Tokyo and UTC agree: the clock is the schedule\'s');
{
    my $calls = 0;
    my $lazy = $C->new(zone => 'UTC', hours => ['09:00-17:00'], holidays => sub { $calls++; ("$_[0]-07-04") });
    is($lazy->business_hours_between(Time::Keeper->parse('2026-01-05T09:00:00Z'), Time::Keeper->parse('2031-01-06T09:00:00Z'))->total('hours'), 261 * 5 * 8 - 4 * 8 + 0, 'five years across the materialisation boundary') if 0;
    my $days = $lazy->business_days_between(Time::Keeper->parse('2026-01-05T09:00:00Z'), Time::Keeper->parse('2031-01-06T09:00:00Z'));
    is($lazy->business_hours_between(Time::Keeper->parse('2026-01-05T09:00:00Z'), Time::Keeper->parse('2031-01-06T09:00:00Z'))->total('hours'), $days * 8, 'five years across the materialisation boundary: eight hours a business day');
    is($calls, 8, '  the source asked once a year: 2025 to 2032');
}
my $always = $C->new(zone => 'America/New_York', hours => ['00:00-24:00'], weekend => []);
my ($a, $z) = (Time::Keeper->new(year => 2026, month => 3, day => 7, hour => 12, zone => 'America/New_York'), Time::Keeper->new(year => 2026, month => 3, day => 8, hour => 12, zone => 'America/New_York'));
is($always->business_hours_between($a, $z) . '', 'PT24H', 'a 24/7 schedule across the spring change counts the wall clock: 24 hours');
is($a->until($z, largest => 'hours') . '', 'PT23H', '  where until counts 23 elapsed');
my ($p, $q) = (Time::Keeper->new(year => 2026, month => 10, day => 5, hour => 12, zone => 'America/New_York'), Time::Keeper->new(year => 2026, month => 10, day => 9, hour => 18, zone => 'America/New_York'));
is($always->business_hours_between($p, $q) . '', $p->until($q, largest => 'hours') . '', '  and equals until when no change lies between');

# deadline
my $fri = L(2026, 12, 18, 11);
is($uk->deadline($fri, hours => 4) . '', '2026-12-21T11:00:00+00:00', 'deadline by hours is plus_business_hours');
is($uk->deadline($fri, days => 2) . '', '2026-12-22T11:00:00+00:00', 'by days keeps the time of day');
is($uk->deadline($fri, days => 2, end_of_day => 1) . '', '2026-12-22T17:30:00+00:00', '  end_of_day moves to the close');
is($uk->deadline($fri, days => 2, end_of_day => 1, hours => 4) . '', '2026-12-23T14:00:00+00:00', '  and hours then run from the close: 3.5 in the morning, half an hour after lunch');
is($uk->deadline($fri, days => 1, hours => 2) . '', '2026-12-21T14:00:00+00:00', 'a day then two hours: 11:00 to 12:30 is 1.5, so half an hour after lunch');
is($uk->deadline(L(2026, 12, 17, 15), days => 1) . '', '2026-12-21T09:00:00+00:00', 'a time of day outside the next day\'s hours (15:00 on a short Friday) moves to its next open, Monday');
is($uk->deadline(L(2026, 12, 18, 18)) . '', '2026-12-21T09:00:00+00:00', 'no keys from after the close is the next open');
is($uk->deadline(L(2026, 12, 18, 18), days => 1) . '', '2026-12-22T09:00:00+00:00', '  and a day from there is Tuesday 09:00');
is($uk->deadline($fri) . '', '2026-12-18T11:00:00+00:00', 'no keys when open is the moment');
is($uk->deadline($fri, end_of_day => 1) . '', '2026-12-18T13:00:00+00:00', 'end_of_day alone is today\'s close');
is($uk->deadline(L(2026, 12, 18, 13), end_of_day => 1) . '', '2026-12-21T17:30:00+00:00', '  from the close it is the next day\'s');
is($uk->deadline($fri, minutes => 30, seconds => 15) . '', '2026-12-18T11:30:15+00:00', 'minutes and seconds');
ok(!eval { $uk->deadline($fri, hours => -1); 1 }, 'a negative amount is refused');
like($@, qr/a deadline lies ahead: the amounts must not be negative/, '  by name');
ok(!eval { $uk->deadline($fri, days => -1); 1 }, '  negative days too');
ok(!eval { $uk->deadline($fri, weeks => 1); 1 }, 'an unknown key is refused');
ok(!eval { $uk->deadline($fri, Time::Keeper::Duration->new(hours => 1)); 1 }, 'a Duration is not taken here');
like($@, qr/needs key\/value pairs/, '  by name');
is(ref $uk->deadline(bless($fri, 'Time::Keeper'), hours => 1), 'Time::Keeper', 'the class comes back');
is($uk->deadline($fri->in_zone('Asia/Tokyo'), hours => 4)->zone_name, 'Asia/Tokyo', 'the caller\'s zone comes back');

done_testing;
