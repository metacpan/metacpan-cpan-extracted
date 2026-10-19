#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Time::Keeper;
use Time::Keeper::Recurrence;

# Rules in another calendar (RFC 7529): the RFC's own examples, Rosh
# Hashanah and the Umm al-Qura 15th against Time::Keeper's calendars, the
# three SKIP choices on a day and on a leap month, the implied leap month,
# the text back, the errors, and the walking methods agreeing on random
# rules in random calendars.

my $R = 'Time::Keeper::Recurrence';
sub dies_like {
    my ($code, $re, $name) = @_;
    my $ok = eval { $code->(); 1 };
    ok(!$ok && $@ =~ $re, $name) or diag($ok ? 'did not die' : $@);
}
sub greg { map { $_->in_calendar('gregory')->format('yMMdd') } @_ }
sub code { map { $_->year . '-' . $_->month_code . '-' . $_->day } @_ }
sub fl { my ($y, $m, $d) = $_[0] =~ /^(\d{4})(\d\d)(\d\d)$/; Time::Keeper->new(year => $y, month => $m, day => $d, zone => 'floating') }
sub heb { my %a = @_; Time::Keeper->new(calendar => 'hebrew', zone => 'floating', %a) }

# ---- RFC 7529 section 4.3 ------------------------------------------------------
{
    open my $fh, '<', 't/rfc7529-examples.tsv' or die "t/rfc7529-examples.tsv: $!";
    my $n = 0;
    while (my $line = <$fh>) {
        chomp $line;
        next if $line =~ /^#/ || $line !~ /\S/;
        my ($name, $dtstart, $rrule, $occ) = split /\t/, $line;
        my @want = split ' ', $occ;
        my $r = $R->new(rrule => $rrule, start => fl($dtstart));
        is_deeply([greg($r->first(scalar @want))], \@want, "RFC 7529: $name");
        my $set = $R->parse_ical("DTSTART;VALUE=DATE:$dtstart\r\nRRULE:$rrule\r\n");
        is_deeply([greg($set->first(scalar @want))], \@want, "RFC 7529: $name, read as iCalendar");
        is($R->new(rrule => $r->rrule, start => fl($dtstart))->rrule, $r->rrule, "RFC 7529: $name: rrule round-trips");
        is($R->parse_ical($set->ical)->ical, $set->ical, "RFC 7529: $name: ical round-trips");
        $n++;
    }
    is($n, 5, 'the five rows were read');
}
is_deeply([code($R->new(rrule => 'RSCALE=HEBREW;FREQ=YEARLY;BYMONTH=5L;BYMONTHDAY=8;SKIP=FORWARD', start => fl('20140208'))->first(5))],
    [qw(5774-M05L-8 5775-M06-8 5776-M05L-8 5777-M06-8 5778-M06-8)], 'the RFC\'s Hebrew column: Adar I in leap years, Adar otherwise');

# ---- Rosh Hashanah and the Umm al-Qura 15th ------------------------------------------
{
    my $rh = $R->new(rrule => 'RSCALE=HEBREW;FREQ=YEARLY;BYMONTH=1;BYMONTHDAY=1',
        start => Time::Keeper->new(year => 5787, month => 1, day => 1, calendar => 'hebrew', zone => 'Asia/Jerusalem'));
    my @got = $rh->first(14);
    my @want = map { Time::Keeper->new(year => $_, month => 1, day => 1, calendar => 'hebrew', zone => 'Asia/Jerusalem') } 5787 .. 5800;
    is_deeply([map { $_->epoch } @got], [map { $_->epoch } @want], 'Rosh Hashanah 5787 to 5800');
    is(scalar(grep { $_->calendar eq 'hebrew' } @got), 14, 'every occurrence is read in the Hebrew calendar');
    is($got[1]->format('d MMMM y'), '1 Tishri 5788', 'and formats as one');
    is($rh->calendar, 'hebrew', 'calendar');
    is($rh->skip, 'omit', 'skip defaults to omit');
    is($rh->zone, 'Asia/Jerusalem', 'in the start\'s zone');
    is($rh->start->calendar, 'hebrew', 'the start is read in the calendar too');

    my $uq = $R->new(rrule => 'RSCALE=ISLAMIC-UMALQURA;FREQ=MONTHLY;BYMONTHDAY=15',
        start => Time::Keeper->new(year => 1447, month => 1, day => 15, calendar => 'islamic-umalqura', zone => 'Asia/Riyadh'));
    my @m = $uq->first(24);
    is(scalar(grep { $_->in_calendar('islamic-umalqura')->day == 15 } @m), 24, 'the 15th of every Umm al-Qura month for two years');
    is_deeply([map { $_->month } @m], [(1 .. 12) x 2], 'every month once');
    is($uq->calendar, 'islamic-umalqura', 'its calendar');
    ok(!defined $R->new(rrule => 'FREQ=DAILY', start => $m[0])->calendar, 'a rule without RSCALE has none, whatever its start\'s');
    ok(!defined $R->new(rrule => 'FREQ=DAILY', start => $m[0])->skip, 'nor a skip');
}

