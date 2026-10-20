#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Time::Keeper;
use Time::Keeper::Sky;
use Time::Keeper::Star;

# The stars: the compiled catalogue, finding a star every way a person names
# one, the apparent places against Skyfield's from the same catalogue
# numbers (t/skyfield-stars.tsv, 30 stars at four dates, the fastest movers
# among them), the arrays for a star map, the track, and the refusals.

sub utc { Time::Keeper->new(@_, zone => 'UTC') }
my $R = atan2(1, 1) / 45;

# ---- the catalogue ------------------------------------------------------------------

{
    my @all = Time::Keeper::Star->brighter_than(99);
    is(scalar @all, 9096, 'the 9,096 stars of BSC5 with a position');
    is($all[0], 2491, 'brightest first: Sirius');
    my @m = map { Time::Keeper::Star->find(hr => $_)->{magnitude} } @all;
    ok(!grep({ $m[$_] < $m[$_ - 1] } 1 .. $#m), 'in order of magnitude');
    is(scalar(my @b = Time::Keeper::Star->brighter_than(1.0)), 15, 'fifteen stars brighter than 1.0');
    is(scalar(@b = Time::Keeper::Star->brighter_than(-2)), 0, 'none brighter than -2');
    my $s = Time::Keeper::Star->find('Sirius');
    is_deeply([@$s{qw(hr name bayer flamsteed constellation magnitude colour)}], [2491, 'Sirius', 'Alp CMa', '9 CMa', 'CMa', -1.46, 0], 'Sirius as the catalogue has it');
    is($s->{parallax}, 0.375, '  its parallax');
    is($s->{proper_motion_ra}, -0.553, '  its proper motion');
    is_deeply([sort keys %$s], [qw(bayer colour constellation declination flamsteed hr magnitude name parallax proper_motion_dec proper_motion_ra radial_velocity right_ascension)], 'what find gives');
    my $named = 0;
    for my $hr (@all) {
        my $f = Time::Keeper::Star->find(hr => $hr);
        next unless defined $f->{name};
        $named++;
        is(Time::Keeper::Star->find($f->{name})->{hr}, $hr, "$f->{name} finds HR $hr") if $named <= 5;
        $named = -1e9 unless Time::Keeper::Star->find($f->{name})->{hr} == $hr;
    }
    is($named, 332, 'every one of the 332 IAU names finds its star');
    ok(!defined Time::Keeper::Star->find(hr => 1)->{name}, 'a star without an IAU name has none');
    ok(!(grep { defined Time::Keeper::Star->find(hr => $_) } 92, 95, 182, 1057, 1841, 2472, 2496, 3515, 3671, 6309, 6515, 7189, 7539, 8296),
       'the 14 entries without a position (novae and other objects) are not stars here');
}

# ---- finding ----------------------------------------------------------------------------

{
    for my $c (['Betelgeuse', 2061], ['betelgeuse', 2061], ['BETELGEUSE', 2061], ['HR 2061', 2061], ['hr2061', 2061],
               ['alpha Ori', 2061], ['Alp Ori', 2061], ['alf Ori', 2061], ['ALPHA ORI', 2061], ['58 Ori', 2061],
               ['alpha1 Cen', 5459], ['Alp1 Cen', 5459], ['Rigil Kentaurus', 5459], ['alpha2 Cen', 5460],
               ['Polaris', 424], ['1 UMi', 424], ['beta Per', 936], ['Algol', 936], ['zeta UMa', 5054], ['Mizar', 5054],
               [7001, 7001], ['7001', 7001]) {
        my ($name, $hr) = @$c;
        my $f = Time::Keeper::Star->find($name);
        is($f && $f->{hr}, $hr, "'$name' is HR $hr");
    }
    ok(!defined Time::Keeper::Star->find($_), "'$_' is no star") for ('Vulcan', 'alpha Xyz', '999 Ori', 'HR 99999', 'HR', 'omega', '0');
    is(Time::Keeper::Star->find(name => 'Vega')->{hr}, 7001, 'name => works');
    is(Time::Keeper::Star->find(hr => 7001)->{name}, 'Vega', 'hr => works');
    ok(!eval { Time::Keeper::Star->find(colour => 'red'); 1 }, 'an unknown argument dies');
    like($@, qr/find: unknown argument 'colour'/, '  by name');
    ok(!eval { Time::Keeper::Star->find; 1 }, 'nothing to find dies');
}

# ---- the apparent place against Skyfield --------------------------------------------------

{
    my $file = -e 't/skyfield-stars.tsv' ? 't/skyfield-stars.tsv' : 'skyfield-stars.tsv';
    open my $fh, '<', $file or die "$file: $!";
    my ($n, $worst, $where) = (0, 0, '');
    while (<$fh>) {
        next if /^#/;
        chomp;
        my ($hr, $epoch, $ra, $dec) = split /\t/;
        my $p = Time::Keeper::Star->position($hr, $epoch);
        my $dra = $p->{right_ascension} - $ra;
        $dra -= 360 if $dra > 180;
        $dra += 360 if $dra < -180;
        my $sep = sqrt(($dra * cos($dec * $R)) ** 2 + ($p->{declination} - $dec) ** 2) * 3600;
        ($worst, $where) = ($sep, "HR $hr at $epoch") if $sep > $worst;
        $n++;
    }
    is($n, 120, '30 stars at four dates');
    # IAU 1976 precession and the short nutation against IAU 2006 and 2000A
    cmp_ok($worst, '<=', 0.4, "within 0.4 arcsecond of Skyfield's IAU 2006/2000A place (worst $worst, $where)");
}

# ---- what a position holds; positions; the track ------------------------------------------

{
    my $t = utc(year => 2026, month => 10, day => 19, hour => 22);
    my $sky = Time::Keeper::Sky->new(place => 'Europe/London');
    my $p = Time::Keeper::Star->position('Vega', $t);
    is_deeply([sort keys %$p], [qw(declination hr magnitude right_ascension)], 'a geocentric position\'s keys');
    my $q = Time::Keeper::Star->position('Vega', $t, place => $sky);
    is_deeply([sort keys %$q], [qw(altitude apparent_altitude azimuth declination hour_angle hr magnitude right_ascension)], 'with a place');
    my (undef, $theta) = Time::Keeper::Sun::_sidereal($t);
    my $h = ($theta + $sky->longitude - $q->{right_ascension}) * $R;
    my $alt = atan2(sin($sky->latitude * $R) * sin($q->{declination} * $R) + cos($sky->latitude * $R) * cos($q->{declination} * $R) * cos($h), 1);
    my $sa = sin($sky->latitude * $R) * sin($q->{declination} * $R) + cos($sky->latitude * $R) * cos($q->{declination} * $R) * cos($h);
    cmp_ok(abs($q->{altitude} - atan2($sa, sqrt(1 - $sa * $sa)) / $R), '<=', 1e-9, 'the altitude is the apparent place\'s from the place');
    my $polaris = Time::Keeper::Star->position('Polaris', $t, place => $sky);
    cmp_ok(abs($polaris->{altitude} - $sky->latitude), '<', 1, "Polaris stands at about the latitude ($polaris->{altitude})");
    my $acrux = Time::Keeper::Star->position('Acrux', $t, place => $sky);
    cmp_ok($acrux->{altitude}, '<', 0, 'Acrux never rises in London');

    my $all = Time::Keeper::Star->positions($t, magnitude => 4.5, place => $sky);
    my @hr = Time::Keeper::Star->brighter_than(4.5);
    is_deeply($all->{hr}, \@hr, 'positions to 4.5 are the stars brighter_than gives');
    is_deeply([sort keys %$all], [qw(altitude azimuth declination hr magnitude right_ascension)], '  as arrays');
    my $worst = 0;
    for my $i (0, 1, 100, $#hr) {
        my $one = Time::Keeper::Star->position($hr[$i], $t, place => $sky);
        for (qw(right_ascension declination altitude azimuth)) {
            my $d = abs($all->{$_}[$i] - $one->{$_});
            $worst = $d if $d > $worst;
        }
    }
    cmp_ok($worst, '<=', 1e-12, 'each one is position\'s, to the bit');
    ok(!exists Time::Keeper::Star->positions($t)->{altitude}, 'no place, no altitude');
    is(scalar @{ Time::Keeper::Star->positions($t)->{hr} }, scalar(@hr), 'magnitude 4.5 unless given');
    is(scalar @{ Time::Keeper::Star->positions($t, magnitude => -5)->{hr} }, 0, 'none brighter than -5');

    my $tr = Time::Keeper::Star->track('Sirius', from => $t, to => $t->epoch + 86400, step => 3600, place => $sky);
    is(scalar @{ $tr->{epoch} }, 25, 'a track, hourly');
    my $w = 0;
    for my $k (0, 12, 24) {
        my $p1 = Time::Keeper::Star->position('Sirius', $tr->{epoch}[$k], place => $sky);
        my ($lat) = Time::Keeper::Star->sub_point('Sirius', $tr->{epoch}[$k]);
        $w = abs($tr->{altitude}[$k] - $p1->{altitude}) if abs($tr->{altitude}[$k] - $p1->{altitude}) > $w;
        $w = abs($tr->{sub_latitude}[$k] - $lat) if abs($tr->{sub_latitude}[$k] - $lat) > $w;
    }
    cmp_ok($w, '<=', 1e-12, '  each sample is position\'s and sub_point\'s');
    # a star returns to the same place a sidereal day later
    my $d1 = Time::Keeper::Star->position('Vega', $t, place => $sky)->{azimuth};
    my $d2 = Time::Keeper::Star->position('Vega', $t->epoch + 86164.0905, place => $sky)->{azimuth};
    cmp_ok(abs($d1 - $d2), '<', 0.01, 'a sidereal day later a star is back where it was');
}

# ---- refusals -----------------------------------------------------------------------------

{
    my $t = utc(year => 2026, month => 10, day => 19);
    ok(!eval { Time::Keeper::Star->position('Vulcan', $t); 1 }, 'an unknown star dies');
    like($@, qr/position: no star is known as 'Vulcan' in the Bright Star Catalogue/, '  naming it');
    ok(!eval { Time::Keeper::Star->position(undef, $t); 1 }, 'no star dies');
    like($@, qr/needs a star/, '  saying so');
    ok(!eval { Time::Keeper::Star->position('Vega', $t, colour => 1); 1 }, 'an unknown argument dies');
    ok(!eval { Time::Keeper::Star->positions($t, magnitude => 'bright'); 1 }, 'a magnitude that is no number dies');
    like($@, qr/magnitude must be a number/, '  saying so');
    ok(!eval { Time::Keeper::Star->position('Vega', utc(year => 3001, month => 1, day => 1)); 1 }, 'the range holds');
    {
        package Tied;
        sub TIESCALAR { my ($c, $v) = @_; bless \$v, $c }
        sub FETCH { ${ $_[0] } }
    }
    tie my $name, 'Tied', 'Deneb';
    is(Time::Keeper::Star->position($name, $t)->{hr}, 7924, 'a tied name is read');
    is(Time::Keeper::Star->position(substr('xDeneb', 1), $t)->{hr}, 7924, 'and a substr');
}

done_testing;
