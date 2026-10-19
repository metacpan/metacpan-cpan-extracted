#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Time::Keeper;
use Time::Keeper::Sun;

# A day at a place: its events against USNO's one-day data (t/usno-oneday.tsv,
# 83 days at twenty places, to the minute, in the day's own offset), and the
# shape of the Day object. USNO lists the events a civil day holds in the
# offset given, which is this dist's day too; it names a day the sun never
# rose or set on, and the twilight the same way.

sub near { my ($got, $want, $tol, $name) = @_; cmp_ok(abs($got - $want), '<=', $tol, "$name: $got within $tol of $want") }

# ---- the shape --------------------------------------------------------------

my $london = Time::Keeper::Sun->new(latitude => 51.5074, longitude => -0.1278, zone => 'Europe/London');
my $day = $london->on(year => 2026, month => 10, day => 15);
isa_ok($day, 'Time::Keeper::Sun::Day');
isa_ok($day->date, 'Time::Keeper::Date');
is("${\ $day->date }", '2026-10-15', 'date');
isa_ok($day->place, 'Time::Keeper::Sun');
is($day->place->latitude, 51.5074, 'the place comes back');
is($day->zone_name, 'Europe/London', 'zone_name');
is("${\ $day->start }", '2026-10-15T00:00:00+01:00', 'start is local midnight');
is("${\ $day->end }", '2026-10-16T00:00:00+01:00', 'end is the next');
isa_ok($day->sunrise, 'Time::Keeper');
is($day->sunrise->zone_name, 'Europe/London', 'a value in the place\'s zone');
is($day->sunrise->nanosecond, 0, 'rounded to the second');
like("${\ $day->sunrise }", qr/^2026-10-15T07:24:\d\d\+01:00$/, 'sunrise 07:24 (USNO: 07:24)');
like("${\ $day->sunset }", qr/^2026-10-15T18:07:\d\d\+01:00$/, 'sunset 18:07 (USNO: 18:07)');
like("${\ $day->solar_noon }", qr/^2026-10-15T12:46:\d\d\+01:00$/, 'solar noon 12:46 (USNO: 12:46)');
like("${\ $day->solar_midnight }", qr/^2026-10-15T00:46:\d\d\+01:00$/, 'solar midnight 00:46');
like("${\ $day->dawn }", qr/^2026-10-15T06:5[01]:\d\d\+01:00$/, 'civil dawn about 06:51 (USNO: 06:51)');
like("${\ $day->dusk }", qr/^2026-10-15T18:41:\d\d\+01:00$/, 'civil dusk 18:41 (USNO: 18:41)');
is("${\ $day->dawn(kind => 'civil') }", "${\ $day->dawn }", 'civil is the default');
ok($day->dawn(kind => 'nautical') < $day->dawn, 'nautical dawn is earlier');
ok($day->dawn(kind => 'astronomical') < $day->dawn(kind => 'nautical'), 'astronomical earlier still');
ok($day->dusk(kind => 'astronomical') > $day->dusk(kind => 'nautical'), 'and the dusks the other way');
isa_ok($day->day_length, 'Time::Keeper::Duration');
is($day->day_length->total('seconds'), $day->sunset->epoch - $day->sunrise->epoch, 'day_length is sunset less sunrise on an ordinary day');
ok($day->day_length->total('hours') > 10.5 && $day->day_length->total('hours') < 11, 'about ten and three quarter hours');
ok(!$day->is_polar_day && !$day->is_polar_night, 'not polar');
is(scalar(my @r = $day->sunrises), 1, 'one sunrise');
is("$r[0]", "${\ $day->sunrise }", 'the same one');
is(scalar(my @s = $day->sunsets), 1, 'one sunset');
is(scalar(my @n = $day->solar_noons), 1, 'one noon');
is(scalar(my @m = $day->solar_midnights), 1, 'one midnight');
is(scalar(my @dd = $day->dawns(kind => 'nautical')), 1, 'one nautical dawn');
is(scalar(my @dk = $day->dusks), 1, 'one civil dusk');
{
    my @ev = $day->events;
    is(scalar @ev, 10, 'ten events');
    is(join(' ', map { $_->[0] } @ev),
       'solar_midnight astronomical_dawn nautical_dawn civil_dawn sunrise solar_noon sunset civil_dusk nautical_dusk astronomical_dusk',
       'in order of time');
    my $ok = 1;
    $ok &&= $ev[$_ - 1][1] <= $ev[$_][1] for 1 .. $#ev;
    ok($ok, 'each no earlier than the last');
    my %first;
    $first{$_->[0]} //= $_->[1] for @ev;
    is("$first{sunrise}", "${\ $day->sunrise }", 'the singular is events\' first of its kind');
    is("$first{civil_dusk}", "${\ $day->dusk }", 'for a twilight too');
}

