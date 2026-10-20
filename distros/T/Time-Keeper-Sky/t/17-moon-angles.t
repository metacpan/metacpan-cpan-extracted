#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Time::Keeper;
use Time::Keeper::Sun;
use Time::Keeper::Moon;

# The moon's bright limb (Meeus 48.5) and parallactic angle (14.1): example
# 48.a, and each against the same angle found another way, by vectors for
# the bright limb and from the altitude and azimuth for the parallactic
# angle.

sub utc { Time::Keeper->new(@_, zone => 'UTC') }
sub near { my ($got, $want, $tol, $name) = @_; cmp_ok(abs($got - $want), '<=', $tol, "$name: $got within $tol of $want") }
sub angle_diff { my $d = abs($_[0] - $_[1]); $d -= 360 * int($d / 360); $d > 180 ? 360 - $d : $d }
my $R = atan2(1, 1) / 45;

# ---- example 48.a: 1992 April 12, 0h TD ---------------------------------------

{
    my $td = utc(year => 1992, month => 4, day => 12)->epoch;
    my $ut = $td - Time::Keeper::Sun->delta_t($td);
    my $p = Time::Keeper::Moon->position($ut);
    near($p->{bright_limb}, 285.0, 0.1, 'example 48.a: the bright limb (the book: 285.0, from its higher-accuracy sun)');
}

# ---- the bright limb is the direction of the sun ------------------------------

# The position angle of the sun from the moon, by vectors: the sun's direction
# projected on the sky at the moon, against the moon's north and east.
sub pa_by_vectors {
    my ($ra, $dec, $ra0, $dec0) = map { $_ * $R } @_;
    my @m = (cos($dec) * cos($ra), cos($dec) * sin($ra), sin($dec));
    my @s = (cos($dec0) * cos($ra0), cos($dec0) * sin($ra0), sin($dec0));
    my @n = (-sin($dec) * cos($ra), -sin($dec) * sin($ra), cos($dec));
    my @e = (-sin($ra), cos($ra), 0);
    my $dot = sub { $_[0][0] * $_[1][0] + $_[0][1] * $_[1][1] + $_[0][2] * $_[1][2] };
    my $k = $dot->(\@s, \@m);
    my @d = map { $s[$_] - $k * $m[$_] } 0 .. 2;
    my $pa = atan2($dot->(\@d, \@e), $dot->(\@d, \@n)) / $R;
    return $pa < 0 ? $pa + 360 : $pa;
}

{
    my $sun = Time::Keeper::Sun->new(place => 'Europe/London');
    my $t0 = utc(year => 2026, month => 1, day => 1)->epoch;
    my ($worst, $n, $side_ok) = (0, 0, 1);
    for (my $e = $t0; $e < $t0 + 365 * 86400; $e += 6 * 3600) {
        my $m = Time::Keeper::Moon->position($e);
        my $s = $sun->position($e);
        my $d = angle_diff($m->{bright_limb}, pa_by_vectors($m->{right_ascension}, $m->{declination}, $s->{right_ascension}, $s->{declination}));
        $worst = $d if $d > $worst;
        my $el = Time::Keeper::Moon->elongation($e);
        $side_ok = 0 if $el > 30 && $el < 150 && !($m->{bright_limb} > 180 && $m->{bright_limb} < 360);
        $side_ok = 0 if $el > 210 && $el < 330 && !($m->{bright_limb} > 0 && $m->{bright_limb} < 180);
        $n++;
    }
    cmp_ok($worst, '<=', 1e-9, "2026 every 6 hours ($n): the bright limb is the sun's position angle by vectors (worst $worst)");
    ok($side_ok, 'a waxing moon is lit on its west (180 to 360), a waning one on its east');
    my $p = Time::Keeper::Moon->position($t0);
    cmp_ok($p->{bright_limb}, '>=', 0, 'from 0');
    cmp_ok($p->{bright_limb}, '<', 360, 'to 360');
}

# ---- the parallactic angle ------------------------------------------------------

