#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Time::Keeper;
use Time::Keeper::Recurrence;

# RFC 5545's RECUR value: every part read, every value checked, written back
# in one canonical form; the rules about which parts may meet; the start's
# form against UNTIL's.

my $R = 'Time::Keeper::Recurrence';
my $start = Time::Keeper->new(year => 1997, month => 9, day => 2, hour => 9, zone => 'America/New_York');
my $floating = Time::Keeper->new(year => 1997, month => 9, day => 2, hour => 9, zone => 'floating');
sub rule { $R->new(rrule => shift, start => $start) }
sub dies_like {
    my ($code, $re, $name) = @_;
    my $ok = eval { $code->(); 1 };
    ok(!$ok && $@ =~ $re, $name) or diag($ok ? 'did not die' : $@);
}

# the RFC's own RRULE values (section 3.8.5.3), read and written back: a
# second read of the text written gives the same text, and every part given
# is still there
my @rfc = (
    'FREQ=DAILY;COUNT=10', 'FREQ=DAILY;UNTIL=19971224T000000Z', 'FREQ=DAILY;INTERVAL=2', 'FREQ=DAILY;INTERVAL=10;COUNT=5',
    'FREQ=YEARLY;UNTIL=20000131T140000Z;BYMONTH=1;BYDAY=SU,MO,TU,WE,TH,FR,SA', 'FREQ=DAILY;UNTIL=20000131T140000Z;BYMONTH=1',
    'FREQ=WEEKLY;COUNT=10', 'FREQ=WEEKLY;UNTIL=19971224T000000Z', 'FREQ=WEEKLY;INTERVAL=2;WKST=SU',
    'FREQ=WEEKLY;UNTIL=19971007T000000Z;WKST=SU;BYDAY=TU,TH', 'FREQ=WEEKLY;COUNT=10;WKST=SU;BYDAY=TU,TH',
    'FREQ=WEEKLY;INTERVAL=2;UNTIL=19971224T000000Z;WKST=SU;BYDAY=MO,WE,FR', 'FREQ=WEEKLY;INTERVAL=2;COUNT=8;WKST=SU;BYDAY=TU,TH',
    'FREQ=MONTHLY;COUNT=10;BYDAY=1FR', 'FREQ=MONTHLY;UNTIL=19971224T000000Z;BYDAY=1FR', 'FREQ=MONTHLY;INTERVAL=2;COUNT=10;BYDAY=1SU,-1SU',
    'FREQ=MONTHLY;COUNT=6;BYDAY=-2MO', 'FREQ=MONTHLY;BYMONTHDAY=-3', 'FREQ=MONTHLY;COUNT=10;BYMONTHDAY=2,15',
    'FREQ=MONTHLY;COUNT=10;BYMONTHDAY=1,-1', 'FREQ=MONTHLY;INTERVAL=18;COUNT=10;BYMONTHDAY=10,11,12,13,14,15',
    'FREQ=MONTHLY;INTERVAL=2;BYDAY=TU', 'FREQ=YEARLY;COUNT=10;BYMONTH=6,7', 'FREQ=YEARLY;INTERVAL=2;COUNT=10;BYMONTH=1,2,3',
    'FREQ=YEARLY;INTERVAL=3;COUNT=10;BYYEARDAY=1,100,200', 'FREQ=YEARLY;BYDAY=20MO', 'FREQ=YEARLY;BYWEEKNO=20;BYDAY=MO',
    'FREQ=YEARLY;BYMONTH=3;BYDAY=TH', 'FREQ=YEARLY;BYDAY=TH;BYMONTH=6,7,8', 'FREQ=MONTHLY;BYDAY=FR;BYMONTHDAY=13',
    'FREQ=MONTHLY;BYDAY=SA;BYMONTHDAY=7,8,9,10,11,12,13', 'FREQ=YEARLY;INTERVAL=4;BYMONTH=11;BYDAY=TU;BYMONTHDAY=2,3,4,5,6,7,8',
    'FREQ=MONTHLY;COUNT=3;BYDAY=TU,WE,TH;BYSETPOS=3', 'FREQ=MONTHLY;BYDAY=MO,TU,WE,TH,FR;BYSETPOS=-2',
    'FREQ=HOURLY;INTERVAL=3;UNTIL=19970902T170000Z', 'FREQ=MINUTELY;INTERVAL=15;COUNT=6', 'FREQ=MINUTELY;INTERVAL=90;COUNT=4',
    'FREQ=DAILY;BYHOUR=9,10,11,12,13,14,15,16;BYMINUTE=0,20,40', 'FREQ=MINUTELY;INTERVAL=20;BYHOUR=9,10,11,12,13,14,15,16',
    'FREQ=WEEKLY;INTERVAL=2;COUNT=4;BYDAY=TU,SU;WKST=MO', 'FREQ=WEEKLY;INTERVAL=2;COUNT=4;BYDAY=TU,SU;WKST=SU',
    'FREQ=MONTHLY;BYMONTHDAY=15,30;COUNT=5',
);
for my $text (@rfc) {
    my $r = rule($text);
    my $out = $r->rrule;
    is(rule($out)->rrule, $out, "canonical and stable: $text");
    my %given = map { /^([A-Z]+)=(.*)$/ ? ($1 => $2) : () } split /;/, $text;
    my %back = map { /^([A-Z]+)=(.*)$/ ? ($1 => $2) : () } split /;/, $out;
    delete $given{INTERVAL} if ($given{INTERVAL} // 1) == 1;
    delete $given{WKST} if ($given{WKST} // 'MO') eq 'MO';
    is(join(' ', sort keys %back), join(' ', sort keys %given), "the same parts: $text");
    for my $k (sort keys %given) {
        is(join(',', sort split /,/, $back{$k}), join(',', sort split /,/, $given{$k}), "the same $k values: $text") if $k =~ /^BY/;
    }
}

# canonical form: the RFC's order of parts, values ascending, INTERVAL=1 and WKST=MO dropped, any case in
is(rule('byday=fr,mo;freq=weekly;interval=1;wkst=mo;count=3')->rrule, 'FREQ=WEEKLY;COUNT=3;BYDAY=MO,FR', 'parts in the RFC order, values sorted, defaults dropped, case folded');
is(rule('RRULE:FREQ=DAILY')->rrule, 'FREQ=DAILY', 'a leading RRULE: is allowed');
is(rule('FREQ=MONTHLY;BYMONTHDAY=-1,1,15,-15')->rrule, 'FREQ=MONTHLY;BYMONTHDAY=1,15,-1,-15', 'positive month days first, then negative');
is(rule('FREQ=YEARLY;BYDAY=-1FR,2MO,TU')->rrule, 'FREQ=YEARLY;BYDAY=2MO,TU,-1FR', 'weekdays in week order, each with its ordinals');
is(rule('FREQ=YEARLY;BYSETPOS=-1,1')->rrule, 'FREQ=YEARLY;BYSETPOS=-1,1', 'BYSETPOS sorted numerically') if 0;
is(rule('FREQ=DAILY;UNTIL=20261231')->rrule, 'FREQ=DAILY;UNTIL=20261231', 'a DATE until');
is(rule('FREQ=DAILY;BYSECOND=60')->rrule, 'FREQ=DAILY;BYSECOND=60', 'BYSECOND=60 is allowed');
is(rule('FREQ=WEEKLY;BYDAY=+1MO;BYMONTH=1')->freq, 'weekly', 'freq') if 0;

# what the rule says about itself
my $r = rule('FREQ=WEEKLY;INTERVAL=2;COUNT=8;WKST=SU;BYDAY=TU,TH');
is($r->freq, 'weekly', 'freq');
is($r->interval, 2, 'interval');
is($r->count, 8, 'count');
ok(!defined $r->until, 'until is undef with count');
is($r->wkst, 7, 'wkst is Sunday, 7');
ok($r->is_finite, 'a count makes it finite');
ok(!rule('FREQ=DAILY')->is_finite, 'without one it is not');
is($r->start->iso8601, '1997-09-02T09:00:00-04:00', 'start is the value given');
is($r->zone, 'America/New_York', 'zone is the start\'s');
is($r->gap . ' ' . $r->overlap, 'forward earlier', 'the defaults for a rule');
is(rule('FREQ=DAILY;UNTIL=19971224T000000Z')->until->iso8601, '1997-12-23T19:00:00-05:00', 'a UTC until, read in the rule\'s zone');
is(rule('FREQ=DAILY;UNTIL=19971224')->until->iso8601, '1997-12-24T23:59:59-05:00', 'a DATE until is the end of that day in the zone');
is($R->new(rrule => 'FREQ=DAILY;UNTIL=19971224T120000', start => $floating)->until->iso8601, '1997-12-24T12:00:00', 'a floating until for a floating start');
is($R->new(rrule => 'FREQ=DAILY', start => $floating)->zone, 'floating', 'a floating rule');
is($R->new(rrule => 'FREQ=DAILY', start => $start, gap => 'skip', overlap => 'both')->gap, 'skip', 'gap given');
is($R->new(rrule => 'FREQ=DAILY', start => $start, gap => 'skip', overlap => 'both')->overlap, 'both', 'overlap given');
isa_ok($r, 'Time::Keeper::Recurrence');

# errors name the part and the value
my %bad = (
    ''                                   => qr/the rule is empty/,
    'COUNT=3'                            => qr/FREQ is wanted/,
    'FREQ=FORTNIGHTLY'                   => qr/FREQ=FORTNIGHTLY is not one of/,
    'FREQ=DAILY;FREQ=WEEKLY'             => qr/FREQ is given twice/,
    'FREQ=DAILY;COUNT=3;UNTIL=20261231'  => qr/UNTIL and COUNT cannot both be given/,
    'FREQ=DAILY;COUNT=0'                 => qr/COUNT=0 is not a whole number above zero/,
    'FREQ=DAILY;INTERVAL=-2'             => qr/INTERVAL=-2 is not a whole number above zero/,
    'FREQ=DAILY;BYHOUR=24'               => qr/BYHOUR=24 is out of range 0 to 23/,
    'FREQ=DAILY;BYMINUTE=60'             => qr/BYMINUTE=60 is out of range 0 to 59/,
    'FREQ=DAILY;BYSECOND=61'             => qr/BYSECOND=61 is out of range 0 to 60/,
    'FREQ=MONTHLY;BYMONTHDAY=32'         => qr/BYMONTHDAY=32 is out of range 1 to 31, or -1 to -31/,
    'FREQ=MONTHLY;BYMONTHDAY=0'          => qr/BYMONTHDAY=0 is out of range/,
    'FREQ=YEARLY;BYYEARDAY=367'          => qr/BYYEARDAY=367 is out of range 1 to 366/,
    'FREQ=YEARLY;BYWEEKNO=54'            => qr/BYWEEKNO=54 is out of range 1 to 53/,
    'FREQ=YEARLY;BYMONTH=13'             => qr/BYMONTH=13 is out of range 1 to 12/,
    'FREQ=YEARLY;BYMONTH=0'              => qr/BYMONTH=0 is out of range/,
    'FREQ=MONTHLY;BYDAY=XX'              => qr/BYDAY=XX is not a weekday/,
    'FREQ=MONTHLY;BYDAY=0FR'             => qr/BYDAY=0FR is not a weekday, with an ordinal/,
    'FREQ=MONTHLY;BYDAY=54FR'            => qr/BYDAY=54FR is not a weekday/,
    'FREQ=MONTHLY;BYDAY=-FR'             => qr/BYDAY=-FR is not a weekday/,
    'FREQ=WEEKLY;BYDAY=1MO'              => qr/an ordinal in BYDAY needs FREQ=MONTHLY or FREQ=YEARLY/,
    'FREQ=YEARLY;BYWEEKNO=1;BYDAY=1MO'   => qr/an ordinal in BYDAY cannot be given with BYWEEKNO/,
    'FREQ=MONTHLY;BYWEEKNO=1'            => qr/BYWEEKNO needs FREQ=YEARLY/,
    'FREQ=MONTHLY;BYYEARDAY=1'           => qr/BYYEARDAY cannot be given with FREQ=DAILY, WEEKLY or MONTHLY/,
    'FREQ=WEEKLY;BYMONTHDAY=1'           => qr/BYMONTHDAY cannot be given with FREQ=WEEKLY/,
    'FREQ=DAILY;BYSETPOS=1'              => qr/BYSETPOS needs another BY part/,
    'FREQ=DAILY;WKST=XX'                 => qr/WKST=XX is not a weekday MO to SU/,
    'FREQ=DAILY;UNTIL=2026'              => qr/UNTIL=2026 is not a date/,
    'FREQ=DAILY;UNTIL=20260230'          => qr/UNTIL=20260230 is not a date that exists/,
    'FREQ=DAILY;UNTIL=19971224T000000'   => qr/UNTIL must be in UTC \(end in Z\) when the start has a zone/,
    'FREQ=DAILY;X-NAME=HEBREW'           => qr/'X-NAME' is not an RRULE part/,
    'FREQ=DAILY;BYHOUR='                 => qr/BYHOUR has no value/,
    'FREQ=DAILY;BYHOUR=1,'               => qr/BYHOUR ends with a comma/,
    'FREQ=DAILY;BYHOUR=1,,2'             => qr/BYHOUR has an empty value/,
    'FREQ'                               => qr/'FREQ' is not NAME=VALUE/,
);
for my $text (sort keys %bad) {
    dies_like(sub { rule($text) }, $bad{$text}, "dies: '$text'");
}
dies_like(sub { $R->new(rrule => 'FREQ=DAILY;UNTIL=19971224T000000Z', start => $floating) }, qr/UNTIL must be floating \(no Z\) when the start is/, 'a UTC until on a floating start dies');
dies_like(sub { $R->new(rrule => 'FREQ=DAILY') }, qr/start => a Time::Keeper value is wanted/, 'no start dies');
dies_like(sub { $R->new(start => $start) }, qr/rrule => is wanted/, 'no rrule dies');
dies_like(sub { $R->new(rrule => 'FREQ=DAILY', start => 'tomorrow') }, qr/start is not a Time::Keeper value/, 'a start that is not a value dies');
dies_like(sub { $R->new(rrule => 'FREQ=DAILY', start => $start, gap => 'sideways') }, qr/gap is forward, backward, skip or fail, not 'sideways'/, 'a bad gap dies');
dies_like(sub { $R->new(rrule => 'FREQ=DAILY', start => $start, overlap => 'neither') }, qr/overlap is earlier, later or both, not 'neither'/, 'a bad overlap dies');
dies_like(sub { $R->new(rrule => 'FREQ=DAILY', start => $start, zone => 'UTC') }, qr/'zone' is not an argument here/, 'zone with a start dies');
dies_like(sub { $R->new(rrule => 'FREQ=DAILY', start => $start, colour => 'red') }, qr/unknown argument 'colour'/, 'an unknown argument dies');
dies_like(sub { $R->new('rrule') }, qr/key and value pairs/, 'an odd list dies');
dies_like(sub { $R->freq }, qr/not a Time::Keeper::Recurrence/, 'an accessor on the class dies');
my $many = join ',', 1 .. 65;
dies_like(sub { rule("FREQ=YEARLY;BYYEARDAY=$many") }, qr/BYYEARDAY has more than 64 values/, 'a list past 64 dies');

done_testing;