# ---- 30 Adar: Adar and Adar II have 29 days, Adar I has 30 -------------------------------------
{
    my $from = heb(year => 5784, month => 7, day => 29);      # 29 Adar II 5784
    dies_like(sub { $R->new(rrule => 'RSCALE=HEBREW;FREQ=YEARLY;BYMONTH=6;BYMONTHDAY=30', start => $from)->first(2) },
        qr/can never fire/, '30 Adar, OMIT: Adar never has a 30th');
    is_deeply([code($R->new(rrule => 'RSCALE=HEBREW;FREQ=YEARLY;BYMONTH=6;BYMONTHDAY=30;SKIP=BACKWARD', start => $from)->first(4))],
        [qw(5784-M06-29 5785-M06-29 5786-M06-29 5787-M06-29)], '30 Adar, BACKWARD: 29 Adar every year');
    is_deeply([code($R->new(rrule => 'RSCALE=HEBREW;FREQ=YEARLY;BYMONTH=6;BYMONTHDAY=30;SKIP=FORWARD', start => $from)->first(4))],
        [qw(5784-M06-29 5784-M07-1 5785-M07-1 5786-M07-1)], '30 Adar, FORWARD: 1 Nisan every year');

    my $a1 = heb(year => 5784, month => 6, day => 30);         # 30 Adar I 5784
    is_deeply([code($R->new(rrule => 'RSCALE=HEBREW;FREQ=YEARLY;BYMONTH=5L;BYMONTHDAY=30', start => $a1)->first(4))],
        [qw(5784-M05L-30 5787-M05L-30 5790-M05L-30 5793-M05L-30)], '30 Adar I, OMIT: leap years only');
    is_deeply([code($R->new(rrule => 'RSCALE=HEBREW;FREQ=YEARLY;BYMONTH=5L;BYMONTHDAY=30;SKIP=BACKWARD', start => $a1)->first(4))],
        [qw(5784-M05L-30 5785-M05-30 5786-M05-30 5787-M05L-30)], '30 Adar I, BACKWARD: the month back to Shevat, which has a 30th');
    is_deeply([code($R->new(rrule => 'RSCALE=HEBREW;FREQ=YEARLY;BYMONTH=5L;BYMONTHDAY=30;SKIP=FORWARD', start => $a1)->first(4))],
        [qw(5784-M05L-30 5785-M07-1 5786-M07-1 5787-M05L-30)], '30 Adar I, FORWARD: the month on to Adar, then the day on to 1 Nisan');
}

