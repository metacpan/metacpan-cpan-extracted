#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Storable qw(freeze thaw dclone);
use Time::Keeper;
use Time::Keeper::Recurrence;

# Rules and sets stored and loaded: Storable, FREEZE/THAW and TO_JSON; the
# zone kept by name, the locale by code, a cron as a cron.

my $R = 'Time::Keeper::Recurrence';
my $S = 'Time::Keeper::Recurrence::Set';
sub fmt { map { $_->format('y-MM-dd HH:mm') } @_ }

my $start = Time::Keeper->new(year => 2026, month => 10, day => 20, hour => 9, zone => 'America/New_York');
my $rule = $R->new(rrule => 'FREQ=WEEKLY;BYDAY=TU,TH;UNTIL=20271231T235959Z', start => $start, gap => 'backward', overlap => 'later');

sub same_rule {
    my ($a, $b, $name) = @_;
    is($b->rrule, $a->rrule, "$name: the rule");
    is($b->zone, $a->zone, "$name: the zone");
    is($b->start->epoch, $a->start->epoch, "$name: the start");
    is($b->start->nanosecond, $a->start->nanosecond, "$name: to the nanosecond");
    is($b->start->locale, $a->start->locale, "$name: the locale");
    is($b->gap, $a->gap, "$name: gap");
    is($b->overlap, $a->overlap, "$name: overlap");
    is_deeply([map { $_->epoch } $b->first(6)], [map { $_->epoch } $a->first(6)], "$name: walks the same");
}

# ---- Storable -----------------------------------------------------------------
{
    my $copy = dclone($rule);
    isa_ok($copy, $R, 'dclone of a rule');
    same_rule($rule, $copy, 'Storable rule');
    my $thawed = thaw(freeze($rule));
    same_rule($rule, $thawed, 'freeze and thaw');

    my $cron = $R->cron('30 2 * * 1-5', zone => 'Europe/London');
    my $ccopy = dclone($cron);
    is($ccopy->cron, '30 2 * * 1-5', 'a cron stays a cron');
    is($ccopy->zone, 'Europe/London', 'in its zone');
    is($ccopy->gap, 'skip', 'with the cron gap choice');
    is($ccopy->overlap, 'both', 'and overlap choice');
    ok(!defined $ccopy->start, 'and no start');
    my $from = Time::Keeper->new(year => 2026, month => 10, day => 20, zone => 'UTC');
    is($ccopy->next($from)->epoch, $cron->next($from)->epoch, 'and walks the same');
    my $vixie = $R->cron('0 9 1 * 1', zone => 'UTC');
    is(dclone($vixie)->cron, '0 9 1 * 1', 'a cron on either day field keeps both');
    my $every = $R->cron('@every 90m', zone => 'UTC');
    is(dclone($every)->cron, '@every 90m', 'an @every cron keeps its interval');
    my $bound = $R->cron('0 9 * * *', start => $start);
    is(dclone($bound)->start->epoch, $start->epoch, 'a cron with a bound keeps it');

    my $set = $rule->with(exdate => [Time::Keeper->new(year => 2026, month => 11, day => 26, hour => 9, zone => 'America/New_York'), '2026-12-25'], rdate => '2027-01-02');
    my $scopy = dclone($set);
    isa_ok($scopy, $S, 'dclone of a set');
    is($scopy->ical, $set->ical, 'the same lines');
    is($scopy->gap, 'backward', 'the gap choice');
    is($scopy->overlap, 'later', 'the overlap choice');
    is(($scopy->rules)[0]->gap, 'backward', 'carried into the rules');
    is_deeply([map { $_->epoch } $scopy->first(12)], [map { $_->epoch } $set->first(12)], 'walks the same');
    my $ex = $R->parse_ical("DTSTART;TZID=America/New_York:20261020T090000\r\nRRULE:FREQ=DAILY;COUNT=14\r\nEXRULE:FREQ=WEEKLY;BYDAY=SA,SU\r\n");
    my $excopy = dclone($ex);
    is(scalar(() = $excopy->exrules), 1, 'an EXRULE survives Storable though ical never writes it');
    is_deeply([map { $_->epoch } $excopy->first(20)], [map { $_->epoch } $ex->first(20)], 'and still removes');
    my $cset = $R->cron('0 9 * * 1-5', zone => 'UTC')->with(exdate => '2026-12-25');
    my $csc = dclone($cset);
    is(($csc->rules)[0]->cron, '0 9 * * 1-5', 'a cron in a set stays a cron');
    ok(!defined $csc->start, 'a cron set without a start has none after');
    is($csc->next(Time::Keeper->new(year => 2026, month => 12, day => 24, hour => 10, zone => 'UTC'))->format('y-MM-dd HH:mm'), '2026-12-28 09:00', 'and skips Christmas still');
    my $vset = $R->cron('0 9 1 * 1', zone => 'UTC')->with(exdate => '2026-12-25');
    is(($vset->rules)[0]->cron, (dclone($vset)->rules)[0]->cron, 'a cron set with no RRULE spelling still stores');
    my $fset = $R->parse_ical("DTSTART;VALUE=DATE:20261020\r\nRRULE:FREQ=WEEKLY;COUNT=3\r\n");
    is(dclone($fset)->ical, $fset->ical, 'a whole-day start stays one');
}

