#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

# Values against DateTime. Author only. DateTime::TimeZone 2.66 carries
# tzdata 2025c and Time::Keeper::Zone 2026e: the zones changed between them
# are compared only before the change (see Time-Keeper-Zone's
# xt/04-datetime-oracle.t for the reasons), the System V names only from 1967,
# and the Etc/GMT names only by offset.
BEGIN {
    eval { require DateTime; require DateTime::TimeZone; 1 }
        or plan skip_all => 'DateTime and DateTime::TimeZone are not installed';
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
my %system_v = map { $_ => 1 } qw(EST5EDT CST6CDT MST7MDT PST8PDT);
my @zones = grep { !/^Etc\// } Time::Keeper::Zone->names;

# Seconds and nanoseconds after them as the decimal they are: -10 and
# 250000000 is -9.75, not "-10.25".
sub exact {
    my ($s, $ns) = @_;
    return $s unless $ns;
    return sprintf('%d.%09d', $s, $ns) if $s >= 0;
    my $whole = $s + 1;
    return ($whole == 0 ? '-0' : $whole) . '.' . sprintf('%09d', 1_000_000_000 - $ns);
}

my @fields = qw(year month day hour minute second nanosecond day_of_week day_of_year
                quarter day_of_quarter week_year week week_of_month offset is_dst epoch);
sub dt_field {
    my ($dt, $f) = @_;
    return ($dt->week)[0] if $f eq 'week_year';
    return ($dt->week)[1] if $f eq 'week';
    return $dt->is_dst ? 1 : 0 if $f eq 'is_dst';
    return $dt->$f;
}

srand(606);
my (%bad, $n);
for (1 .. 20_000) {
    my $zone = $zones[int rand @zones];
    my $s = int(rand(5_000_000_000)) - 2_000_000_000;   # 1906 to 2128
    next if $changed_from{$zone} && $s >= $changed_from{$zone};
    next if $system_v{$zone} && $s < -94694400;
    my $ns = int(rand(1_000_000_000));
    my $t = Time::Keeper->from_epoch(exact($s, $ns), zone => $zone);
    my $dt = DateTime->from_epoch(epoch => $s, time_zone => $zone)->set_nanosecond($ns);
    $n++;
    for my $f (@fields) {
        my ($mine, $theirs) = ($t->$f, dt_field($dt, $f));
        next if $mine == $theirs;
        $bad{$f} //= "$zone $s.$ns: here $mine, DateTime $theirs";
    }
    $bad{zone_abbr} //= "$zone $s: here " . $t->zone_abbr . ', DateTime ' . $dt->time_zone_short_name
        if $t->zone_abbr ne $dt->time_zone_short_name;
    my $jd = $t->julian_day - $dt->jd;
    $bad{julian_day} //= "$zone $s: off by $jd" if abs($jd) > 1e-6;
}
is(scalar keys %bad, 0, "every field of $n random values in random zones agrees with DateTime")
    or diag(join "\n", map { "$_: $bad{$_}" } sort keys %bad);

# Wall-clock times through new: where DateTime dies, the time fell in a
# gap and croaks here; elsewhere DateTime's instant is one of the readings
# here, and the default (K3) is the earlier.
my %rbad;
my ($rn, $gaps, $overlaps) = (0, 0, 0);
for (1 .. 20_000) {
    my $zone = $zones[int rand @zones];
    next if $system_v{$zone};
    my %f = (year => 1970 + int(rand(56)), month => 1 + int(rand(12)), day => 1 + int(rand(28)),
             hour => int(rand(24)), minute => int(rand(60)), second => int(rand(60)));
    my $dt = eval { DateTime->new(%f, time_zone => $zone) };
    next if $changed_from{$zone} && (!$dt || $dt->epoch >= $changed_from{$zone} - 86400);
    $rn++;
    my $mine = eval { Time::Keeper->new(%f, zone => $zone) };
    if (!$dt) {
        $gaps++;
        $rbad{$zone} //= "@{[%f]}: DateTime saw a gap, here " . ($mine // "died: $@") if $mine;
        next;
    }
    my $later = Time::Keeper->new(%f, zone => $zone, overlap => 'later');
    $overlaps++ if $later != $mine;
    $rbad{$zone} //= "@{[%f]}: DateTime " . $dt->epoch . ", here " . $mine->epoch . ' or ' . $later->epoch
        unless $dt->epoch == $mine->epoch || $dt->epoch == $later->epoch;
    $rbad{$zone} //= "@{[%f]}: the default is not the earlier reading"
        unless $mine <= $later;
}
# Random times rarely land in a gap or an overlap, so aim at them: the
# middle of every change of offset since 1970 in every zone.
for my $zone (@zones) {
    next if $system_v{$zone};
    for my $c (Time::Keeper::Zone::_changes($zone, 0, ($changed_from{$zone} // $y2026) - 86400)) {
        my ($at, $after) = @$c;
        my ($before) = Time::Keeper::Zone::_offset_at($zone, $at - 1);
        next if $before == $after;
        my $mid = $at + int(($before + $after) / 2);
        my $w = Time::Keeper->from_epoch($mid, zone => 'floating');
        my %f = map { $_ => $w->$_ } qw(year month day hour minute second);
        next if $corrected_day{ sprintf '%s %04d-%02d-%02d', $zone, @f{qw(year month day)} };
        my $dt = eval { DateTime->new(%f, time_zone => $zone) };
        my $mine = eval { Time::Keeper->new(%f, zone => $zone) };
        $rn++;
        if (!$dt) {
            $gaps++;
            $rbad{$zone} //= "@{[%f]}: DateTime saw a gap, here " . $mine if $mine;
            next;
        }
        if (!$mine) {
            $rbad{$zone} //= "@{[%f]}: a gap here, DateTime " . $dt->epoch;
            next;
        }
        my $later = Time::Keeper->new(%f, zone => $zone, overlap => 'later');
        $overlaps++ if $later != $mine;
        $rbad{$zone} //= "@{[%f]}: DateTime " . $dt->epoch . ", here " . $mine->epoch . ' or ' . $later->epoch
            unless $dt->epoch == $mine->epoch || $dt->epoch == $later->epoch;
    }
}

is(scalar keys %rbad, 0, "$rn wall-clock times resolve as DateTime does or as one of its readings ($gaps gaps, $overlaps overlaps)")
    or diag(join "\n", map { "$_: $rbad{$_}" } grep { defined } (sort keys %rbad)[0 .. 4]);

done_testing;
