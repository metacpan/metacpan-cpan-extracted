#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Time::Keeper;
use Time::Keeper::Recurrence;

# Author test: random cron expressions against Python's croniter, the next
# twenty occurrences after a moment, in UTC. croniter reads both day fields
# as either, as Vixie cron and this module do, but counts a day field
# written */n as restricted where Punk::Queue and this module (and Vixie
# cron, for */1) do not, so the two day fields never take a step here.
# Skipped without croniter.

my $py = $ENV{TKR_PYTHON} || 'python3';
plan skip_all => "$py has no croniter" unless system("$py -I -c 'import croniter' >/dev/null 2>&1") == 0;
my $N = $ENV{TKR_ORACLE_N} || 300;

srand($ENV{TKR_SEED} || 20261018);
sub field {
    my ($lo, $hi) = @_;
    my $k = rand();
    return '*' if $k < 0.4;
    return join(',', map { $lo + int rand($hi - $lo + 1) } 1 .. 1 + int rand 3) if $k < 0.7;
    my $a = $lo + int rand($hi - $lo); my $b = $a + 1 + int rand($hi - $a);
    return $k < 0.85 ? "$a-$b" : '*/' . (1 + int rand(($hi - $lo) / 2 || 1));
}
my @exprs;
while (@exprs < $N) {
    my $e = join ' ', field(0, 59), field(0, 23), field(1, 31), field(1, 12), field(0, 6);
    redo if (split ' ', $e)[2] =~ m{[/-]} || (split ' ', $e)[4] =~ m{[/-]};   # nor a range: 0-6 is unrestricted here, restricted to croniter
    my $r = eval { Time::Keeper::Recurrence->cron($e) } or next;
    push @exprs, [$e, $r];
}
my $from = Time::Keeper->new(year => 2026, month => 1, day => 1, zone => 'UTC');

my $dir = tempdir(CLEANUP => 1);
open my $in, '>', "$dir/exprs.txt" or die;
print $in $_->[0], "\n" for @exprs;
close $in;
open my $script, '>', "$dir/oracle.py" or die;
print $script <<'PY';
import sys, datetime
from datetime import timezone
from croniter import croniter
base = datetime.datetime(2026, 1, 1, tzinfo=timezone.utc)
for line in open(sys.argv[1]):
    expr = line.rstrip("\n")
    try:
        it = croniter(expr, base, ret_type=datetime.datetime)
        out = [it.get_next().strftime("%Y-%m-%dT%H:%M:%SZ") for _ in range(20)]
        print(" ".join(out))
    except Exception as e:
        print("ERROR " + str(e).replace("\n", " "))
PY
close $script;
my @oracle = `$py -I $dir/oracle.py $dir/exprs.txt`;
chomp @oracle;
is(scalar @oracle, scalar @exprs, 'the oracle answered every expression');

my ($agree, $skipped) = (0, 0);
for my $i (0 .. $#exprs) {
    my ($e, $r) = @{ $exprs[$i] };
    my $theirs = $oracle[$i] // '';
    if ($theirs =~ /^ERROR/) { $skipped++; next }
    my @mine;
    my $cur = $from;
    for (1 .. 20) { my $n = eval { $r->next($cur) } or last; push @mine, $n->iso8601; $cur = $n }
    my $ours = join ' ', @mine;
    if ($ours eq $theirs) { $agree++ }
    else { fail("'$e'"); diag("ours:   $ours\ntheirs: $theirs") }
}
cmp_ok($agree, '>=', scalar(@exprs) - $skipped, "$agree of @{[ scalar @exprs ]} expressions agree with croniter ($skipped refused by it)");

done_testing;
