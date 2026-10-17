#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

# The engine against DateTime::TimeZone. Author only. DateTime::TimeZone
# 2.66 carries tzdata 2025c, eight releases behind this dist's 2026e, so
# some zones are expected to differ; each is listed with the reason, and
# the test checks that it differs ONLY in that way.

BEGIN {
    eval { require DateTime; require DateTime::TimeZone; 1 }
        or plan skip_all => 'DateTime and DateTime::TimeZone are not installed';
}
use Time::Keeper::Zone;

my $y2026 = 1767225600;

# Changed in tzdata after 2025c (see NEWS): the same before the date given,
# not after. Moldova has used EU transition times since 2022 (2026a); the
# rest change their future (2026a to 2026e).
my %changed_from = (
    (map { $_ => $y2026 } qw(America/Winnipeg America/Inuvik America/Edmonton
                             America/Vancouver Africa/Casablanca Africa/El_Aaiun)),
    'Europe/Chisinau' => 1640995200,
);
# Single transitions corrected after 2025c (NEWS): Colombia's 1992-05-02
# and Iran's 1979-05-26 spring forward were at 00:00, not 24:00. Wall
# times on those two days are not compared.
my %corrected_day = map { $_ => 1 } 'America/Bogota 1992-05-02', 'Asia/Tehran 1979-05-26';

# EST5EDT and the others became links to geographic zones in 2024b, which
# DateTime 2.66 follows; 2026d made them zones of their own again, on the
# US rules alone. They differ before 1967 and agree after.
my %system_v = map { $_ => 1 } qw(EST5EDT CST6CDT MST7MDT PST8PDT);
my $y1967 = -94694400;
# DateTime makes the Etc/GMT zones itself, abbreviated "+0100" and "UTC"
# where tzdata has "+01" and "GMT": the same offsets, other spellings.
my %abbr_only = map { $_ => 1 } grep { /^Etc\/GMT/ } Time::Keeper::Zone->names;

srand(2026);
my (%bad, $n);
for my $name (Time::Keeper::Zone->names) {
    my $tz = DateTime::TimeZone->new(name => $name);
    for (1 .. 300) {
        my $t = int(rand(5_400_000_000)) - 2_000_000_000;   # 1906 to 2077
        next if $changed_from{$name} && $t >= $changed_from{$name};
        next if $system_v{$name} && $t < $y1967;
        my $dt = DateTime->from_epoch(epoch => $t);
        my ($off, undef, $abbr) = Time::Keeper::Zone::_offset_at($name, $t);
        my ($doff, $dabbr) = ($tz->offset_for_datetime($dt), $tz->short_name_for_datetime($dt));
        $n++;
        next if $off == $doff && ($abbr eq $dabbr || $abbr_only{$name});
        $bad{$name} //= "$t: DateTime $doff $dabbr, here $off $abbr";
    }
}
is(scalar keys %bad, 0, "$n random instants agree with DateTime::TimeZone $DateTime::TimeZone::VERSION, apart from the listed differences")
    or diag(join "\n", map { "$_: $bad{$_}" } sort keys %bad);

# Wall-clock times, through DateTime->new: a gap must die there and be a gap
# here, and in an overlap DateTime's instant must be one of the two found
# here. Which of the two DateTime takes is its own rule: it prefers a
# standard-time span to a DST one, and otherwise whichever its binary
# search landed on. Matching that is not the engine's job; the caller
# chooses earlier or later.
my %rbad;
my ($rn, $gaps, $overlaps, $picked_earlier) = (0, 0, 0, 0);
for my $name (Time::Keeper::Zone->names) {
    next if $system_v{$name};
    my @c = Time::Keeper::Zone::_changes($name, 0, ($changed_from{$name} // $y2026) - 86400);
    for my $c (@c) {
        my $t = $c->[0];
        my ($before) = Time::Keeper::Zone::_offset_at($name, $t - 1);
        next if $before == $c->[1];
        my $local = $t + ($before < $c->[1] ? $before : $c->[1]) + 1;
        my @g = gmtime $local;
        next if $corrected_day{ sprintf '%s %04d-%02d-%02d', $name, $g[5] + 1900, $g[4] + 1, $g[3] };
        my ($r, $u) = Time::Keeper::Zone::_resolve_local($name, $local, 0, 0);
        my (undef, $e) = Time::Keeper::Zone::_resolve_local($name, $local, 0, 1);
        my @f = (gmtime $local)[5, 4, 3, 2, 1, 0];
        my $dt = eval {
            DateTime->new(year => $f[0] + 1900, month => $f[1] + 1, day => $f[2],
                          hour => $f[3], minute => $f[4], second => $f[5], time_zone => $name);
        };
        $rn++;
        if (!$dt) {
            $gaps++;
            $rbad{$name} //= "$local: DateTime saw a gap, here result $r" unless $r == 2;
        }
        else {
            $overlaps++ if $r == 1;
            $picked_earlier++ if $r == 1 && $dt->epoch == $e && $e != $u;
            $rbad{$name} //= "$local: DateTime " . $dt->epoch . ", here " . ($u // 'undef') . " or " . ($e // 'undef')
                unless defined $u && ($u == $dt->epoch || ($r == 1 && $e == $dt->epoch));
        }
    }
}
is(scalar keys %rbad, 0, "$rn wall-clock times at changes since 1970 resolve as DateTime does ($gaps gaps, $overlaps overlaps)")
    or diag(join "\n", map { "$_: $rbad{$_}" } sort keys %rbad);
diag("in $picked_earlier of the $overlaps overlaps DateTime took the earlier instant");

done_testing;
