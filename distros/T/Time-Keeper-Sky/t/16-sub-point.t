#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Time::Keeper;
use Time::Keeper::Sun;
use Time::Keeper::Moon;

# Sub-points: where the sun and the moon are overhead. The latitude is the
# declination; the longitude is minus the Greenwich hour angle, which USNO's
# celestial navigation data gives for both (t/usno-celnav.tsv,
# t/usno-celnav-moon.tsv).

sub utc { Time::Keeper->new(@_, zone => 'UTC') }
sub near { my ($got, $want, $tol, $name) = @_; cmp_ok(abs($got - $want), '<=', $tol, "$name: $got within $tol of $want") }
sub angle_diff { my $d = abs($_[0] - $_[1]); $d -= 360 * int($d / 360); $d > 180 ? 360 - $d : $d }

# ---- against USNO -------------------------------------------------------------

for my $body (['Sun', 'usno-celnav.tsv', 'Time::Keeper::Sun'], ['Moon', 'usno-celnav-moon.tsv', 'Time::Keeper::Moon']) {
    my ($name, $base, $class) = @$body;
    my $file = -e "t/$base" ? "t/$base" : $base;
    open my $fh, '<', $file or die "$file: $!";
    my ($rows, $worst_lat, $worst_lon) = (0, 0, 0);
    while (my $line = <$fh>) {
        next if $line =~ /^#/;
        chomp $line;
        my ($place, $date, $time, $lat, $lon, $dec, $gha) = split /\t/, $line;
        my ($y, $m, $d) = split /-/, $date;
        my ($h, $mi, $s) = split /:/, $time;
        my $t = utc(year => $y, month => $m, day => $d, hour => $h, minute => $mi, second => $s);
        my ($slat, $slon) = $class->sub_point($t);
        cmp_ok($slon, '>=', -180, "$name $place $date: the longitude is from -180");
        cmp_ok($slon, '<=', 180, '  to 180');
        my $dl = abs($slat - $dec);
        my $dn = angle_diff($slon, -$gha);
        $worst_lat = $dl if $dl > $worst_lat;
        $worst_lon = $dn if $dn > $worst_lon;
        $rows++;
    }
    cmp_ok($rows, '>=', 20, "$name: USNO rows read ($rows)");
    cmp_ok($worst_lat, '<=', 0.005, "$name: the sub-latitude is USNO's declination (worst $worst_lat)");
    cmp_ok($worst_lon, '<=', 0.01, "$name: the sub-longitude is minus USNO's GHA (worst $worst_lon)");
}

# ---- the sun's sub-point and the sun's own events -------------------------------

{
    my $t = utc(year => 2026, month => 10, day => 19, hour => 9, minute => 30);
    my $sun = Time::Keeper::Sun->new(place => 'Europe/London');
    my ($lat) = $sun->sub_point($t);
    is($lat, $sun->position($t)->{declination}, 'the sub-latitude is position\'s declination');
    is_deeply([$sun->sub_point($t)], [Time::Keeper::Sun->sub_point($t)], 'the place does not enter into it');

    for my $p (['Europe/London'], ['Asia/Tokyo'], ['America/Denver'], ['Australia/Sydney'], ['Pacific/Auckland']) {
        my $s = Time::Keeper::Sun->new(place => $p->[0]);
        my $noon = $s->next_solar_noon($t);
        my (undef, $lon) = Time::Keeper::Sun->sub_point($noon);
        near(angle_diff($lon, $s->longitude), 0, 0.01, "$p->[0]: at solar noon the sun is over the place's meridian");
    }

    for my $month (qw(march september)) {
        my (undef, $lon) = Time::Keeper::Sun->sub_point(my $e = Time::Keeper::Sun->equinox(year => 2026, month => $month));
        my ($lat) = Time::Keeper::Sun->sub_point($e);
        near($lat, 0, 0.005, "the $month equinox: over the equator (chapter 25 holds the longitude to 0.01, chapter 27 times the equinox)");
    }
    # The declination at a solstice is the TRUE obliquity: the mean, 23.4362 in
    # 2026, and up to 9.2 arcseconds (0.0026 degree) of nutation.
    my ($n) = Time::Keeper::Sun->sub_point(Time::Keeper::Sun->solstice(year => 2026, month => 'june'));
    my ($s) = Time::Keeper::Sun->sub_point(Time::Keeper::Sun->solstice(year => 2026, month => 'december'));
    near($n, 23.4362, 0.004, 'the June solstice: over the tropic of Cancer');
    near($s, -23.4362, 0.004, 'the December solstice: over the tropic of Capricorn');

    my (undef, $l0) = Time::Keeper::Sun->sub_point(utc(year => 2026, month => 10, day => 19));
    my (undef, $l1) = Time::Keeper::Sun->sub_point(utc(year => 2026, month => 10, day => 19, hour => 1));
    near(angle_diff($l0, $l1 + 15), 0, 0.01, 'it moves west 15 degrees an hour');
}

# ---- the moon -----------------------------------------------------------------

{
    my $t = utc(year => 2026, month => 10, day => 19, hour => 9, minute => 30);
    my ($lat) = Time::Keeper::Moon->sub_point($t);
    is($lat, Time::Keeper::Moon->position($t)->{declination}, 'the moon\'s sub-latitude is its geocentric declination');
    my $sun = Time::Keeper::Sun->new(place => 'Europe/London');
    my $tr = $sun->track(from => $t, to => $t->epoch + 86400 * 28, step => 3600);
    my $mt = Time::Keeper::Moon->track(from => $t, to => $t->epoch + 86400 * 28, step => 3600);
    my ($max, $min) = (-90, 90);
    for (@{ $mt->{sub_latitude} }) { $max = $_ if $_ > $max; $min = $_ if $_ < $min }
    cmp_ok($max, '>', 18, "over a month the moon goes north of 18 degrees ($max)");
    cmp_ok($min, '<', -18, "and south of -18 ($min)");
}

# ---- the arguments ------------------------------------------------------------

{
    for my $class (qw(Time::Keeper::Sun Time::Keeper::Moon)) {
        ok(!eval { $class->sub_point('noon'); 1 }, "$class->sub_point: a word dies");
        like($@, qr/sub_point: 'noon' is neither a Time::Keeper value nor an epoch/, '  with its message');
        ok(!eval { $class->sub_point(utc(year => 3001, month => 1, day => 1)); 1 }, '  and a year out of range');
        like($@, qr/sub_point: the year 3001 is outside/, '  with its message');
    }
    my $t = utc(year => 2026, month => 10, day => 19)->epoch;
    is_deeply([Time::Keeper::Sun->sub_point(substr("x$t", 1))], [Time::Keeper::Sun->sub_point($t)], 'a substr instant is read');
}

done_testing;
