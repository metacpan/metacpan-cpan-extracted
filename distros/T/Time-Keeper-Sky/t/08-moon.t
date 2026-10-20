#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Time::Keeper;
use Time::Keeper::Moon;

# The moon's phases against the book's examples 49.a, 49.b and 48.a (the
# port's digits, sources/meeus-examples.tsv) and against USNO's phases for
# 2026, 1900 and 2100 (t/usno-phases.tsv, to the minute UT); the fraction
# and the day's name against USNO's one-day data (t/usno-moon-oneday.tsv).

sub utc { Time::Keeper->new(@_, zone => 'UTC') }
sub near { my ($got, $want, $tol, $name) = @_; cmp_ok(abs($got - $want), '<=', $tol, "$name: $got within $tol of $want") }

# ---- examples 49.a and 49.b, in TD ----------------------------------------------

is(Time::Keeper::Sun::_phase_snap(1977.13, 0), -283, 'example 49.a: k is -283');
near(Time::Keeper::Sun::_phase_mean_jde(-283), 2443192.94102, 1e-5, 'the mean new moon');
near(Time::Keeper::Sun::_phase_jde(-283), 2443192.65118, 1e-5, 'the true new moon, 1977 February 18 at 03:37:42 TD');
is(Time::Keeper::Sun::_phase_snap(2044.04, 3), 544.75, 'example 49.b: k is 544.75');
near(Time::Keeper::Sun::_phase_mean_jde(544.75), 2467636.88597, 1e-5, 'the mean last quarter');
near(Time::Keeper::Sun::_phase_jde(544.75), 2467636.49186, 1e-5, 'the true last quarter, 2044 January 21 at 23:48:17 TD');

# and in UT, through Delta T: 48.184 s in 1977 (the table), the held 69.184 in 2044
{
    my $nm = Time::Keeper::Moon->previous(phase => 'new', before => utc(year => 1977, month => 2, day => 19));
    isa_ok($nm, 'Time::Keeper');
    near($nm->epoch, utc(year => 1977, month => 2, day => 18, hour => 3, minute => 37, second => 42)->epoch - 48.184, 1,
         '49.a in UT: 03:36:54, the TD less the 48 s of Delta T');
    my $lq = Time::Keeper::Moon->next(phase => 'last_quarter', after => utc(year => 2044, month => 1, day => 15));
    near($lq->epoch, utc(year => 2044, month => 1, day => 21, hour => 23, minute => 48, second => 17)->epoch - 69.184, 1,
         '49.b in UT: 23:47:08, the TD less the held 69 s (after the leap table, a guess)');
    is($lq->zone_name, 'UTC', 'in UTC unless told');
    is(Time::Keeper::Moon->next(phase => 'last', after => utc(year => 2044, month => 1, day => 15), zone => 'Asia/Tokyo')->zone_name, 'Asia/Tokyo', 'or in the zone given');
    is($lq->nanosecond, 0, 'rounded to the second');
}

# ---- example 48.a ----------------------------------------------------------------

{
    my ($e, $i, $k) = Time::Keeper::Sun::_moon_at_jde(2448724.5);
    near($i, 68.88, 0.01, 'example 48.a by 48.4: the phase angle');
    near($k, 0.6801, 0.0005, 'and the fraction by 48.4');
    near($k, 0.6786, 0.002, 'within two thousandths of the exact method');
    my ($ee, $ie, $ke) = Time::Keeper::Sun::_moon_exact_jde(2448724.5);
    near($ie, 69.0756, 0.0005, 'example 48.a by 48.2 and 48.3: the phase angle');
    near($ke, 0.6786, 0.00005, "and the fraction, to the book's four places");
    near(Time::Keeper::Moon->illumination(Time::Keeper->from_epoch(703036800 - 58)), 0.6786, 0.0002, 'illumination at that instant in UT');
    ok($e > 90 && $e < 120, "the elongation, waxing gibbous ($e)");
}

# ---- the shape --------------------------------------------------------------------