# ---- a leap month, by BYMONTH and implied by the start ---------------------------------------------
{
    my $a15 = heb(year => 5784, month => 6, day => 15);        # 15 Adar I 5784
    is_deeply([code($R->new(rrule => 'RSCALE=HEBREW;FREQ=YEARLY;BYMONTH=5L;BYMONTHDAY=15', start => $a15)->first(3))],
        [qw(5784-M05L-15 5787-M05L-15 5790-M05L-15)], 'BYMONTH=5L, OMIT');
    is_deeply([code($R->new(rrule => 'RSCALE=HEBREW;FREQ=YEARLY;BYMONTH=5L;BYMONTHDAY=15;SKIP=BACKWARD', start => $a15)->first(3))],
        [qw(5784-M05L-15 5785-M05-15 5786-M05-15)], 'BYMONTH=5L, BACKWARD: Shevat');
    is_deeply([code($R->new(rrule => 'RSCALE=HEBREW;FREQ=YEARLY;BYMONTH=5L;BYMONTHDAY=15;SKIP=FORWARD', start => $a15)->first(3))],
        [qw(5784-M05L-15 5785-M06-15 5786-M06-15)], 'BYMONTH=5L, FORWARD: Adar');
    is_deeply([code($R->new(rrule => 'RSCALE=HEBREW;FREQ=YEARLY', start => $a15)->first(3))],
        [qw(5784-M05L-15 5787-M05L-15 5790-M05L-15)], 'a start in Adar I implies BYMONTH=5L (RFC 7529 4.2)');
    is_deeply([code($R->new(rrule => 'RSCALE=HEBREW;FREQ=YEARLY;SKIP=FORWARD', start => $a15)->first(3))],
        [qw(5784-M05L-15 5785-M06-15 5786-M06-15)], 'and SKIP=FORWARD takes it to Adar in a common year');
    my $a2 = heb(year => 5784, month => 7, day => 15);         # 15 Adar II 5784
    is_deeply([code($R->new(rrule => 'RSCALE=HEBREW;FREQ=YEARLY', start => $a2)->first(3))],
        [qw(5784-M06-15 5785-M06-15 5786-M06-15)], 'a start in Adar II is month 6: Adar every year, Adar II in a leap year');
    is_deeply([code($R->new(rrule => 'RSCALE=HEBREW;FREQ=MONTHLY', start => $a15)->first(4))],
        [qw(5784-M05L-15 5784-M06-15 5784-M07-15 5784-M08-15)], 'MONTHLY from Adar I steps by the ordinal month: Adar II, then Nisan');
    my $tishri = heb(year => 5784, month => 1, day => 1);
    my @last = $R->new(rrule => 'RSCALE=HEBREW;FREQ=MONTHLY;BYMONTHDAY=-1;COUNT=14', start => $tishri)->first(14);
    shift @last;
    is(scalar(@last), 13, 'BYMONTHDAY=-1 in a thirteen-month year: thirteen last days');
    is(scalar(grep { $_->day == $_->days_in_month && $_->year == 5784 } @last), 13, 'each the last day of its month');
    is_deeply([code($R->new(rrule => 'RSCALE=HEBREW;FREQ=YEARLY;INTERVAL=1;BYMONTH=1;BYMONTHDAY=1', start => $tishri)->first(3))],
        [qw(5784-M01-1 5785-M01-1 5786-M01-1)], 'a year of thirteen months is one period, not 12 months on');
    my $twelve = $R->new(rrule => 'RSCALE=HEBREW;FREQ=MONTHLY;INTERVAL=13;BYMONTHDAY=1', start => $tishri);
    is_deeply([code($twelve->first(2))], [qw(5784-M01-1 5785-M01-1)], 'thirteen months on from Tishri of a leap year is Tishri');

    my $c = Time::Keeper->new(year => 2025, month => 1, day => 1, calendar => 'chinese', zone => 'Asia/Shanghai');
    my @six = $R->new(rrule => 'RSCALE=CHINESE;FREQ=YEARLY;BYMONTH=6L;BYMONTHDAY=1', start => $c)->first(2);
    is($six[1]->in_calendar('gregory')->ymd, '2025-07-25', 'a Chinese 6L in 2025: the leap sixth month begins 25 July');
    is($six[1]->month_code, 'M06L', 'read as M06L');
    is_deeply([map { $_->epoch } $R->every(1, 'year', calendar => 'chinese', start => $c)->first(4)],
        [map { Time::Keeper->new(year => $_, month => 1, day => 1, calendar => 'chinese', zone => 'Asia/Shanghai')->epoch } 2025 .. 2028],
        'every(1, year, calendar => chinese): the Chinese new year, as Time::Keeper has it');
    is($R->every(1, 'year', calendar => 'chinese', start => $c)->rrule, 'RSCALE=CHINESE;FREQ=YEARLY', 'whose rule says so');
}

# ---- the Gregorian with RSCALE ------------------------------------------------------------------------
{
    my $jan31 = Time::Keeper->new(year => 2026, month => 1, day => 31, zone => 'UTC');
    is_deeply([greg($R->new(rrule => 'RSCALE=GREGORIAN;FREQ=MONTHLY;SKIP=BACKWARD', start => $jan31)->first(4))], [qw(20260131 20260228 20260331 20260430)], 'monthly from the 31st, BACKWARD: the last day of a short month');
    is_deeply([greg($R->new(rrule => 'RSCALE=GREGORIAN;FREQ=MONTHLY;SKIP=FORWARD', start => $jan31)->first(4))], [qw(20260131 20260301 20260331 20260501)], 'FORWARD: the first of the next');
    {
        my $fw = $R->new(rrule => 'RSCALE=GREGORIAN;FREQ=MONTHLY;SKIP=FORWARD', start => $jan31);
        my $mar1 = Time::Keeper->new(year => 2026, month => 3, day => 1, zone => 'UTC');
        ok($fw->contains($mar1), 'contains a day moved on from the month before');
        is($fw->next($mar1->minus(seconds => 1))->ymd, '2026-03-01', 'next reaches it from just before');
        is(scalar(() = $fw->between($mar1, $mar1->plus(days => 1))), 1, 'between holds it');
        is($fw->previous($mar1->plus(seconds => 1))->ymd, '2026-03-01', 'previous finds it');
    }
    is_deeply([greg($R->new(rrule => 'RSCALE=GREGORIAN;FREQ=MONTHLY;INTERVAL=3;SKIP=FORWARD', start => $jan31)->first(3))], [qw(20260131 20260501 20260731)], 'a day moved on from a month the interval reaches, not from one it skips');
    is_deeply([greg($R->new(rrule => 'RSCALE=GREGORIAN;FREQ=MONTHLY', start => $jan31)->first(3))], [qw(20260131 20260331 20260531)], 'OMIT is RFC 5545\'s reading');
    is_deeply([greg($R->new(rrule => 'RSCALE=GREGORIAN;FREQ=MONTHLY;BYMONTHDAY=31,1;SKIP=FORWARD', start => $jan31)->first(4))], [qw(20260131 20260201 20260301 20260331)], 'a day moved on onto a day the rule names comes once');
    is($R->new(rrule => 'RSCALE=GREGORIAN;FREQ=MONTHLY', start => $jan31)->calendar, 'gregory', 'the Gregorian is gregory, as Time::Keeper names it');
    is($R->new(rrule => 'rscale=gregorian;freq=monthly;skip=forward', start => $jan31)->rrule, 'RSCALE=GREGORIAN;FREQ=MONTHLY;SKIP=FORWARD', 'written in upper case, RSCALE first and SKIP last');
}

