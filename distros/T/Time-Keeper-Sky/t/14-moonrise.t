#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Time::Keeper;
use Time::Keeper::Sun;
use Time::Keeper::Moon;

# Moonrise, moonset and the moon's upper transit on a civil day from a
# place, against USNO's one-day data (t/usno-moon-events.tsv: 159 days at
# twenty places, the moon's events to the minute in the day's own offset).

sub near { my ($got, $want, $tol, $name) = @_; cmp_ok(abs($got - $want), '<=', $tol, "$name: $got within $tol of $want") }
sub hm { $_[0]->strftime('%H:%M') }

my $london = Time::Keeper::Sun->new(place => 'Europe/London');
my $oct15 = Time::Keeper::Date->new(year => 2026, month => 10, day => 15);

# ---- the shape --------------------------------------------------------------

{
    my $d = Time::Keeper::Moon->on($oct15, place => $london);
    like(hm($d->moonrise), qr/^13:1[45]$/, 'London 15 October 2026: moonrise 13:15 (USNO)');
    like(hm($d->moon_transit), qr/^16:3[67]$/, 'the transit 16:36');
    like(hm($d->moonset), qr/^19:5[56]$/, 'moonset 19:56');
    is($d->moonrise->zone_name, 'Europe/London', 'in the place\'s zone');
    is($d->moonrise->nanosecond, 0, 'to the second');
    is(scalar(my @r = $d->moonrises), 1, 'one moonrise');
    is(scalar(my @s = $d->moonsets), 1, 'one moonset');
    is(scalar(my @t = $d->moon_transits), 1, 'one transit');
    ok(!$d->is_moon_up_all_day && !$d->is_moon_down_all_day, 'neither flag');
    is(join(' ', map { $_->[0] } $d->events), 'moonrise moon_transit moonset', 'events in order');
    my $q = Time::Keeper::Moon->on(Time::Keeper::Date->new(year => 2026, month => 10, day => 18), place => $london);
    is(join(' ', map { $_->[0] } $q->events), 'moonrise first_quarter moon_transit moonset', 'with the day\'s phase among them');
    is(join(' ', map { $_->[0] } Time::Keeper::Moon->on(Time::Keeper::Date->new(year => 2026, month => 10, day => 18))->events), 'first_quarter',
       'without a place, the phase alone');
    my $bare = Time::Keeper::Moon->on($oct15);
    for my $m (qw(moonrise moonset moon_transit moonrises moonsets moon_transits is_moon_up_all_day is_moon_down_all_day)) {
        ok(!eval { $bare->$m; 1 }, "$m without a place dies");
        like($@, qr/^$m: the day was made without a place; give place => to Time::Keeper::Moon->on/, 'by name');
    }
}

# ---- searches from an instant -------------------------------------------------------

{
    my $t = Time::Keeper->new(year => 2026, month => 10, day => 15, zone => 'Europe/London');
    my $rise = Time::Keeper::Moon->next_moonrise($t, place => $london);
    is("$rise", "${\ Time::Keeper::Moon->on($oct15, place => $london)->moonrise }", 'next_moonrise from midnight is the day\'s');
    ok(Time::Keeper::Moon->next_moonrise($rise, place => $london) > $rise, 'and from that moonrise, strictly after');
    like(hm(Time::Keeper::Moon->next_moonrise($rise, place => $london)), qr/^14:0[67]$/, 'the next day\'s, 14:07');
    ok(Time::Keeper::Moon->previous_moonrise($rise, place => $london) < $rise, 'previous strictly before');
    like(hm(Time::Keeper::Moon->next_moonset($t, place => $london)), qr/^19:5[56]$/, 'next_moonset');
    like(hm(Time::Keeper::Moon->previous_moonset($t, place => $london)), qr/^1[89]:/, 'previous_moonset, the evening before');
    like(hm(Time::Keeper::Moon->next_moon_transit($t, place => $london)), qr/^16:3[67]$/, 'next_moon_transit');
    ok(Time::Keeper::Moon->previous_moon_transit($t, place => $london) < $t, 'previous_moon_transit');
    is(Time::Keeper::Moon->next_moonrise($t, place => $london, zone => 'UTC')->zone_name, 'UTC', 'zone => over the place');
    ok(!eval { Time::Keeper::Moon->next_moonrise($t); 1 }, 'without a place dies');
    like($@, qr/^Time::Keeper::Moon->next_moonrise needs place => a Time::Keeper::Sun place/, 'by name');
    ok(!eval { Time::Keeper::Moon->next_moonset($t, place => $london, after => $t); 1 }, 'an unknown argument dies');
    like($@, qr/unknown argument 'after'/, 'by name');
}

# ---- a month at London: a day without a moonrise, a day without a moonset ----------