# ---- FREEZE and THAW ------------------------------------------------------------
{
    my $frozen = $rule->FREEZE('CBOR');
    like($frozen, qr/^tkr1 America\/New_York en \d+ 0 backward later rrule FREQ=WEEKLY;UNTIL=20271231T235959Z;BYDAY=TU,TH$/, 'a rule freezes to one line of text');
    same_rule($rule, $R->THAW('CBOR', $frozen), 'FREEZE/THAW rule');
    my $cron = $R->cron('*/15 * * * *', zone => 'Asia/Tokyo');
    like($cron->FREEZE('x'), qr/^tkr1 Asia\/Tokyo en - 0 skip both cron 0,15,30,45 \* \* \* \*$/, 'a cron freezes with its expression, spelled canonically');
    is($R->THAW('x', $cron->FREEZE('x'))->cron, '0,15,30,45 * * * *', 'and thaws as one');
    is($R->THAW('x', $cron->FREEZE('x'))->zone, 'Asia/Tokyo', 'the zone by name');

    my $set = $rule->with(exdate => '2026-12-25');
    my $sf = $set->FREEZE('x');
    like($sf, qr/^tkrs1 backward later en 0\r\nDTSTART;TZID=America\/New_York:20261020T090000\r\nRRULE:/, 'a set freezes to a header and its lines');
    is($S->THAW('x', $sf)->ical, $set->ical, 'and thaws to the same set');
    is($S->THAW('x', $sf)->gap, 'backward', 'with the gap choice');
    my $ex = $R->parse_ical("DTSTART:20261020T090000Z\r\nRRULE:FREQ=DAILY;COUNT=14\r\nEXRULE:FREQ=WEEKLY;BYDAY=SA,SU\r\n");
    like($ex->FREEZE('x'), qr/EXRULE:FREQ=WEEKLY;BYDAY=SA,SU/, 'the frozen form keeps an EXRULE');
    my $cs = $R->cron('0 9 * * 1-5', zone => 'UTC')->with(exdate => '2026-12-25')->FREEZE('x');
    like($cs, qr/X-TKR-CRON:0 9 \* \* 1-5/, 'and a cron as an X-TKR-CRON line');
    is(($S->THAW('x', $cs)->rules)[0]->cron, '0 9 * * 1-5', 'which thaws as a cron');

    for my $junk ('junk', 'tkr1', 'tkr1 Narnia/Lamppost en 0 0 forward earlier rrule FREQ=DAILY', 'tkr1 UTC en 0 0 sideways earlier rrule FREQ=DAILY',
                  'tkr1 UTC en 0 0 forward earlier rrule FREQ=FORTNIGHTLY', 'tkr1 UTC en x 0 forward earlier rrule FREQ=DAILY', 'tkrs1 forward earlier en 0') {
        ok(!eval { $R->THAW('x', $junk); 1 }, "a rule does not thaw from '$junk'");
    }
    like(do { eval { $R->THAW('x', 'junk') }; $@ }, qr/not a frozen Time::Keeper::Recurrence/, 'the words for junk');
    like(do { eval { $R->THAW('x', 'tkr1 Narnia/Lamppost en 0 0 forward earlier rrule FREQ=DAILY') }; $@ }, qr/'Narnia\/Lamppost' is not a time zone this build knows/, 'the words for an unknown zone');
    ok(!eval { $S->THAW('x', 'junk'); 1 }, 'nor a set');
    like($@, qr/not a frozen Time::Keeper::Recurrence::Set/, 'with its words');
}

