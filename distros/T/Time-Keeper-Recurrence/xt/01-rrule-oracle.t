#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Time::Keeper;
use Time::Keeper::Recurrence;

# Author test: random RRULEs against Python's dateutil.rrule, the first
# forty occurrences strictly after the start (dateutil leaves out a start
# that does not fit the rule, where the RFC and this module count it), in
# UTC. Two shapes are kept out, where dateutil departs from the RFC: a BYDAY
# list mixing ordinals and plain weekdays (dateutil ANDs the two kinds; the
# RFC's BYDAY=1SU,-1SU example is an OR), and BYSETPOS with FREQ=WEEKLY
# (dateutil counts the start's week from the start's day; the RFC's monthly
# BYSETPOS example counts from the period's first day). TKR_PYTHON names the
# interpreter; skipped when dateutil is missing.

my $py = $ENV{TKR_PYTHON} || 'python3';
my $ok = system("$py -I -c 'import dateutil.rrule' >/dev/null 2>&1") == 0;
plan skip_all => "$py has no dateutil" unless $ok;
my $N = $ENV{TKR_ORACLE_N} || 400;

srand($ENV{TKR_SEED} || 20261018);
my @freq = qw(YEARLY MONTHLY WEEKLY DAILY HOURLY MINUTELY);
my @days = qw(MO TU WE TH FR SA SU);
my @rules;
while (@rules < $N) {
    my $f = $freq[int rand @freq];
    my @parts = ("FREQ=$f");
    push @parts, 'INTERVAL=' . (1 + int rand 5) if rand() < 0.6;
    if (rand() < 0.5 && $f ne 'HOURLY' && $f ne 'MINUTELY') {
        my $ordinals = ($f eq 'MONTHLY' || $f eq 'YEARLY') && rand() < 0.3;   # all ordinal or all plain, never mixed
        my @d = map { my $o = $ordinals ? ((rand() < 0.5 ? '-' : '') . (1 + int rand 4)) : ''; $o . $days[int rand 7] } 1 .. 1 + int rand 3;
        push @parts, 'BYDAY=' . join(',', @d);
    }
    push @parts, 'BYMONTHDAY=' . join(',', map { (rand() < 0.2 ? '-' : '') . (1 + int rand 28) } 1 .. 1 + int rand 2) if rand() < 0.3 && $f ne 'WEEKLY';
    push @parts, 'BYMONTH=' . join(',', map { 1 + int rand 12 } 1 .. 1 + int rand 2) if rand() < 0.3;
    push @parts, 'BYYEARDAY=' . join(',', map { 1 + int rand 365 } 1 .. 1 + int rand 2) if rand() < 0.15 && $f eq 'YEARLY';
    push @parts, 'BYWEEKNO=' . (1 + int rand 52) if rand() < 0.1 && $f eq 'YEARLY' && !grep { /^BYDAY=.*\d/ } @parts;
    push @parts, 'BYHOUR=' . join(',', map { int rand 24 } 1 .. 1 + int rand 2) if rand() < 0.4 && $f ne 'HOURLY' && $f ne 'MINUTELY';
    push @parts, 'BYMINUTE=' . join(',', map { int rand 60 } 1 .. 1 + int rand 2) if rand() < 0.3 && $f ne 'MINUTELY';
    push @parts, 'BYSETPOS=' . ((rand() < 0.5 ? '-' : '') . (1 + int rand 3)) if rand() < 0.15 && $f ne 'WEEKLY' && grep { /^BY/ } @parts;
    push @parts, 'WKST=' . $days[int rand 7] if rand() < 0.2;
    my $text = join ';', @parts;
    my $start = Time::Keeper->new(year => 2020 + int rand 10, month => 1 + int rand 12, day => 1 + int rand 28, hour => int rand 24, minute => int rand 60, zone => 'UTC');
    my $r = eval { Time::Keeper::Recurrence->new(rrule => $text, start => $start) } or next;
    eval { $r->next($start) } or next;      # a rule that never fires would hang dateutil, which has no horizon
    push @rules, [$text, $start, $r];
}

my $dir = tempdir(CLEANUP => 1);
open my $in, '>', "$dir/rules.txt" or die;
print $in join("\t", $_->[0], $_->[1]->strftime('%Y%m%dT%H%M%S')), "\n" for @rules;
close $in;
open my $script, '>', "$dir/oracle.py" or die;
print $script <<'PY';
import sys, datetime
from dateutil.rrule import rrulestr
from datetime import timezone
for line in open(sys.argv[1]):
    text, start = line.rstrip("\n").split("\t")
    dt = datetime.datetime.strptime(start, "%Y%m%dT%H%M%S").replace(tzinfo=timezone.utc)
    try:
        rule = rrulestr(text, dtstart=dt)
        out = []
        for o in rule:
            if o <= dt:
                continue
            out.append(o.strftime("%Y-%m-%dT%H:%M:%SZ"))
            if len(out) >= 40:
                break
        print(" ".join(out))
    except Exception as e:
        print("ERROR " + str(e).replace("\n", " "))
PY
close $script;
my @oracle = do { local $SIG{ALRM} = sub { die "the oracle took more than ten minutes\n" }; alarm 600; my @o = `$py -I $dir/oracle.py $dir/rules.txt`; alarm 0; @o };
chomp @oracle;
is(scalar @oracle, scalar @rules, 'the oracle answered every rule');

my ($agree, $skipped) = (0, 0);
for my $i (0 .. $#rules) {
    my ($text, $start, $r) = @{ $rules[$i] };
    my $theirs = $oracle[$i] // '';
    if ($theirs =~ /^ERROR/) { $skipped++; diag("dateutil refused $text: $theirs") if $ENV{TKR_ORACLE_DIAG}; next }
    my @mine;
    my $cur = $start;
    for (1 .. 40) { my $n = eval { $r->next($cur) } or last; push @mine, $n->iso8601; $cur = $n }
    my $ours = join ' ', @mine;
    if ($ours eq $theirs) { $agree++ }
    else { fail("$text from " . $start->iso8601); diag("ours:   $ours\ntheirs: $theirs") }
}
cmp_ok($agree, '>=', scalar(@rules) - $skipped, "$agree of @{[ scalar @rules ]} rules agree with dateutil ($skipped refused by it)");

done_testing;
