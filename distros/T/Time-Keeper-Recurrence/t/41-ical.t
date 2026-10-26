#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Time::Keeper;
use Time::Keeper::Recurrence;

# iCalendar text: the RFC's examples read as the same rules t/20 builds,
# folded lines, TZIDs by IANA and Windows name, whole-day starts, a PERIOD
# refused, and the lines written back strictly.

my $R = 'Time::Keeper::Recurrence';
my $NY = 'America/New_York';
sub ny { Time::Keeper->new(zone => $NY, @_) }
sub fmt { map { $_->format('y-MM-dd HH:mm') } @_ }
sub compact { my $s = shift; $s =~ s/[-:]//g; $s }
sub unfold { my $s = shift; $s =~ s/\r\n[ \t]//g; $s }

# ---- the RFC's examples ------------------------------------------------------
{
    open my $fh, '<', 't/rfc5545-examples.tsv' or die "t/rfc5545-examples.tsv: $!";
    my $n = 0;
    while (my $line = <$fh>) {
        chomp $line;
        next if $line =~ /^#/ || $line !~ /\S/;
        my ($name, $dtstart, $rrule) = split /\t/, $line;
        my $start = Time::Keeper->parse($dtstart, zone => $NY);
        my $rule = $R->new(rrule => $rrule, start => $start);
        my $text = "DTSTART;TZID=$NY:" . compact($dtstart) . "\r\nRRULE:$rrule\r\n";
        my $set = $R->parse_ical($text);
        my ($got) = $set->rules;
        is($got->rrule, $rule->rrule, "$name: the RRULE line reads as the rule");
        is($set->start->epoch, $start->epoch, "$name: DTSTART is the start");
        is($set->zone, $NY, "$name: in New York");
        is_deeply([map { $_->epoch } $set->first(8)], [map { $_->epoch } $rule->first(8)], "$name: walks as the rule");
        my $canon = "DTSTART;TZID=$NY:" . compact($dtstart) . "\r\nRRULE:" . $rule->rrule . "\r\n";
        is(unfold($set->ical), $canon, "$name: ical writes the lines back canonically");
        is($R->parse_ical($set->ical)->ical, $set->ical, "$name: and round-trips");
        is(unfold($rule->ical), $canon, "$name: the rule's own ical is the same");
        $n++;
    }
    cmp_ok($n, '>', 30, 'the RFC examples were read');
}

# ---- folding -------------------------------------------------------------------
{
    my $want = $R->parse_ical("DTSTART;TZID=$NY:20261020T090000\r\nRRULE:FREQ=WEEKLY;BYDAY=TU,TH\r\n");
    for my $folded (
        "DTSTART;TZID=$NY:20261020T090000\r\nRRULE:FREQ=WEEKLY;BYD\r\n AY=TU,TH\r\n",
        "DTSTART;TZID=$NY:20261020T090000\nRRULE:FREQ=WEEKLY;BYD\n\tAY=TU,TH\n",
        "DTSTART;TZID=Ame\r\n rica/New_York:20261020T090000\r\nRRULE:FREQ=WEEKLY;BYDAY=TU,TH",
        "\r\n\r\nDTSTART;TZID=$NY:20261020T090000\r\n\r\nRRULE:FREQ=WEEKLY;BYDAY=TU,TH\r\n\r\n",
    ) {
        is($R->parse_ical($folded)->ical, $want->ical, 'a folded or oddly ended text reads the same');
    }
    my @many = map { ny(year => 2027, month => 1 + int($_ / 28), day => 1 + $_ % 28, hour => 9) } 0 .. 40;
    my $long = $want->with(rdate => \@many);
    my $ical = $long->ical;
    my @lines = split /\r\n/, $ical;
    ok(!grep({ length > 75 } @lines), 'no written line is over 75 octets');
    ok((grep { /^ / } @lines), 'the long RDATE line was folded');
    is($R->parse_ical($ical)->ical, $ical, 'a folded text round-trips');
    is(scalar(() = $R->parse_ical($ical)->rdates), 41, 'with every date');
}

# ---- TZIDs ---------------------------------------------------------------------
{
    for my $tz ('America/New_York', '/America/New_York', 'Eastern Standard Time', '/Eastern Standard Time', '"America/New_York"') {
        my $set = $R->parse_ical("DTSTART;TZID=$tz:20261020T090000\r\nRRULE:FREQ=DAILY\r\n");
        is($set->zone, $NY, "TZID=$tz is New York");
        is($set->start->epoch, ny(year => 2026, month => 10, day => 20, hour => 9)->epoch, "and the start is 09:00 there");
    }
    my $set = $R->parse_ical("DTSTART;TZID=GMT Standard Time:20261020T090000\r\nRRULE:FREQ=DAILY\r\n");
    is($set->zone, 'Europe/London', 'GMT Standard Time is London');
    ok(!eval { $R->parse_ical("DTSTART;TZID=Narnia/Lamppost:20261020T090000\r\nRRULE:FREQ=DAILY\r\n"); 1 }, 'an unknown TZID dies');
    like($@, qr/TZID=Narnia\/Lamppost is not a time zone/, 'naming it');
    my $utc = $R->parse_ical("DTSTART:20261020T090000Z\r\nRRULE:FREQ=DAILY\r\n");
    is($utc->zone, 'UTC', 'a Z start is UTC');
    is($utc->ical, "DTSTART:20261020T090000Z\r\nRRULE:FREQ=DAILY\r\n", 'and is written with Z');
    my $float = $R->parse_ical("DTSTART:20261020T090000\r\nRRULE:FREQ=DAILY\r\n");
    is($float->zone, 'floating', 'a bare start is floating');
    is($float->ical, "DTSTART:20261020T090000\r\nRRULE:FREQ=DAILY\r\n", 'and is written bare');
    my $fixed = $R->new(rrule => 'FREQ=DAILY', start => Time::Keeper->new(year => 2026, month => 10, day => 20, hour => 9, zone => '+05:30'));
    is($fixed->ical, "DTSTART;TZID=\"+05:30\":20261020T090000\r\nRRULE:FREQ=DAILY\r\n", 'a fixed offset is its own TZID, quoted for its colon');
    is($R->parse_ical($fixed->ical)->zone, '+05:30', 'and reads back');
    # a timed EXDATE in a zone other than the start's matches by instant
    my $mixed = $R->parse_ical("DTSTART;TZID=$NY:20261020T090000\r\nRRULE:FREQ=DAILY;COUNT=3\r\nEXDATE;TZID=Europe/London:20261021T140000\r\n");
    is_deeply([fmt($mixed->first(5))], ['2026-10-20 09:00', '2026-10-22 09:00'], 'an EXDATE given in London removes the New York occurrence');
    my $zless = $R->parse_ical("DTSTART;TZID=$NY:20261020T090000\r\nRRULE:FREQ=DAILY;COUNT=3\r\nEXDATE:20261021T090000\r\n");
    is_deeply([fmt($zless->first(5))], ['2026-10-20 09:00', '2026-10-22 09:00'], 'an EXDATE with no TZID is read in the start\'s zone');
}

# ---- whole days -----------------------------------------------------------------
{
    my $set = $R->parse_ical("DTSTART;VALUE=DATE:20261020\r\nRRULE:FREQ=WEEKLY;COUNT=3\r\n");
    is($set->zone, 'floating', 'a DATE start floats');
    is_deeply([fmt($set->first(5))], ['2026-10-20 00:00', '2026-10-27 00:00', '2026-11-03 00:00'], 'and recurs at midnight');
    is($set->ical, "DTSTART;VALUE=DATE:20261020\r\nRRULE:FREQ=WEEKLY;COUNT=3\r\n", 'written back as a DATE');
    my $ex = $R->parse_ical("DTSTART;TZID=$NY:20261020T090000\r\nRRULE:FREQ=DAILY;COUNT=5\r\nEXDATE;VALUE=DATE:20261021,20261023\r\nRDATE;VALUE=DATE:20261101\r\n");
    is_deeply([fmt($ex->first(9))], ['2026-10-20 09:00', '2026-10-22 09:00', '2026-10-24 09:00', '2026-11-01 00:00'], 'DATE lists remove and add whole days');
    is($ex->ical, "DTSTART;TZID=$NY:20261020T090000\r\nRRULE:FREQ=DAILY;COUNT=5\r\nRDATE;VALUE=DATE:20261101\r\nEXDATE;VALUE=DATE:20261021,20261023\r\n", 'and are written as DATE lines');
    ok(!eval { $R->parse_ical("DTSTART;TZID=$NY:20261020T090000\r\nRRULE:FREQ=DAILY\r\nEXDATE;VALUE=DATE:20261021T090000\r\n"); 1 }, 'VALUE=DATE with a time dies');
    like($@, qr/EXDATE:20261021T090000 is not a date \(YYYYMMDD\)/, 'naming the value');
    my $lenient = $R->parse_ical("DTSTART;TZID=$NY:20261020T090000\r\nRRULE:FREQ=DAILY;COUNT=3\r\nEXDATE:20261021\r\n");
    is_deeply([fmt($lenient->first(5))], ['2026-10-20 09:00', '2026-10-22 09:00'], 'a bare date in an EXDATE is read as the day');
}

# ---- lists and mixed lines -------------------------------------------------------
{
    my $set = $R->parse_ical(join "\r\n",
        'BEGIN:VEVENT', 'UID:abc@example.com', 'SUMMARY:Stand-up; daily: yes', "DTSTART;TZID=$NY:20261020T090000",
        "DTEND;TZID=$NY:20261020T091500", 'RRULE:FREQ=DAILY;COUNT=6', "EXDATE;TZID=$NY:20261021T090000,20261023T090000",
        "RDATE;TZID=$NY:20261101T100000,20261102T100000", 'END:VEVENT', '');
    is_deeply([fmt($set->first(10))], ['2026-10-20 09:00', '2026-10-22 09:00', '2026-10-24 09:00', '2026-10-25 09:00', '2026-11-01 10:00', '2026-11-02 10:00'],
        'a VEVENT with other properties reads its recurrence lines');
    is($set->ical, "DTSTART;TZID=$NY:20261020T090000\r\nRRULE:FREQ=DAILY;COUNT=6\r\nRDATE;TZID=$NY:20261101T100000,20261102T100000\r\nEXDATE;TZID=$NY:20261021T090000,20261023T090000\r\n",
        'written in RFC order, lists joined');
    my $two = $R->parse_ical("DTSTART;TZID=$NY:20261020T090000\r\nRRULE:FREQ=WEEKLY;BYDAY=TU\r\nRRULE:FREQ=WEEKLY;BYDAY=TH\r\n");
    is(scalar(() = $two->rules), 2, 'two RRULE lines are two rules');
    is_deeply([fmt($two->first(4))], ['2026-10-20 09:00', '2026-10-22 09:00', '2026-10-27 09:00', '2026-10-29 09:00'], 'merged');
    my $lower = $R->parse_ical("dtstart;tzid=$NY:20261020T090000\r\nrrule:freq=daily;count=2\r\n");
    is($lower->ical, "DTSTART;TZID=$NY:20261020T090000\r\nRRULE:FREQ=DAILY;COUNT=2\r\n", 'property names and parts in any case');
    my $only = $R->parse_ical("DTSTART;TZID=$NY:20261020T090000\r\n");
    is_deeply([fmt($only->first(3))], ['2026-10-20 09:00'], 'a DTSTART alone is one occurrence');
    is($only->ical, "DTSTART;TZID=$NY:20261020T090000\r\nRDATE;TZID=$NY:20261020T090000\r\n", 'written as an RDATE');
    my $set_class = Time::Keeper::Recurrence::Set->parse_ical("DTSTART:20261020T090000Z\r\nRRULE:FREQ=DAILY\r\n");
    isa_ok($set_class, 'Time::Keeper::Recurrence::Set', 'parse_ical on the Set class');
    is("$set_class", $set_class->ical, 'a set stringifies to its ical');
}

# ---- what is refused -------------------------------------------------------------------
{
    my %dies = (
        "DTSTART;TZID=$NY:20261020T090000\r\nRDATE;VALUE=PERIOD:20261101T100000/PT1H\r\n" => qr/RDATE;VALUE=PERIOD is not supported: a period is not an occurrence/,
        "DTSTART;TZID=$NY:20261020T090000\r\nDTSTART;TZID=$NY:20261021T090000\r\nRRULE:FREQ=DAILY\r\n" => qr/two DTSTART lines/,
        "RRULE:FREQ=DAILY\r\n" => qr/an RRULE needs a DTSTART/,
        "EXRULE:FREQ=DAILY\r\n" => qr/an EXRULE needs a DTSTART/,
        "SUMMARY:nothing\r\n" => qr/nothing recurs: no DTSTART, RRULE or RDATE/,
        '' => qr/nothing recurs/,
        "DTSTART:2026-10-20\r\nRRULE:FREQ=DAILY\r\n" => qr/DTSTART:2026-10-20 is not a date or a date and time/,
        "DTSTART:20261020T090000Z\r\nRRULE:FREQ=DAILY;UNTIL=20261030T090000\r\n" => qr/RRULE: UNTIL must be in UTC \(end in Z\) when DTSTART has a zone/,
        "DTSTART:20261020T090000\r\nRRULE:FREQ=DAILY;UNTIL=20261030T090000Z\r\n" => qr/RRULE: UNTIL must be floating \(no Z\) when DTSTART is/,
        "DTSTART:20261020T090000Z\r\nRRULE:FREQ=FORTNIGHTLY\r\n" => qr/RRULE: /,
        "DTSTART:20261020T090000Z\r\nRRULE:FREQ=DAILY;UNTIL=20200101T000000Z\r\n" => qr/RRULE:FREQ=DAILY;UNTIL=20200101T000000Z .*can never fire/,
        "DTSTART:20261020T090000Z\r\nRRULE:FREQ=DAILY\r\nEXDATE:20261021T0900\r\n" => qr/EXDATE:20261021T0900 is not a date or a date and time/,
        "DTSTART:20261020T090000Z\r\n" . join('', map { "RRULE:FREQ=DAILY;INTERVAL=$_\r\n" } 1 .. 17) => qr/more than 16 rules in a set/,
    );
    for my $text (sort keys %dies) {
        (my $shown = $text) =~ s/\r\n/|/g;
        ok(!eval { $R->parse_ical($text); 1 }, 'refused: ' . ($shown || '(empty)'));
        like($@, $dies{$text}, '  with the right words');
    }
    my $vixie = $R->cron('0 9 1 * 1', zone => 'UTC');
    ok(!eval { $vixie->ical; 1 }, 'a cron on either of two day fields has no RRULE and no ical');
    like($@, qr/fires on either, which no RRULE says/, 'and says why');
    ok(!eval { $R->cron('@every 2h', zone => 'UTC')->ical; 1 }, 'nor has an @every');
    my $plain = $R->cron('0 9 * * 1-5', zone => 'UTC');
    is($plain->ical, "RRULE:FREQ=MINUTELY;BYMINUTE=0;BYHOUR=9;BYDAY=MO,TU,WE,TH,FR\r\n", 'a cron with no start is its RRULE without a DTSTART');
    my $bound = $R->cron('0 9 * * 1-5', start => Time::Keeper->new(year => 2026, month => 10, day => 20, hour => 9, zone => 'UTC'));
    is($bound->ical, "RRULE:FREQ=MINUTELY;BYMINUTE=0;BYHOUR=9;BYDAY=MO,TU,WE,TH,FR\r\n", 'a cron\'s bound is not a DTSTART');
}

done_testing;
