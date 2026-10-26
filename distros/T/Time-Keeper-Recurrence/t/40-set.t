#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Time::Keeper;
use Time::Keeper::Recurrence;

# Sets: dates removed to the second and by the day, dates added and sorted
# in, rules merged without duplicates, EXRULEs read and applied, and the
# walking methods agreeing with one another on random sets.

my $R = 'Time::Keeper::Recurrence';
my $NY = 'America/New_York';
sub ny { Time::Keeper->new(zone => $NY, @_) }
sub fmt { my @o = map { $_->format('y-MM-dd HH:mm') } @_; wantarray ? @o : $o[0] }
my $far = Time::Keeper->new(year => 2100, month => 1, day => 1, zone => 'UTC');

my $start = ny(year => 2026, month => 10, day => 20, hour => 9);
my $tuth = $R->new(rrule => 'FREQ=WEEKLY;BYDAY=TU,TH', start => $start);

# ---- EXDATE to the second -------------------------------------------------
{
    my $thanks = ny(year => 2026, month => 11, day => 26, hour => 9);
    my $set = $tuth->with(exdate => [$thanks]);
    isa_ok($set, 'Time::Keeper::Recurrence::Set', 'with gives a Set');
    my @got = fmt($set->first(12));
    is_deeply(\@got, [map { "$_ 09:00" } qw(2026-10-20 2026-10-22 2026-10-27 2026-10-29 2026-11-03 2026-11-05 2026-11-10 2026-11-12 2026-11-17 2026-11-19 2026-11-24 2026-12-01)], 'EXDATE removes the one occurrence');
    ok(!$set->contains($thanks), 'contains: the removed one is not in');
    ok($set->contains(ny(year => 2026, month => 11, day => 24, hour => 9)), 'contains: the one before is');
    is(fmt($set->next(ny(year => 2026, month => 11, day => 25))), '2026-12-01 09:00', 'next skips the removed one');
    is(fmt($set->previous(ny(year => 2026, month => 11, day => 27))), '2026-11-24 09:00', 'previous skips the removed one');

    my $off = $tuth->with(exdate => [ny(year => 2026, month => 11, day => 26, hour => 9, second => 1)]);
    ok($off->contains($thanks), 'an EXDATE one second off removes nothing: to the second, not by the day');
    is(scalar(() = $off->first(12)), 12, 'and the twelve are still twelve');

    my $other_zone = Time::Keeper->new(year => 2026, month => 11, day => 26, hour => 14, zone => 'UTC');
    ok(!$tuth->with(exdate => $other_zone)->contains($thanks), 'an EXDATE given in another zone matches by instant');
}

# ---- EXDATE by the day -----------------------------------------------------
{
    my $twice = $R->new(rrule => 'FREQ=DAILY;BYHOUR=9,17;BYMINUTE=0', start => $start);
    my $set = $twice->with(exdate => '2026-10-22');
    my @got = fmt($set->between($start, ny(year => 2026, month => 10, day => 24)));
    is_deeply(\@got, ['2026-10-20 09:00', '2026-10-20 17:00', '2026-10-21 09:00', '2026-10-21 17:00', '2026-10-23 09:00', '2026-10-23 17:00'],
        'a whole-day EXDATE removes both occurrences of the day');
    my $one = $twice->with(exdate => ny(year => 2026, month => 10, day => 22, hour => 9));
    is(scalar(() = $one->between($start, ny(year => 2026, month => 10, day => 24))), 7, 'a timed EXDATE removes one of the two');
    my $dobj = $twice->with(exdate => Time::Keeper::Date->new(year => 2026, month => 10, day => 22));
    is(scalar(() = $dobj->between($start, ny(year => 2026, month => 10, day => 24))), 6, 'a Time::Keeper::Date is a whole day');
    my ($x) = $dobj->exdates;
    isa_ok($x, 'Time::Keeper::Date', 'exdates gives the day back as a Date');
    is("$x", '2026-10-22', 'the right day');

    # the day is the set's zone's day: 2026-10-22 in New York holds 23:30 on the 22nd, which is 03:30Z on the 23rd
    my $late = $R->new(rrule => 'FREQ=DAILY;BYHOUR=23;BYMINUTE=30', start => ny(year => 2026, month => 10, day => 20, hour => 23, minute => 30));
    my @l = fmt($late->with(exdate => '2026-10-22')->between($late->start, ny(year => 2026, month => 10, day => 24)));
    is_deeply(\@l, ['2026-10-20 23:30', '2026-10-21 23:30', '2026-10-23 23:30'], 'the day removed is the day in the set\'s zone');
}