# the four forms of on
{
    my $d2 = $london->on(Time::Keeper::Date->new(year => 2026, month => 10, day => 15));
    is("${\ $d2->sunrise }", "${\ $day->sunrise }", 'on a Date');
    my $d3 = $london->on(Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 15, zone => 'Europe/London'));
    is("${\ $d3->sunrise }", "${\ $day->sunrise }", 'on a value');
    my $d4 = $london->on(Time::Keeper->new(year => 2026, month => 10, day => 16, hour => 3, zone => 'Asia/Tokyo'));
    is("${\ $d4->date }", '2026-10-15', 'a value in another zone gives its date at the PLACE (Tokyo 03:00 on the 16th is London on the 15th)');
    {
        local $Time::Keeper::CLOCK = Time::Keeper->parse('2026-10-15T20:00:00Z');
        is("${\ $london->on->date }", '2026-10-15', 'on() is today in the place\'s zone, by the test clock');
        local $Time::Keeper::CLOCK = Time::Keeper->parse('2026-10-15T23:30:00Z');
        is("${\ $london->on->date }", '2026-10-16', 'which is tomorrow in London at 23:30 UTC in summer time');
    }
    for my $bad (
        [[year => 2026, month => 2, day => 30], qr/^on: there is no 2026-02-30/],
        [[year => 2026, month => 13, day => 1], qr/^on: there is no month 13/],
        [[year => 2026, month => 10], qr/^on needs year, month and day/],
        [[year => 2026, month => 10, day => 15, hour => 1], qr/^on: unknown argument 'hour'/],
        [[year => 'next', month => 10, day => 15], qr/^on: year must be a number/],
        [['2026-10-15'], qr/^on takes a Time::Keeper::Date, a Time::Keeper value, or year, month and day/],
        [[[]], qr/^on takes a Time::Keeper::Date/],
        [[Time::Keeper::Duration->new(days => 1)], qr/^on takes a Time::Keeper::Date/],
        [[year => 3001, month => 1, day => 1], qr/^on: the year 3001 is outside/],
        [[year => -2000, month => 6, day => 1], qr/^on: the year -2000 is outside/],
    ) {
        my ($args, $re) = @$bad;
        ok(!eval { $london->on(@$args); 1 }, 'on(' . join(' ', map { ref $_ ? ref $_ : $_ } @$args) . ') dies');
        like($@, $re, 'by name');
    }
    ok($london->on(year => 3000, month => 12, day => 31)->sunrise, 'the last day of 3000 is in');
    ok($london->on(year => -1999, month => 1, day => 1)->sunrise, 'the first day of -1999 is in');
    ok(!eval { Time::Keeper::Sun::Day::sunrise(bless(\(my $x = 'y'), 'Time::Keeper::Sun::Day')); 1 }, 'a forged day is refused');
    like($@, qr/^sunrise: not a Time::Keeper::Sun::Day/, 'by name');
    ok(!eval { $day->dawn(kind => 'twilight'); 1 }, 'an unknown twilight dies');
    like($@, qr/^dawn: no twilight is called 'twilight' \(civil, nautical or astronomical\)/, 'by name');
    ok(!eval { $day->dusk(depth => 6); 1 }, 'an unknown argument dies');
    like($@, qr/^dusk: unknown argument 'depth'/, 'by name');
}

# ---- USNO's one-day rows ----------------------------------------------------------