# From the topocentric altitude and azimuth alone: the declination by the
# cosine rule in the triangle pole, zenith, moon, then the angle at the moon.
sub q_from_altaz {
    my ($lat, $alt, $az) = map { $_ * $R } @_;
    my $sd = sin($lat) * sin($alt) + cos($lat) * cos($alt) * cos($az);
    my $cd = sqrt(1 - $sd * $sd);
    my $sq = -cos($lat) * sin($az) / $cd;
    my $cq = (sin($lat) - sin($alt) * $sd) / (cos($alt) * $cd);
    return atan2($sq, $cq) / $R;
}

for my $where (['Europe/London'], ['Australia/Sydney'], ['America/Denver'], ['Asia/Kolkata']) {
    my $sun = Time::Keeper::Sun->new(place => $where->[0]);
    my $t0 = utc(year => 2026, month => 10, day => 1)->epoch;
    my ($worst, $n) = (0, 0);
    for (my $e = $t0; $e < $t0 + 30 * 86400; $e += 3 * 3600 + 17) {
        my $p = Time::Keeper::Moon->position($e, place => $sun);
        my $d = angle_diff($p->{parallactic_angle}, q_from_altaz($sun->latitude, $p->{altitude}, $p->{azimuth}));
        $worst = $d if $d > $worst;
        $n++;
    }
    cmp_ok($worst, '<=', 1e-6, "$where->[0], October 2026 ($n): the parallactic angle from the altitude and azimuth (worst $worst)");
}

{
    my $london = Time::Keeper::Sun->new(place => 'Europe/London');
    my $sydney = Time::Keeper::Sun->new(place => 'Australia/Sydney');
    my $t = utc(year => 2026, month => 10, day => 19);
    my $tr = Time::Keeper::Moon->next_moon_transit($t, place => $london);
    my $at = Time::Keeper::Moon->position($tr, place => $london);
    near($at->{parallactic_angle}, 0, 0.05, 'London: 0 at the moon\'s upper transit');
    cmp_ok(Time::Keeper::Moon->position($tr->epoch + 3 * 3600, place => $london)->{parallactic_angle}, '>', 0, '  positive after it, west of the meridian');
    cmp_ok(Time::Keeper::Moon->position($tr->epoch - 3 * 3600, place => $london)->{parallactic_angle}, '<', 0, '  negative before it');
    $tr = Time::Keeper::Moon->next_moon_transit($t, place => $sydney);
    $at = Time::Keeper::Moon->position($tr, place => $sydney);
    near(180 - abs($at->{parallactic_angle}), 0, 0.05, 'Sydney, where the moon transits north of the zenith: 180 at the transit');
    my $p = Time::Keeper::Moon->position($t, place => $london);
    cmp_ok($p->{parallactic_angle}, '>=', -180, 'from -180');
    cmp_ok($p->{parallactic_angle}, '<=', 180, 'to 180');
    ok(!exists Time::Keeper::Moon->position($t)->{parallactic_angle}, 'no place, no parallactic angle');
    ok(exists Time::Keeper::Moon->position($t)->{bright_limb}, 'but a bright limb: it needs none');
}

# ---- the tracks carry both ------------------------------------------------------

{
    my $sun = Time::Keeper::Sun->new(place => 'Europe/London');
    my $t0 = utc(year => 2026, month => 10, day => 19)->epoch;
    my $mt = Time::Keeper::Moon->track(from => $t0, to => $t0 + 86400, step => 600, place => $sun);
    my $worst = 0;
    for my $k (0 .. $#{ $mt->{epoch} }) {
        my $p = Time::Keeper::Moon->position($mt->{epoch}[$k], place => $sun);
        for (qw(bright_limb parallactic_angle)) {
            my $d = abs($mt->{$_}[$k] - $p->{$_});
            $worst = $d if $d > $worst;
        }
    }
    cmp_ok($worst, '<=', 1e-9, "the moon's track: bright_limb and parallactic_angle are position's (worst $worst)");
    my $geo = Time::Keeper::Moon->track(from => $t0, to => $t0 + 3600);
    ok($geo->{bright_limb} && !$geo->{parallactic_angle}, 'with no place: the bright limb, no parallactic angle');
}

done_testing;