# ---- what is refused ------------------------------------------------------------------------------------
{
    my $s = heb(year => 5784, month => 1, day => 1);
    dies_like(sub { $R->new(rrule => 'RSCALE=JULIAN;FREQ=YEARLY', start => $s) }, qr/RSCALE=JULIAN names no calendar Time::Keeper knows/, 'JULIAN names Time::Keeper');
    dies_like(sub { $R->new(rrule => 'FREQ=YEARLY;SKIP=FORWARD', start => $s) }, qr/SKIP needs RSCALE/, 'SKIP without RSCALE');
    dies_like(sub { $R->new(rrule => 'RSCALE=HEBREW;FREQ=YEARLY;BYWEEKNO=1', start => $s) }, qr/BYWEEKNO cannot be given with RSCALE/, 'BYWEEKNO with RSCALE');
    dies_like(sub { $R->new(rrule => 'FREQ=YEARLY;BYMONTH=5L', start => $s) }, qr/BYMONTH=5L: a leap month needs RSCALE/, 'a leap month without RSCALE');
    dies_like(sub { $R->new(rrule => 'FREQ=YEARLY;BYMONTH=13', start => $s) }, qr/BYMONTH=13 is out of range 1 to 12/, 'month 13 without RSCALE');
    dies_like(sub { $R->new(rrule => 'RSCALE=HEBREW;FREQ=YEARLY;BYMONTH=14', start => $s) }, qr/BYMONTH=14 is out of range 1 to 13/, 'month 14 with it');
    dies_like(sub { $R->new(rrule => 'FREQ=YEARLY;BYYEARDAY=380', start => $s) }, qr/BYYEARDAY=380 is out of range 1 to 366/, 'year day 380 without RSCALE');
    ok($R->new(rrule => 'RSCALE=HEBREW;FREQ=YEARLY;BYYEARDAY=-1', start => $s), 'BYYEARDAY up to 385 with it');
    is($R->new(rrule => 'FREQ=MONTHLY;BYMONTH=13;RSCALE=ETHIOPIC', start => fl('20130906'))->rrule, 'RSCALE=ETHIOPIC;FREQ=MONTHLY;BYMONTH=13', 'RSCALE after the BYMONTH it widens still widens it');
    is($R->new(rrule => 'FREQ=YEARLY;BYMONTH=5L;BYMONTHDAY=8;RSCALE=HEBREW', start => fl('20140208'))->rrule, 'RSCALE=HEBREW;FREQ=YEARLY;BYMONTHDAY=8;BYMONTH=5L', 'and allows its leap month');
    dies_like(sub { $R->new(rrule => 'RSCALE=HEBREW;FREQ=YEARLY;SKIP=SIDEWAYS', start => $s) }, qr/SKIP=SIDEWAYS is not one of OMIT, BACKWARD, FORWARD/, 'a SKIP that is not one');
    dies_like(sub { $R->new(rrule => 'RSCALE=HEBREW;FREQ=YEARLY', start => $s, calendar => 'hebrew') }, qr/both name a calendar/, 'calendar => and RSCALE both');
    dies_like(sub { $R->every(1, 'year', calendar => 'klingon', start => $s) }, qr/calendar => 'klingon' names no calendar/, 'every with a calendar that is not one');
    dies_like(sub { $R->new(rrule => 'RSCALE=GREGORIAN;FREQ=DAILY;BYHOUR=9;BYMINUTE=0', start => $s)->cron }, qr/has no cron spelling/, 'a calendar rule is no cron');
    is($R->new(rrule => 'FREQ=YEARLY', start => $s, calendar => 'hebrew')->rrule, 'RSCALE=HEBREW;FREQ=YEARLY', 'calendar => on new is RSCALE');
    is_deeply([map { $_->year } $R->new(rrule => 'FREQ=YEARLY', start => $s, calendar => 'hebrew')->first(3)], [5784, 5785, 5786], 'and walks in it');
}