# ---- zones, locales and fractions ------------------------------------------------
{
    my $fl = $R->new(rrule => 'FREQ=DAILY;COUNT=3', start => Time::Keeper->new(year => 2026, month => 10, day => 20, hour => 9, zone => 'floating'));
    same_rule($fl, dclone($fl), 'a floating rule');
    is(dclone($fl)->zone, 'floating', 'floating stays floating');
    my $fx = $R->new(rrule => 'FREQ=DAILY;COUNT=3', start => Time::Keeper->new(year => 2026, month => 10, day => 20, hour => 9, zone => '+05:30'));
    same_rule($fx, dclone($fx), 'a fixed-offset rule');
    my $ns = $R->new(rrule => 'FREQ=DAILY;COUNT=3', start => Time::Keeper->new(year => 2026, month => 10, day => 20, hour => 9, nanosecond => 123456789, zone => 'UTC'));
    same_rule($ns, dclone($ns), 'a rule with a fraction of a second');
    is(dclone($ns)->first(2)->nanosecond, 123456789, 'the occurrences keep it');
    my $fr = $R->new(rrule => 'FREQ=DAILY;COUNT=3', start => Time::Keeper->new(year => 2026, month => 10, day => 20, hour => 9, zone => 'Europe/Paris', locale => 'fr'));
    like($fr->FREEZE('x'), qr/^tkr1 Europe\/Paris fr /, 'the locale is stored by code');
    is(dclone($fr)->start->locale, 'fr', 'and comes back');
    is(dclone($fr)->first(1)->locale, 'fr', 'onto the occurrences');
    my $neg = $R->new(rrule => 'FREQ=YEARLY;COUNT=3', start => Time::Keeper->new(year => 1950, month => 1, day => 1, zone => 'UTC'));
    is(dclone($neg)->start->epoch, $neg->start->epoch, 'a start before 1970 (a negative epoch) survives');
}

# ---- TO_JSON -------------------------------------------------------------------------
{
    is($rule->TO_JSON, $rule->rrule, 'a rule\'s TO_JSON is its RRULE');
    is($R->cron('0 9 1 * 1', zone => 'UTC')->TO_JSON, '0 9 1 * 1', 'a cron\'s is its expression');
    my $set = $rule->with(exdate => '2026-12-25');
    is($set->TO_JSON, $set->ical, 'a set\'s is its ical');
    SKIP: {
        eval { require JSON::PP; 1 } or skip 'no JSON::PP', 2;
        my $json = JSON::PP->new->canonical->convert_blessed;
        is($json->encode([$rule]), '["' . $rule->rrule . '"]', 'JSON::PP encodes a rule as its RRULE string');
        like($json->encode({ s => $set }), qr/^\{"s":"DTSTART;TZID=America\/New_York:20261020T090000\\r\\nRRULE:/, 'and a set as its lines');
    }
}

done_testing;