# ---- RDATE -----------------------------------------------------------------
{
    my $a = ny(year => 2026, month => 12, day => 25, hour => 9);
    my $b = ny(year => 2026, month => 11, day => 1, hour => 10);
    my $set = $tuth->with(rdate => [$a, $b]);
    my @r = $set->rdates;
    is_deeply([fmt(@r)], ['2026-11-01 10:00', '2026-12-25 09:00'], 'rdates come back sorted');
    my @got = fmt($set->between(ny(year => 2026, month => 10, day => 29, hour => 12), ny(year => 2026, month => 11, day => 4)));
    is_deeply(\@got, ['2026-11-01 10:00', '2026-11-03 09:00'], 'an RDATE sorts into the walk');
    ok($set->contains($a), 'contains an RDATE');
    is(fmt($set->previous(ny(year => 2026, month => 11, day => 2))), '2026-11-01 10:00', 'previous finds an RDATE');
    my $dup = $tuth->with(rdate => ny(year => 2026, month => 10, day => 22, hour => 9));
    is(scalar(() = $dup->first(4)), 4, 'an RDATE the rule gives anyway comes once');
    is_deeply([fmt($dup->first(2))], ['2026-10-20 09:00', '2026-10-22 09:00'], 'and in its place');
    my $day = $tuth->with(rdate => '2026-12-25');
    my ($d) = $day->rdates;
    isa_ok($d, 'Time::Keeper::Date', 'a whole day added comes back as a Date');
    is(fmt($day->next(ny(year => 2026, month => 12, day => 24, hour => 12))), '2026-12-25 00:00', 'a whole day added is its midnight in the zone');
    my $same = $tuth->with(rdate => [$a, $a, $a]);
    is(scalar(() = $same->rdates), 1, 'the same date three times is one');
    ok(!eval { $tuth->with(rdate => 'yesterday'); 1 }, 'a word is not a date');
    like($@, qr/rdate takes Time::Keeper values, Time::Keeper::Date values or YYYY-MM-DD strings/, 'and says what is');
    my $removed_added = $tuth->with(rdate => $a, exdate => $a);
    ok(!$removed_added->contains($a), 'a date both added and removed is removed');
}

# ---- rules merged ------------------------------------------------------------
{
    my $tu = $R->new(rrule => 'FREQ=WEEKLY;BYDAY=TU', start => $start);
    my $th = $R->new(rrule => 'FREQ=WEEKLY;BYDAY=TH', start => $start);
    my $set = $tu->with(rule => $th);
    is(scalar(() = $set->rules), 2, 'two rules');
    is_deeply([fmt($set->first(8))], [fmt($tuth->first(8))], 'TU plus TH is TU,TH');
    my $both = $tu->with(rule => $tuth);
    is_deeply([fmt($both->first(8))], [fmt($tuth->first(8))], 'an instant two rules give comes once');
    my ($r1, $r2) = $set->rules;
    is($r1->rrule, 'FREQ=WEEKLY;BYDAY=TU', 'rules gives the rules back');
    is($r2->rrule, 'FREQ=WEEKLY;BYDAY=TH', 'in order');
    isa_ok($r1, 'Time::Keeper::Recurrence', 'as rules');

    my $london = $R->new(rrule => 'FREQ=DAILY', start => Time::Keeper->new(year => 2026, month => 10, day => 20, hour => 9, zone => 'Europe/London'));
    ok(!eval { $tu->with(rule => $london); 1 }, 'a rule in another zone cannot join');
    like($@, qr/share one zone/, 'and says so');
    my $later = $R->new(rrule => 'FREQ=DAILY', start => $start->plus(days => 1));
    ok(!eval { $tu->with(rule => $later); 1 }, 'a rule with another start cannot join');
    like($@, qr/share one start/, 'and says so');
    ok(!eval { $tu->with(rule => $set); 1 }, 'a set is not a rule');
    ok(!eval { $tu->with(frob => 1); 1 }, 'an unknown key dies');
    like($@, qr/unknown argument 'frob'/, 'naming it');
    ok(!eval { $tu->with('rdate'); 1 }, 'an odd list dies');

    my $many = $tu;
    my $s16 = $tu->with(rules => [($th) x 15]);
    is(scalar(() = $s16->rules), 16, 'sixteen rules fit');
    ok(!eval { $s16->with(rule => $th); 1 }, 'a seventeenth does not');
    like($@, qr/more than 16 rules in a set/, 'and the cap is named');
}

