#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

# Arithmetic against DateTime. Author only. K12 (the owner's) adds months
# before days, where DateTime adds days first, so a duration with both is
# not compared; everything else is: months alone in each end-of-month mode,
# days alone, either with clock time, clock time alone. Where DateTime dies,
# the wall time fell in a gap and it croaks here too; in an overlap the
# answer here is the earlier reading (K3), and DateTime's must be one of
# the two.
BEGIN {
    eval { require DateTime; require DateTime::Duration; 1 }
        or plan skip_all => 'DateTime is not installed';
}
use Time::Keeper;
use Time::Keeper::Zone;

my $y2026 = 1767225600;
my %changed_from = (
    (map { $_ => $y2026 } qw(America/Winnipeg America/Inuvik America/Edmonton
                             America/Vancouver Africa/Casablanca Africa/El_Aaiun)),
    'Europe/Chisinau' => 1640995200,
);
# Two spring forwards corrected after 2025c (2026a): Colombia's on
# 1992-05-02 and Iran's on 1979-05-26 were at 00:00, not 24:00.
my %corrected_day = map { $_ => 1 } 'America/Bogota 1992-05-02', 'Asia/Tehran 1979-05-26';
my %skip = map { $_ => 1 } qw(EST5EDT CST6CDT MST7MDT PST8PDT);
my @zones = grep { !/^Etc\// && !$skip{$_} } Time::Keeper::Zone->names;
push @zones, ('UTC') x 50;

sub exact {
    my ($s, $ns) = @_;
    return $s unless $ns;
    return sprintf('%d.%09d', $s, $ns) if $s >= 0;
    my $whole = $s + 1;
    return ($whole == 0 ? '-0' : $whole) . '.' . sprintf('%09d', 1_000_000_000 - $ns);
}

srand(707);
my %bad;
my ($n, $gaps, $overlaps) = (0, 0, 0);
for (1 .. 30_000) {
    my $zone = $zones[int rand @zones];
    my $s = 0 + int(rand(1_800_000_000));       # 1970 to 2027
    next if $changed_from{$zone} && $s >= $changed_from{$zone} - 400 * 86400;
    my $ns = rand() < .3 ? int(rand(1e9)) : 0;
    my %u;
    my $kind = int rand 4;
    my $sign = rand() < .5 ? -1 : 1;
    if ($kind == 0)    { $u{months} = $sign * (1 + int rand 30) }
    elsif ($kind == 1) { $u{days} = $sign * (1 + int rand 400) }
    elsif ($kind == 2) { $u{months} = $sign * (1 + int rand 30); $u{hours} = $sign * int rand 30; $u{seconds} = $sign * int rand 100 }
    else               { $u{minutes} = $sign * int rand 100_000; $u{seconds} = $sign * int rand 100_000; $u{nanoseconds} = $sign * int rand 1e9 }
    if ($u{months}) {
        my @modes = ('wrap', 'limit', 'preserve');
        $u{end_of_month} = $modes[int rand 3];
    }
    my $t = Time::Keeper->from_epoch(exact($s, $ns), zone => $zone);
    my $dt = DateTime->from_epoch(epoch => $s, time_zone => $zone)->set_nanosecond($ns);
    my $mine = eval { $t->plus(%u) };
    my $mine_later = $mine && eval { $t->plus(%u, overlap => 'later') };
    my $theirs = eval { $dt->clone->add(%u) };
    $n++;
    my $tag = "$zone " . exact($s, $ns) . " + @{[ %u ]}";
    if (!$theirs) {
        $gaps++;
        $bad{gap} //= "$tag: DateTime saw a gap, here $mine" if $mine;
        next;
    }
    next if $changed_from{$zone} && $theirs->epoch >= $changed_from{$zone} - 2 * 86400;
    if (!$mine) {
        $bad{nogap} //= "$tag: died here ($@), DateTime " . $theirs->iso8601;
        next;
    }
    my $want = Time::Keeper->from_epoch(exact($theirs->epoch, $theirs->nanosecond));
    $overlaps++ if $mine != $mine_later;
    $bad{result} //= "$tag: here $mine or $mine_later, DateTime " . $theirs->iso8601
        unless $want == $mine || $want == $mine_later;
    $bad{default} //= "$tag: the default is not the earlier reading" unless $mine <= $mine_later;
}
# Random sums rarely land in a gap or an overlap: aim at them. A day before
# the middle of each change since 1970, plus a day, lands in it.
for my $zone (@zones) {
    next if $zone eq 'UTC';
    for my $c (Time::Keeper::Zone::_changes($zone, 86400, ($changed_from{$zone} // $y2026) - 4 * 86400)) {
        my ($at, $after) = @$c;
        my ($before) = Time::Keeper::Zone::_offset_at($zone, $at - 1);
        next if $before == $after;
        my $w = Time::Keeper->from_epoch($at + int(($before + $after) / 2) - 86400, zone => 'floating');
        my %f = map { $_ => $w->$_ } qw(year month day hour minute second);
        my $land = $w->plus(days => 1);
        next if $corrected_day{ sprintf '%s %04d-%02d-%02d', $zone, $land->year, $land->month, $land->day };
        my $t = eval { Time::Keeper->new(%f, zone => $zone) } or next;
        my $dt = eval { DateTime->new(%f, time_zone => $zone) } or next;
        my $mine = eval { $t->plus(days => 1) };
        my $mine_later = $mine && eval { $t->plus(days => 1, overlap => 'later') };
        my $theirs = eval { $dt->clone->add(days => 1) };
        $n++;
        my $tag = "$zone @{[ %f ]} + a day";
        if (!$theirs) {
            $gaps++;
            $bad{gap} //= "$tag: DateTime saw a gap, here $mine" if $mine;
            next;
        }
        if (!$mine) {
            $bad{nogap} //= "$tag: died here ($@), DateTime " . $theirs->iso8601;
            next;
        }
        my $want = Time::Keeper->from_epoch($theirs->epoch);
        $overlaps++ if $mine != $mine_later;
        $bad{aimed} //= "$tag: here $mine or $mine_later, DateTime " . $theirs->iso8601
            unless $want == $mine || $want == $mine_later;
    }
}

is(scalar keys %bad, 0, "$n random sums agree with DateTime's add ($gaps gaps, $overlaps overlaps)")
    or diag(join "\n", map { "$_: $bad{$_}" } sort keys %bad);

# delta_days against DateTime's.
my $dbad = 0;
for (1 .. 3000) {
    my $zone = $zones[int rand @zones];
    my ($s1, $s2) = map { int(rand(1_700_000_000)) } 1, 2;
    my $a = Time::Keeper->from_epoch($s1, zone => $zone);
    my $b = Time::Keeper->from_epoch($s2, zone => $zone);
    my $da = DateTime->from_epoch(epoch => $s1, time_zone => $zone);
    my $db = DateTime->from_epoch(epoch => $s2, time_zone => $zone);
    $dbad++ unless $b->delta_days($a)->days + 7 * $b->delta_days($a)->weeks == $db->delta_days($da)->in_units('days');
}
is($dbad, 0, 'delta_days agrees with DateTime on 3,000 pairs');

done_testing;