{
    my $t = utc(year => 2026, month => 10, day => 15, hour => 12);
    is(Time::Keeper::Moon->phase_name($t), 'waxing_crescent', 'phase_name on 15 October 2026');
    near(Time::Keeper::Moon->illumination($t), 0.22, 0.02, 'illumination about 22% (USNO)');
    near(Time::Keeper::Moon->age($t), 4.8, 0.1, 'age about 4.8 days (the new moon was the 10th at 15:50)');
    ok(Time::Keeper::Moon->elongation($t) > 45 && Time::Keeper::Moon->elongation($t) < 67.5, 'elongation in the crescent eighth');
    # The phase angle is 180 less the elongation only for a moon on the ecliptic
    # at an infinite distance; its latitude (up to 5.1 degrees) parts them.
    near(Time::Keeper::Moon->phase_angle($t), 180 - Time::Keeper::Moon->elongation($t), 5.2, "phase angle within the moon's latitude of 180 less the elongation while waxing");
    is(Time::Keeper::Moon->lunation(utc(year => 2000, month => 1, day => 7)), 953, 'the lunation of 7 January 2000 is Brown\'s 953');
    is(Time::Keeper::Moon->lunation(utc(year => 2000, month => 1, day => 6)), 952, 'and the day before, before the new moon at 18:14, the 952nd');
    is(Time::Keeper::Moon->lunation($t), 953 + 331, '331 lunations later in October 2026');
    is(Time::Keeper::Moon->phase_name($t->epoch), 'waxing_crescent', 'an epoch does');
}

# the eight names round one lunation, from the new moon of 10 October 2026
{
    my $new = Time::Keeper::Moon->next(phase => 'new', after => utc(year => 2026, month => 10, day => 1));
    like("$new", qr/^2026-10-10T15:(49|50|51):\d\dZ$/, 'the new moon of October 2026 at 15:50 (USNO)');
    my @names;
    push @names, Time::Keeper::Moon->phase_name($new->plus(seconds => int(29.53 * 86400 * $_ / 8 + 3600))) for 0 .. 7;
    is(join(' ', @names), 'new waxing_crescent first_quarter waxing_gibbous full waning_gibbous last_quarter waning_crescent', 'the eight names in order');
    # A new moon is up to 5 degrees off the sun's line, so a sliver is lit: 0.0019 at most in 2026.
    ok(Time::Keeper::Moon->illumination($new) < 0.002, 'almost nothing lit at the new moon');
    my $full = Time::Keeper::Moon->next(phase => 'full', after => $new);
    ok(Time::Keeper::Moon->illumination($full) > 0.998, 'almost all lit at the full moon');
    ok(Time::Keeper::Moon->elongation($full->minus(hours => 1)) < 180 && Time::Keeper::Moon->elongation($full->plus(hours => 1)) > 180, 'the elongation passes 180 at the full moon');
    near(Time::Keeper::Moon->age($new->plus(days => 10)), 10, 0.001, 'age counts from the new moon');
    is("${\ Time::Keeper::Moon->previous(phase => 'new', before => $full) }", "$new", 'previous new from the full moon is that new moon');
    is("${\ Time::Keeper::Moon->next(phase => 'full', after => $full->minus(seconds => 1)) }", "$full", 'next full from a second before it is it');
    isnt("${\ Time::Keeper::Moon->next(phase => 'full', after => $full) }", "$full", 'next is strictly after');
    isnt("${\ Time::Keeper::Moon->previous(phase => 'full', before => $full) }", "$full", 'previous strictly before');
    cmp_ok(Time::Keeper::Moon->next(phase => 'full', after => $full)->epoch - $full->epoch, '>', 29 * 86400, 'a lunation on');
}

# phases over a year, and across a year boundary
{
    my @p = Time::Keeper::Moon->phases(from => utc(year => 2026, month => 1, day => 1), to => utc(year => 2027, month => 1, day => 1));
    is(scalar @p, 50, '50 phases in 2026');
    my $ok = 1;
    $ok &&= $p[$_ - 1][1] < $p[$_][1] for 1 .. $#p;
    ok($ok, 'in order');
    my %next = (new => 'first_quarter', first_quarter => 'full', full => 'last_quarter', last_quarter => 'new');
    $ok = 1;
    $ok &&= $next{$p[$_ - 1][0]} eq $p[$_][0] for 1 .. $#p;
    ok($ok, 'each kind followed by the next');
    my @q = Time::Keeper::Moon->phases(from => utc(year => 2026, month => 12, day => 20), to => utc(year => 2027, month => 1, day => 10));
    ok(@q >= 2 && $q[0][1]->year == 2026 && $q[-1][1]->year == 2027, 'across the year boundary');
    ok(!eval { Time::Keeper::Moon->phases(from => utc(year => 2026, month => 1, day => 1), to => utc(year => 2027, month => 6, day => 1)); 1 }, 'more than a year dies');
    like($@, qr/at most a year at a time/, 'by name');
}