{
    my (%none, $rises);
    for my $day (1 .. 31) {
        my $d = Time::Keeper::Moon->on(Time::Keeper::Date->new(year => 2026, month => 10, day => $day), place => $london);
        my @r = $d->moonrises;
        my @s = $d->moonsets;
        $none{rise} = $day if !@r;
        $none{set} = $day if !@s;
        $rises += @r;
    }
    ok($none{rise}, "a day in October 2026 with no moonrise at London: the $none{rise}th") if $none{rise};
    ok($none{set}, "a day with no moonset: the $none{set}th") if $none{set};
    ok($none{rise} && $none{set}, 'the moon misses a rise and a set each month');
    cmp_ok($rises, '<=', 31, "$rises moonrises in 31 days");
    cmp_ok($rises, '>=', 29, 'about one a day less one a month');
}

# ---- two of a kind in one civil day (S3) ------------------------------------------

# North of about 60 degrees the moon's daily delay can turn negative, and a
# civil day holds two moonrises or two moonsets (USNO lists both).
{
    my $tromso = Time::Keeper::Sun->new(latitude => 69.6492, longitude => 18.9553, zone => 'Europe/Oslo');
    my $d = Time::Keeper::Moon->on(Time::Keeper::Date->new(year => 2026, month => 6, day => 11), place => $tromso);
    my @r = $d->moonrises;
    is(scalar @r, 2, 'Tromso 11 June 2026: two moonrises (USNO: 00:24 and 23:39)');
    like(hm($r[0]), qr/^00:2[45]$/, 'the first');
    like(hm($r[1]), qr/^23:3[89]$/, 'the second');
    is("${\ $d->moonrise }", "$r[0]", 'the singular is the first (S3)');
    is(join(' ', map { $_->[0] } $d->events), 'moonrise moon_transit moonset moonrise', 'events show both');
    my $e = Time::Keeper::Moon->on(Time::Keeper::Date->new(year => 2026, month => 5, day => 28), place => $tromso);
    is(scalar(my @s = $e->moonsets), 2, '28 May: two moonsets (USNO: 00:58 and 23:57)');
    is("${\ $e->moonset }", "$s[0]", 'the singular the first');
}

# ---- the 25-hour day ---------------------------------------------------------------

{
    my $d = Time::Keeper::Moon->on(Time::Keeper::Date->new(year => 2026, month => 10, day => 25), place => $london);
    is($d->end->epoch - $d->start->epoch, 25 * 3600, 'the long day');
    ok(defined $d->moonrise || defined $d->moonset, 'with its moon events');
}

# ---- USNO's rows -----------------------------------------------------------------

{
    my $file = -e 't/usno-moon-events.tsv' ? 't/usno-moon-events.tsv' : 'usno-moon-events.tsv';
    open my $fh, '<', $file or BAIL_OUT("$file: $!");
    my %kind = ('Rise' => 'moonrises', 'Set' => 'moonsets', 'Upper Transit' => 'moon_transits');
    my ($rows, $events, $worst, $worst_name, @two) = (0, 0, 0, '');
    my %places;
    while (<$fh>) {
        next if /^#/;
        chomp;
        my ($place, $date, $lat, $lon, $zone, $tz, $moondata) = split /\t/;
        next unless defined $moondata;
        my ($y, $mo, $d) = split /-/, $date;
        my $sun = $places{"$lat $lon $zone"} //= Time::Keeper::Sun->new(latitude => $lat, longitude => $lon, zone => $zone);
        my $day = Time::Keeper::Moon->on(Time::Keeper::Date->new(year => $y, month => $mo, day => $d), place => $sun);
        my (%theirs, %note);
        for my $item (split /;/, $moondata) {
            my ($phen, $time) = split /=/, $item, 2;
            if (defined $time && length $time) {
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
            next if !@usno && $phen eq 'Upper Transit';
            push @two, "$label $phen" if @usno > 1;
            is(scalar @ours, scalar @usno, "$label: " . scalar(@usno) . " $phen");
            for my $i (0 .. $#usno) {
                last if $i > $#ours;
                my $diff = abs($ours[$i]->epoch - $usno[$i]);
                ($worst, $worst_name) = ($diff, "$label $phen") if $diff > $worst;
                # T7: two minutes below 60 degrees of latitude, five above
                my $mark = abs($lat) > 60 ? 300 : 120;
                cmp_ok($diff, '<=', $mark, "$label: $phen " . $ours[$i]->strftime('%H:%M:%S') . " within $mark s of USNO's");
                $events++;
            }
        }
        if ($note{'Object continuously above the Horizon'}) {
            ok($day->is_moon_up_all_day, "$label: USNO says the moon was up all day");
        }
        elsif ($note{'Object continuously below the Horizon'}) {
            ok($day->is_moon_down_all_day, "$label: USNO says the moon was down all day");
        }
        else {
            ok(!$day->is_moon_up_all_day && !$day->is_moon_down_all_day, "$label: neither flag");
        }
        $rows++;
    }
    close $fh;
    cmp_ok($rows, '>=', 150, "$rows days against USNO");
    note("$events moon events compared with USNO's minutes; the worst was $worst s ($worst_name)");
    note("days with two of a kind at USNO: @two") if @two;
}

done_testing;