# ---- a cron in a set -------------------------------------------------------
{
    my $cron = $R->cron('0 9 * * 1-5', zone => 'UTC');
    my $set = $cron->with(exdate => '2026-12-25');
    is($set->zone, 'UTC', 'a cron set is in the cron\'s zone');
    ok(!defined $set->start, 'and has no start');
    my $from = Time::Keeper->new(year => 2026, month => 12, day => 24, hour => 10, zone => 'UTC');
    is(fmt($set->next($from)), '2026-12-28 09:00', 'Christmas skipped, the weekend too');
    is($set->gap, 'skip', 'the cron\'s gap choice');
    is($set->overlap, 'both', 'and overlap choice');
    ok(!$set->is_finite, 'a cron set is not finite');
    ok(!eval { $R->cron('@every 1h', zone => 'UTC')->with(exdate => '2026-12-25'); 1 }, 'an @every cron cannot join a set');
    like($@, qr/an \@every cron has no occurrences of its own/, 'and says why');
}

# ---- EXRULE ----------------------------------------------------------------
{
    my $set = $R->parse_ical("DTSTART;TZID=America/New_York:20261020T090000\r\nRRULE:FREQ=DAILY;COUNT=14\r\nEXRULE:FREQ=WEEKLY;BYDAY=SA,SU\r\n");
    is(scalar(() = $set->rules), 1, 'one rule');
    is(scalar(() = $set->exrules), 1, 'one EXRULE');
    my @got = fmt($set->first(20));
    is(scalar @got, 10, 'fourteen days less two weekends is ten');
    ok(!grep({ /2026-10-2[45]/ } @got), 'the weekend is out');
    unlike($set->ical, qr/EXRULE/, 'an EXRULE is never written');
    is(fmt($set->previous(ny(year => 2026, month => 10, day => 26))), '2026-10-23 09:00', 'previous steps over the EXRULE\'s days');
}

# ---- what a set says -------------------------------------------------------
{
    my $set = $tuth->with(exdate => '2026-12-25');
    is($set->zone, $NY, 'zone');
    is(fmt($set->start), '2026-10-20 09:00', 'start');
    is($set->gap, 'forward', 'gap');
    is($set->overlap, 'earlier', 'overlap');
    ok(!$set->is_finite, 'infinite rule, infinite set');
    ok($R->new(rrule => 'FREQ=DAILY;COUNT=3', start => $start)->with(exdate => '2026-10-21')->is_finite, 'finite rule, finite set');
    is(scalar(() = $set->rdates), 0, 'no rdates');
    is(scalar(() = $set->exdates), 1, 'one exdate');
    ok($set, 'a set is true');
    my $it = $set->iterate;
    my @it;
    while (my $t = $it->()) { push @it, fmt($t); last if @it == 5 }
    is_deeply(\@it, [fmt($set->first(5))], 'iterate gives what first gives');
    my $it2 = $tuth->with(exdate => '2026-12-29')->iterate(ny(year => 2026, month => 12, day => 24, hour => 12));
    is(fmt($it2->()), '2026-12-31 09:00', 'iterate from a moment skips the removed day');
    my $fin = $R->new(rrule => 'FREQ=DAILY;COUNT=2', start => $start)->with(rdate => '2026-10-25');
    my $it3 = $fin->iterate;
    my @all;
    while (my $t = $it3->()) { push @all, fmt($t) }
    is_deeply(\@all, ['2026-10-20 09:00', '2026-10-21 09:00', '2026-10-25 00:00'], 'iterate ends after the last, the RDATE last');
    ok(!defined $it3->(), 'and stays ended');
}

# ---- with never changes the original -----------------------------------------
{
    my $set = $tuth->with(exdate => '2026-12-25');
    my $more = $set->with(exdate => '2026-12-31', rdate => '2027-01-02');
    is(scalar(() = $set->exdates), 1, 'the first set keeps one exdate');
    is(scalar(() = $more->exdates), 2, 'the second has two');
    is(scalar(() = $more->rdates), 1, 'and the rdate');
    is($tuth->rrule, 'FREQ=WEEKLY;BYDAY=TU,TH', 'the rule is as it was');
    is_deeply([fmt($tuth->first(3))], ['2026-10-20 09:00', '2026-10-22 09:00', '2026-10-27 09:00'], 'and walks as it did');
    isa_ok($more, 'Time::Keeper::Recurrence::Set', 'with on a set gives a set');
}