# arguments and the range
ok(!eval { Time::Keeper::Moon->next(after => utc(year => 2026, month => 1, day => 1)); 1 }, 'next without a phase dies');
like($@, qr/^Time::Keeper::Moon->next needs phase => new, first_quarter, full or last_quarter/, 'by name');
ok(!eval { Time::Keeper::Moon->next(phase => 'blue'); 1 }, 'an unknown phase dies');
like($@, qr/no phase is called 'blue'/, 'by name');
ok(!eval { Time::Keeper::Moon->next(phase => 'full', before => 1); 1 }, 'before on next dies');
like($@, qr/unknown argument 'before'/, 'by name');
ok(!eval { Time::Keeper::Moon->phases(from => 1); 1 }, 'phases without to dies');
ok(!eval { Time::Keeper::Moon->phase_name(utc(year => 3001, month => 1, day => 1)); 1 }, 'the year 3001 dies');
like($@, qr/^phase_name: the year 3001 is outside/, 'by name');
ok(!eval { Time::Keeper::Moon->age('soon'); 1 }, 'a word dies');
ok(Time::Keeper::Moon->next(phase => 'new') > Time::Keeper->now->minus(hours => 1), 'next without after is after now');
{
    local $Time::Keeper::CLOCK = utc(year => 2026, month => 10, day => 15);
    like("${\ Time::Keeper::Moon->next(phase => 'full') }", qr/^2026-10-26T04:1/, 'and now is the test clock');
}

# ---- USNO's phases -------------------------------------------------------------------

{
    my $file = -e 't/usno-phases.tsv' ? 't/usno-phases.tsv' : 'usno-phases.tsv';
    open my $fh, '<', $file or BAIL_OUT("$file: $!");
    my (%by_year, %kind);
    %kind = ('New Moon' => 'new', 'First Quarter' => 'first_quarter', 'Full Moon' => 'full', 'Last Quarter' => 'last_quarter');
    while (<$fh>) {
        next if /^#/;
        chomp;
        my ($y, $m, $d, $time, $phase) = split /\t/;
        next unless defined $phase;
        my ($h, $mi) = split /:/, $time;
        push @{$by_year{$y}}, [$kind{$phase}, utc(year => $y, month => $m, day => $d, hour => $h, minute => $mi)->epoch];
    }
    close $fh;
    my ($n, $worst, $worst_name) = (0, 0, '');
    for my $y (sort keys %by_year) {
        my @usno = @{$by_year{$y}};
        my @ours = Time::Keeper::Moon->phases(from => utc(year => $y, month => 1, day => 1), to => utc(year => $y + 1, month => 1, day => 1)->minus(seconds => 1));
        is(scalar @ours, scalar @usno, "$y: " . scalar(@usno) . ' phases');
        for my $i (0 .. $#usno) {
            last if $i > $#ours;
            is($ours[$i][0], $usno[$i][0], "$y phase $i is a $usno[$i][0]");
            # USNO's minute, or the one either side: it rounds, and so does this.
            my $diff = $ours[$i][1]->epoch - $usno[$i][1];
            my $minutes = int(($ours[$i][1]->epoch - $ours[$i][1]->epoch % 60) / 60) - int($usno[$i][1] / 60);
            cmp_ok(abs($minutes), '<=', 1, "$y $usno[$i][0] " . $ours[$i][1]->strftime('%m-%d %H:%M:%S') . " is USNO's minute or an adjacent one");
            ($worst, $worst_name) = (abs($diff), "$y $usno[$i][0] $i") if abs($diff) > $worst;
            $n++;
        }
    }
    note("$n phases against USNO; the largest difference from USNO's minute was $worst s ($worst_name)");
}

# ---- USNO's one-day moon data ---------------------------------------------------------

