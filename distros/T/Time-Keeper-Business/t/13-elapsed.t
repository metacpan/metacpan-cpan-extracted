#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Storable ();

use Time::Keeper;
use Time::Keeper::Business;

my $C = 'Time::Keeper::Business';
sub Y { Time::Keeper->new(year => $_[0], month => $_[1], day => $_[2], hour => $_[3], minute => $_[4] // 0, zone => 'America/New_York') }
my %b = map { $_ => $C->new(zone => 'America/New_York', hours => ['22:00-06:00'], weekend => [], reckon => $_) } qw(wall elapsed);

is($b{elapsed}->business_hours_between(Y(2026, 3, 7, 22), Y(2026, 3, 8, 6))->total('hours'), 7, 'elapsed: the night over the spring change is seven hours');
is($b{wall}->business_hours_between(Y(2026, 3, 7, 22), Y(2026, 3, 8, 6))->total('hours'), 8, '  wall: eight');
is($b{elapsed}->business_hours_between(Y(2026, 10, 31, 22), Y(2026, 11, 1, 6))->total('hours'), 9, 'elapsed: the night over the autumn change is nine');
is($b{wall}->business_hours_between(Y(2026, 10, 31, 22), Y(2026, 11, 1, 6))->total('hours'), 8, '  wall: eight');
is($b{elapsed}->business_hours_between(Y(2026, 3, 1, 0), Y(2026, 3, 15, 0))->total('hours'), 14 * 8 - 1, 'two weeks over the spring change, elapsed: an hour short');
is($b{elapsed}->business_hours_between(Y(2026, 1, 5, 0), Y(2026, 2, 2, 0))->total('hours'), 28 * 8, 'four steady weeks, elapsed, equal the wall clock');
is($b{elapsed}->plus_business_hours(Y(2026, 3, 7, 22), hours => 5) . '', '2026-03-08T04:00:00-04:00', 'five elapsed hours from 22:00 EST land at 04:00 EDT');
is($b{wall}->plus_business_hours(Y(2026, 3, 7, 22), hours => 5) . '', '2026-03-08T03:00:00-04:00', '  five wall hours at 03:00 EDT');
is($b{elapsed}->plus_business_hours(Y(2026, 10, 31, 22), hours => 8) . '', '2026-11-01T05:00:00-05:00', 'eight elapsed hours over the autumn change end at 05:00 EST, an hour before the close');
is($b{elapsed}->minus_business_hours(Y(2026, 3, 8, 6), hours => 5) . '', '2026-03-08T00:00:00-05:00', 'five back from 06:00 EDT is midnight EST');
is($b{elapsed}->plus_business_hours(Y(2026, 3, 7, 22), hours => 7) . '', '2026-03-08T06:00:00-04:00', 'seven elapsed hours fill the spring night to its close');
is($b{elapsed}->plus_business_hours(Y(2026, 3, 7, 22), hours => 8) . '', '2026-03-08T23:00:00-04:00', '  and an eighth goes into the next night');
is($b{elapsed}->plus_business_hours(Y(2026, 1, 5, 22), hours => 8 * 30) . '', '2026-02-04T06:00:00-05:00', 'thirty steady nights at a stroke');
is($b{elapsed}->plus_business_hours(Y(2026, 3, 1, 22), hours => 8 * 14) . '', '2026-03-15T23:00:00-04:00', 'fourteen nights of eight over the spring change end an hour into the fifteenth');
is($b{elapsed}->deadline(Y(2026, 3, 7, 21), hours => 5) . '', '2026-03-08T04:00:00-04:00', 'a deadline from before the open, elapsed');
is($b{elapsed}->deadline(Y(2026, 3, 7, 21), days => 1, end_of_day => 1) . '', '2026-03-09T06:00:00-04:00', '  days and end_of_day are positions, the same in both');
is($b{elapsed}->deadline(Y(2026, 10, 31, 23), hours => 1) . '', '2026-11-01T00:00:00-04:00', '  an hour from an open moment counts from the moment');

my $later = Time::Keeper->new(year => 2026, month => 11, day => 1, hour => 1, minute => 30, zone => 'America/New_York', overlap => 'later');
is($b{elapsed}->plus_business_hours($later, hours => 1) . '', '2026-11-01T02:30:00-05:00', 'an hour from the later 01:30 (EST) is 02:30 EST: the moment itself is the start, not its wall reading');
is($b{elapsed}->deadline(Y(2026, 3, 7, 23), days => 1, hours => 1) . '', '2026-03-09T00:00:00-04:00', 'a deadline of a day and an hour from an open moment: the hour counts from the day stepped to');

my $gap = $C->new(zone => 'America/New_York', hours => ['02:30-04:00'], weekend => [], reckon => 'elapsed');
is($gap->business_hours_between(Y(2026, 3, 8, 0), Y(2026, 3, 9, 0))->total('hours'), 0.5, 'a span starting in the gap is moved forward by the gap, 02:30 to 03:30: half an elapsed hour');
is($C->new(zone => 'America/New_York', hours => ['02:30-04:00'], weekend => [])->business_hours_between(Y(2026, 3, 8, 0), Y(2026, 3, 9, 0))->total('hours'), 1.5, '  and an hour and a half on the wall clock');
my $always = $C->new(zone => 'America/New_York', hours => ['00:00-24:00'], weekend => [], reckon => 'elapsed');
is($always->business_hours_between(Y(2026, 3, 7, 12), Y(2026, 3, 8, 12)) . '', Y(2026, 3, 7, 12)->until(Y(2026, 3, 8, 12), largest => 'hours') . '', 'a 24/7 schedule reckoned elapsed equals until across a change');

my $day = $C->new(zone => 'America/New_York', hours => ['09:00-17:00'], reckon => 'elapsed');
is($day->business_hours_between(Y(2026, 3, 2, 9), Y(2026, 3, 16, 9))->total('hours'), 80, 'nine to five over the spring change: forty hours a week either way');
my $utc_e = $C->new(zone => 'UTC', hours => ['22:00-06:00'], reckon => 'elapsed');
my $utc_w = $C->new(zone => 'UTC', hours => ['22:00-06:00']);
my $t0 = Time::Keeper->parse('2026-03-01T00:00:00Z');
is($utc_e->business_hours_between($t0, $t0->plus(days => 60)) . '', $utc_w->business_hours_between($t0, $t0->plus(days => 60)) . '', 'a schedule in UTC is the same both ways');
is($utc_e->plus_business_hours($t0, hours => 333) . '', $utc_w->plus_business_hours($t0, hours => 333) . '', '  adding too');

my $back = $b{elapsed}->with(reckon => 'wall');
is($back->business_hours_between(Y(2026, 3, 7, 22), Y(2026, 3, 8, 6))->total('hours'), 8, 'with(reckon => wall) goes back');
is($b{elapsed}->TO_JSON->{reckon}, 'elapsed', 'the plain form carries reckon');
is(Storable::dclone($b{elapsed})->business_hours_between(Y(2026, 3, 7, 22), Y(2026, 3, 8, 6))->total('hours'), 7, '  and Storable');
{ package My::Keeper; our @ISA = ('Time::Keeper'); }
is(ref $b{elapsed}->plus_business_hours(bless(Y(2026, 3, 7, 22), 'My::Keeper'), hours => 1), 'My::Keeper', 'a subclass comes back');
is($b{elapsed}->plus_business_hours(Y(2026, 3, 7, 22)->in_zone('Asia/Tokyo'), hours => 5)->zone_name, 'Asia/Tokyo', '  and the caller\'s zone');
ok(!eval { $C->new(zone => 'UTC', hours => ['09:00-17:00'], reckon => 'sideways'); 1 }, 'an unknown reckoning is refused');
like($@, qr/reckon is 'wall' or 'elapsed', not 'sideways'/, '  by name');

{
    srand(20261019);
    my @bad;
    my $asked = 0;
    my $crossing = 0;
    for my $zone ('America/New_York', 'Europe/London', 'Australia/Lord_Howe', 'Asia/Tokyo') {
        for my $hours (['09:00-17:00'], ['22:00-06:00'], ['01:00-03:00', '13:00-14:30']) {
            my $s = $C->new(zone => $zone, hours => $hours, reckon => 'elapsed', weekend => $zone =~ /Howe/ ? [5, 6] : []);
            for (1 .. 25) {
                my $x = Time::Keeper->from_epoch(rand() < 0.5 ? 1767225600 + int(rand(365 * 86400)) : (1772323200, 1789862400)[rand 2] + int(rand(40 * 86400)), zone => $zone);
                my $y = $x->plus(seconds => int(rand(20 * 86400)));
                ($x, $y) = ($y, $x) if rand() < 0.3;
                my ($lo, $hi) = sort { $a <=> $b } $x->epoch, $y->epoch;
                my $want = 0;
                my $from = Time::Keeper->from_epoch($lo, zone => $zone)->to_date->epoch_days - 1;
                my $to = Time::Keeper->from_epoch($hi, zone => $zone)->to_date->epoch_days;
                for my $d ($from .. $to) {
                    for my $p ($s->business_hours_on(Time::Keeper::Date->from_epoch_days($d))) {
                        my ($o, $c) = ($p->[0]->epoch, $p->[1]->epoch);
                        $o = $lo if $o < $lo;
                        $c = $hi if $c > $hi;
                        $want += $c - $o if $c > $o;
                    }
                }
                $want = -$want if $x->epoch > $y->epoch;
                my $got = $s->business_hours_between($x, $y)->total('seconds');
                $asked++;
                $crossing++ if $s->business_hours_between($x, $y)->total('seconds') != $C->new(zone => $zone, hours => $hours, weekend => $zone =~ /Howe/ ? [5, 6] : [])->business_hours_between($x, $y)->total('seconds');
                push @bad, "$zone @$hours $x to $y: $got, the day's spans sum to $want" unless $got == $want;
            }
        }
    }
    ok(!@bad, "elapsed business_hours_between equals the sum of each day's opens and closes as instants ($asked spans of up to twenty days, four zones, $crossing of them over a change)")
        or diag(join "\n", @bad[0 .. ($#bad < 9 ? $#bad : 9)]);
}

done_testing;