{
    my $file = -e 't/usno-oneday.tsv' ? 't/usno-oneday.tsv' : 'usno-oneday.tsv';
    open my $fh, '<', $file or BAIL_OUT("$file: $!");
    my %kind = ('Rise' => 'sunrises', 'Set' => 'sunsets', 'Upper Transit' => 'solar_noons', 'Lower Transit' => 'solar_midnights',
                'Begin Civil Twilight' => 'dawns', 'End Civil Twilight' => 'dusks');
    my ($rows, $events, $worst, $worst_name) = (0, 0, 0, '');
    while (<$fh>) {
        next if /^#/;
        chomp;
        my ($place, $date, $lat, $lon, $zone, $tz, $isdst, $sundata, $notes) = split /\t/;
        next unless defined $sundata;
        my ($y, $mo, $d) = split /-/, $date;
        my $sun = Time::Keeper::Sun->new(latitude => $lat, longitude => $lon, zone => $zone);
        my $day = $sun->on(year => $y, month => $mo, day => $d);
        my (%theirs, %note);
        for my $item (split /;/, $sundata) {
            my ($phen, $time) = split /=/, $item, 2;
            if (length $time) {
                my ($h, $mi) = split /:/, $time;
                push @{$theirs{$phen}}, Time::Keeper->new(year => $y, month => $mo, day => $d, hour => $h, minute => $mi, zone => 'UTC')->epoch - $tz * 3600;
            }
            else {
                $note{$phen} = 1;
            }
        }
        my $label = "$place $date";
        for my $phen (sort keys %kind) {
            my $method = $kind{$phen};
            my @ours = $day->$method;
            my @usno = @{$theirs{$phen} || []};
            # USNO lists the lower transit only on a day the sun is up throughout,
            # and the upper one not at all in a polar night: those are compared
            # only when it gives them.
            next if !@usno && $phen =~ /Transit/;
            is(scalar @ours, scalar @usno, "$label: " . scalar(@usno) . " of $phen");
            for my $i (0 .. $#usno) {
                last if $i > $#ours;
                my $diff = abs($ours[$i]->epoch - $usno[$i]);
                ($worst, $worst_name) = ($diff, "$label $phen") if $diff > $worst;
                # A minute; two above 60 degrees of latitude, where a sun that skims
                # the horizon climbs so slowly that a hundredth of a degree is
                # minutes; and within the pole's last degree, where the sun takes a
                # day to cross the horizon and a thousandth of a degree (the
                # parallax this method ignores) is four minutes, half an hour.
                my $mark = abs($lat) > 89 ? 1800 : abs($lat) > 60 ? 120 : 60;
                cmp_ok($diff, '<=', $mark, "$label: $phen " . $ours[$i]->strftime('%H:%M:%S') . " within $mark s of USNO's");
                $events++;
            }
        }
        if ($note{'Object continuously above the Horizon'}) {
            ok($day->is_polar_day, "$label: USNO says the sun was up all day, is_polar_day");
            ok(!defined $day->sunrise && !defined $day->sunset, "$label: and there is no sunrise or sunset");
            is($day->day_length->total('seconds'), $day->end->epoch - $day->start->epoch, "$label: day_length is the whole window");
        }
        elsif ($note{'Object continuously below the Horizon'}) {
            ok($day->is_polar_night, "$label: USNO says the sun was down all day, is_polar_night");
            ok(!defined $day->sunrise && !defined $day->sunset, "$label: and there is no sunrise or sunset");
            ok(!defined $day->day_length, "$label: and no day_length");
        }
        else {
            ok(!$day->is_polar_day && !$day->is_polar_night, "$label: neither polar flag");
        }
        if ($note{'Object continuously above the Twilight Limit'}) {
            ok(!defined $day->dawn && !defined $day->dusk, "$label: no civil twilight, the sun never that low");
        }
        if ($note{'Object continuously below the Twilight Limit'}) {
            ok(!defined $day->dawn && !defined $day->dusk, "$label: no civil twilight, the sun never that high");
        }
        $rows++;
    }
    close $fh;
    cmp_ok($rows, '>=', 80, "$rows days against USNO");
    note("$events events compared with USNO's minutes; the worst was $worst s ($worst_name)");
}

done_testing;
