#!perl
# until against DateTime and against the exact difference. Author only. In
# UTC between 2017 and 2026 there are no leap seconds, so: largest seconds
# is minus_absolute; largest hours is the epoch difference in minutes and
# seconds; largest days is DateTime's delta_days, less one when the later
# value's time of day is the earlier, and the rest in seconds. Every
# largest round-trips in four zones without DateTime.
use 5.010;
use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require DateTime; 1 } or plan skip_all => 'DateTime is needed for this oracle';
}
use Time::Keeper;

my $K = 'Time::Keeper';
my $N = $ENV{TK_ORACLE_N} || 20_000;
srand($ENV{TK_SEED} || 20261017);
my ($lo, $hi) = (1_483_228_800, 1_798_761_599);
my $bad = 0;

for my $i (1 .. $N) {
    my ($e1, $e2) = ($lo + int(rand($hi - $lo)), $lo + int(rand($hi - $lo)));
    my ($n1, $n2) = (int(rand(1e9)), int(rand(1e9)));
    my $x = $K->from_epoch($e1)->plus(nanoseconds => $n1);
    my $y = $K->from_epoch($e2)->plus(nanoseconds => $n2);
    my $sign = ($e2 > $e1 || ($e2 == $e1 && $n2 >= $n1)) ? 1 : -1;
    my ($ds, $dn) = ($e2 - $e1, $n2 - $n1);
    if ($dn < 0) { $ds--; $dn += 1e9 }
    if ($ds < 0 && $dn > 0) { $ds++; $dn -= 1e9 }

    my $sec = $x->until($y, largest => 'seconds');
    my ($gs, $gn) = $sec->in_units('seconds', 'nanoseconds');
    unless ($gs == $ds && $gn == $dn && $sec->total_seconds == $y->minus_absolute($x)->total_seconds) {
        $bad++;
        diag("seconds: $x until $y gives $sec, want $ds s $dn ns");
    }
    my $hrs = $x->until($y, largest => 'hours');
    my ($hm, $hs, $hn) = $hrs->in_units('minutes', 'seconds', 'nanoseconds');
    my $want_m = $sign > 0 ? int($ds / 60) : -int(-$ds / 60);
    unless ($hm == $want_m && $hs == $ds - $want_m * 60 && $hn == $dn) {
        $bad++;
        diag("hours: $x until $y gives $hrs, want $want_m min " . ($ds - $want_m * 60) . " s $dn ns");
    }
    my ($dt1, $dt2) = (DateTime->from_epoch(epoch => $e1), DateTime->from_epoch(epoch => $e2));
    my ($a, $b) = $sign > 0 ? ($dt1, $dt2) : ($dt2, $dt1);
    my $days = $a->delta_days($b)->in_units('days');
    $days-- if $days && $a->clone->add(days => $days) > $b;
    my $rest = ($sign > 0 ? $e2 - $e1 : $e1 - $e2) - $days * 86400;
    my $dd = $x->until($y, largest => 'days');
    my ($gd, $gm, $gsec, $gns) = $dd->in_units('days', 'minutes', 'seconds', 'nanoseconds');
    my $got_rest2 = abs($gm) * 60 + abs($gsec);
    unless (abs($gd) == $days && $got_rest2 == $rest - (($sign > 0 ? $n2 < $n1 : $n1 < $n2) ? 1 : 0)) {
        $bad++;
        diag("days: $x until $y gives $dd, want $days days and $rest s of clock");
    }
    last if $bad > 20;
}
is($bad, 0, "$N random pairs agree with DateTime's days and the exact seconds");

my $rt = 0;
my @zones = ('UTC', 'Europe/London', 'America/New_York', 'Australia/Lord_Howe');
for my $i (1 .. $N / 4) {
    my $z = $zones[$i % 4];
    my $x = $K->from_epoch(int(rand(4e9)) - 2e9, zone => $z)->plus(nanoseconds => int(rand(1e9)));
    my $y = $K->from_epoch(int(rand(4e9)) - 2e9, zone => $z)->plus(nanoseconds => int(rand(1e9)));
    for my $largest (qw(years months weeks days hours minutes seconds nanoseconds)) {
        my $d = $x->until($y, largest => $largest);
        my $back = eval { $x->plus($d) };
        next if $back && $back == $y;
        $rt++;
        diag("$x until $y largest $largest: $d adds back to " . ($back // "death: $@"));
    }
    last if $rt > 20;
}
is($rt, 0, 'and every largest round-trips in four zones');

done_testing;