{
    my $file = -e 't/usno-moon-oneday.tsv' ? 't/usno-moon-oneday.tsv' : 'usno-moon-oneday.tsv';
    open my $fh, '<', $file or BAIL_OUT("$file: $!");
    my %kind = ('New Moon' => 'new', 'First Quarter' => 'first_quarter', 'Full Moon' => 'full', 'Last Quarter' => 'last_quarter');
    my ($rows, $worst) = (0, 0);
    while (<$fh>) {
        next if /^#/;
        chomp;
        my ($place, $date, $lat, $lon, $zone, $tz, $frac, $cur, $cphase, $cdate, $ctime) = split /\t/;
        next unless defined $ctime;
        my ($y, $m, $d) = split /-/, $date;
        my $day = Time::Keeper::Moon->on(Time::Keeper::Date->new(year => $y, month => $m, day => $d), zone => $zone);
        isa_ok($day, 'Time::Keeper::Moon::Day');
        is("${\ $day->date }", $date, "$place $date: the date");
        (my $pct = $frac) =~ s/%//;
        my $diff = abs($day->illumination - $pct / 100);
        $worst = $diff if $diff > $worst;
        cmp_ok($diff, '<=', 0.006, "$place $date: illumination " . sprintf('%.3f', $day->illumination) . " within 0.006 of USNO's $frac at noon (its rounding to a percent, and a little)");
        # USNO's name is by the rounded fraction at noon; this dist's is by the
        # principal phase falling in the civil day. They agree except on the day
        # of a quarter, which USNO never names so, and at 0%, 100% and 50%.
        (my $usno_name = lc $cur) =~ s/ /_/g;
        $usno_name =~ s/^(new|full)_moon$/$1/;
        if (defined $day->phase) {
            like($day->phase_name, qr/^(new|first_quarter|full|last_quarter)$/, "$place $date: a principal phase falls in the day, $cur at USNO");
            is($day->phase_name, $kind{$cphase}, "$place $date: and it is USNO's closest phase, $cphase");
            my ($cy, $cm, $cd) = split /-/, $cdate;
            my ($ch, $cmi) = split /:/, $ctime;
            my $usno_sec = utc(year => $cy, month => $cm, day => $cd, hour => $ch, minute => $cmi)->epoch - $tz * 3600;
            cmp_ok(abs($day->phase->epoch - $usno_sec), '<=', 90, "$place $date: at USNO's time $cdate $ctime");
            is($day->phase->zone_name, $zone, 'in the zone');
        }
        elsif ($usno_name =~ /^(new|full|first_quarter|last_quarter)$/) {
            fail("$place $date: USNO names a principal phase ($cur) but none falls in the civil day here");
        }
        else {
            is($day->phase_name, $usno_name, "$place $date: $cur");
        }
        $rows++;
    }
    close $fh;
    cmp_ok($rows, '>=', 30, "$rows days against USNO");
    note("worst illumination difference $worst");
}

# the window decides: the new moon of 10 October 2026, 15:50 UT, is the 11th in Tokyo
{
    my $date = Time::Keeper::Date->new(year => 2026, month => 10, day => 10);
    ok(defined Time::Keeper::Moon->on($date)->phase, 'in UTC the 10th holds the new moon');
    is(Time::Keeper::Moon->on($date)->phase_name, 'new', 'and is named new');
    ok(!defined Time::Keeper::Moon->on($date, zone => 'Asia/Tokyo')->phase, 'in Tokyo the 10th does not');
    is(Time::Keeper::Moon->on($date, zone => 'Asia/Tokyo')->phase_name, 'waning_crescent', 'it is the last waning crescent');
    my $tk = Time::Keeper::Moon->on($date->plus(days => 1), zone => 'Asia/Tokyo');
    is($tk->phase_name, 'new', 'the 11th does');
    like("${\ $tk->phase }", qr/^2026-10-11T00:(49|50|51):\d\d\+09:00$/, 'at 00:50 Tokyo time');
    is($tk->zone_name, 'Asia/Tokyo', 'zone_name');
    is("${\ $tk->start }", '2026-10-11T00:00:00+09:00', 'start');
    is("${\ $tk->noon }", '2026-10-11T12:00:00+09:00', 'noon');
    is(Time::Keeper::Moon->on(Time::Keeper->new(year => 2026, month => 10, day => 11, hour => 3, zone => 'Asia/Tokyo'))->phase_name, 'new',
       'a value gives its date in the zone given (UTC here: the 10th, 18:00)');
    is(Time::Keeper::Moon->on($date, zone => 'Asia/Tokyo', locale => 'ja')->start->locale, 'ja', 'the locale is carried');
    ok(!eval { Time::Keeper::Moon->on('2026-10-10'); 1 }, 'a string dies');
    like($@, qr/^Time::Keeper::Moon->on takes a Time::Keeper::Date or a Time::Keeper value/, 'by name');
    ok(!eval { Time::Keeper::Moon->on($date, zone => 'floating'); 1 }, 'the floating zone dies');
    like($@, qr/the floating zone has no day/, 'by name');
    ok(!eval { Time::Keeper::Moon::Day::phase(bless(\(my $x = 'y'), 'Time::Keeper::Moon::Day')); 1 }, 'a forged day is refused');
    my ($s, $e) = ($tk->start->epoch, $tk->end->epoch);
    ok(Time::Keeper::Sun::_moonday_holds($tk, $s), 'the first second of the day is in it');
    ok(!Time::Keeper::Sun::_moonday_holds($tk, $s - 1), 'the second before is not');
    ok(Time::Keeper::Sun::_moonday_holds($tk, $e - 1), 'the last second is in it');
    ok(!Time::Keeper::Sun::_moonday_holds($tk, $e), "the next midnight is the next day's");
}

done_testing;