# ---- sets and storage ---------------------------------------------------------------------------------------------
{
    my $s = heb(year => 5784, month => 1, day => 1);
    my $r = $R->new(rrule => 'RSCALE=HEBREW;FREQ=YEARLY;BYMONTH=5L;BYMONTHDAY=8;SKIP=FORWARD', start => $s);
    my $copy = $R->THAW('x', $r->FREEZE('x'));
    is($copy->rrule, $r->rrule, 'a frozen calendar rule thaws to the same rule');
    is_deeply([map { $_->epoch } $copy->first(5)], [map { $_->epoch } $r->first(5)], 'and walks the same');
    my $set = $r->with(exdate => ($r->first(3))[2]);
    is(($set->first(3))[2]->calendar, 'hebrew', 'a set of a calendar rule gives values in its calendar');
    is(scalar(() = $set->first(3)), 3, 'and merges by instant');
}

# ---- the methods agree on random rules in random calendars ---------------------------------------------------------
{
    srand($ENV{TKR_SEED} || 20261019);
    my @cal = qw(gregorian hebrew chinese islamic-umalqura islamic-civil persian ethiopic coptic indian dangi buddhist);
    my @freq = qw(YEARLY MONTHLY WEEKLY DAILY);
    my @days = qw(MO TU WE TH FR SA SU);
    my $checked = 0;
    for my $i (1 .. 200) {
        my $cal = $cal[int rand @cal];
        my $f = $freq[int rand @freq];
        my @parts = ('RSCALE=' . uc $cal, "FREQ=$f", 'INTERVAL=' . (1 + int rand 3));
        push @parts, 'BYDAY=' . join(',', map { $days[int rand 7] } 1 .. 1 + int rand 2) if rand() < 0.4;
        push @parts, 'BYMONTHDAY=' . (rand() < 0.2 ? -1 - int rand 3 : 1 + int rand 30) if rand() < 0.4 && $f ne 'WEEKLY';
        push @parts, 'BYMONTH=' . (1 + int rand 12) . (rand() < 0.2 ? 'L' : '') if rand() < 0.3;
        push @parts, 'SKIP=' . (qw(OMIT BACKWARD FORWARD))[int rand 3] if rand() < 0.5;
        my $text = join ';', @parts;
        my $start = Time::Keeper->new(year => 2026, month => 1 + int rand 12, day => 1 + int rand 28, hour => int rand 24, zone => 'UTC');
        my $r = eval { $R->new(rrule => $text, start => $start) };
        if (!$r) { diag("$text: $@") if $@ !~ /can never fire/; next }
        my @f = eval { $r->first(6) };
        next if @f < 6;
        my @again;
        my $cur = $start->minus(seconds => 1);
        for (1 .. 6) { my $n = $r->next($cur) or last; push @again, $n; $cur = $n }
        is(join(' ', map { $_->iso8601 } @again), join(' ', map { $_->iso8601 } @f), "$text: next walks what first gives") or last;
        my $it = $r->iterate;
        is(join(' ', map { $it->()->iso8601 } 1 .. 6), join(' ', map { $_->iso8601 } @f), "$text: iterate too") or last;
        is(join(' ', map { $_->iso8601 } $r->between($start, $f[-1])), join(' ', map { $_->iso8601 } @f[0 .. 4]), "$text: between") or last;
        ok((grep { !$r->contains($_) } @f) == 0, "$text: contains every one") or last;
        is($r->previous($f[-1])->iso8601, $f[-2]->iso8601, "$text: previous of the sixth is the fifth") or last;
        my $want = $cal eq 'gregorian' ? 'gregory' : $cal;
        is(scalar(grep { $_->calendar eq $want } @f), 6, "$text: every occurrence in $want") or last;
        is($R->new(rrule => $r->rrule, start => $start)->rrule, $r->rrule, "$text: rrule round-trips") or last;
        $checked++;
    }
    cmp_ok($checked, '>=', 100, "$checked random calendar rules agreed");
}

done_testing;