# ---- the methods agree on random sets ------------------------------------------
{
    my $seed = $ENV{TKR_SEED} || 20261018;
    srand $seed;
    diag("seed $seed") if $ENV{TKR_SEED};
    my @days = qw(MO TU WE TH FR SA SU);
    my $bad = 0;
    for my $i (1 .. 1000) {
        my $freq = (qw(DAILY WEEKLY MONTHLY))[int rand 3];
        my $rrule = "FREQ=$freq";
        $rrule .= ';INTERVAL=' . (1 + int rand 3) if rand() < 0.4;
        if ($freq ne 'DAILY' || rand() < 0.5) {
            my %d = map { $days[int rand 7] => 1 } 1 .. (1 + int rand 3);
            $rrule .= ';BYDAY=' . join(',', grep { $d{$_} } @days) if rand() < 0.7;
        }
        my $s = ny(year => 2026, month => 1 + int rand 12, day => 1 + int rand 28, hour => int rand 24, minute => int rand 60, gap => 'forward');
        my $rule = eval { $R->new(rrule => $rrule, start => $s) } or next;
        my @occ = $rule->first(30);
        my @ex = map { $occ[int rand @occ] } 1 .. int rand 4;
        push @ex, $occ[int rand @occ]->format('y-MM-dd') if rand() < 0.5;
        my @rd = map { $s->plus(seconds => int rand 120 * 86400) } 1 .. int rand 4;
        push @rd, $s->plus(seconds => (1 + int rand 120) * 86400)->format('y-MM-dd') if rand() < 0.3;
        my $set = $rule->with(exdate => \@ex, rdate => \@rd);
        $set = $set->with(rule => $R->new(rrule => 'FREQ=WEEKLY;BYDAY=' . $days[int rand 7], start => $s)) if rand() < 0.3;

        my @first = $set->first(20);
        my @between = $set->between($s, $far);
        splice @between, 20;
        my @next;
        my $t = $s->minus(seconds => 1);
        while (@next < 20 && defined($t = $set->next($t))) { push @next, $t }
        my @prev;
        $t = $first[-1]->plus(seconds => 1);
        while (@prev < 20 && defined($t = $set->previous($t))) { unshift @prev, $t }
        my $ok = 1;
        for my $pair ([\@first, \@between, 'between'], [\@first, \@next, 'next'], [\@first, \@prev, 'previous']) {
            my ($a, $b, $name) = @$pair;
            if (join(' ', map { $_->epoch } @$a) ne join(' ', map { $_->epoch } @$b)) {
                $ok = 0;
                diag("$rrule from $s with exdate [@ex] rdate [@rd]: first and $name differ\n  first: @{[fmt(@$a)]}\n  $name: @{[fmt(@$b)]}");
            }
        }
        for my $o (@first) {
            next if $set->contains($o);
            $ok = 0;
            diag("$rrule: contains misses $o");
        }
        for my $x (grep { ref } @ex) {
            next if !$set->contains($x);
            $ok = 0;
            diag("$rrule: contains has the removed $x");
        }
        my $in_order = 1;
        for my $k (1 .. $#first) { $in_order = 0 if $first[$k]->epoch <= $first[$k - 1]->epoch }
        $ok = 0, diag("$rrule: out of order or doubled") if !$in_order;
        $bad++ if !$ok;
        last if $bad > 5;
    }
    is($bad, 0, "first, between, next, previous and contains agree on 1,000 random sets (seed $seed)");
}

# ---- the between cap ------------------------------------------------------
{
    my $u = Time::Keeper->new(year => 2026, month => 1, day => 1, zone => 'UTC');
    my $daily = $R->new(rrule => 'FREQ=DAILY', start => $u)->with(rdate => $u->plus(hours => 1));
    my $ok = eval { $daily->between($u, $u->plus(years => 40000)); 1 };
    ok(!$ok && $@ =~ /more than 10000000 occurrences; use iterate/, 'a set\'s between is capped') or diag($ok ? 'did not die' : $@);
    is(scalar(() = $daily->between($u, $u->plus(days => 3))), 4, 'and below the cap gives them all');
}

done_testing;
