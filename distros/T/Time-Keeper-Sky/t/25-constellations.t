#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Time::Keeper;
use Time::Keeper::Sky;
use Time::Keeper::Star;
use Time::Keeper::Moon;
use Time::Keeper::Planet;

# The constellations: Roman's own test positions (CDS VI/42 test.in and
# out.dat, equinox 1950), every Bright Star Catalogue star with a Bayer or
# Flamsteed designation in the constellation it is named for, the names and
# genitives, and the constellation in the moon's and the planets' places.

# ---- Roman's test ----------------------------------------------------------------------

{
    # B1950.0 = 1950 January 0.923
    my $b1950 = Time::Keeper->new(year => 1949, month => 12, day => 31, hour => 22, minute => 9, zone => 'UTC');
    for (['9.0000', '+65.0000', 'UMa'], ['23.5000', '-20.0000', 'Aqr'], ['5.1200', '+09.1200', 'Ori'], ['9.4555', '-19.9000', 'Hya'],
         ['12.8888', '+22.0000', 'Com'], ['15.6687', '-12.1234', 'Lib'], ['19.0000', '-40.0000', 'CrA'], ['6.2222', '-81.1234', 'Men']) {
        my ($h, $d, $c) = @$_;
        is(Time::Keeper::Sky->constellation_of($h * 15, $d, $b1950), $c, "Roman's test: $h h $d in $c");
    }
}

# ---- the catalogue -------------------------------------------------------------------------

{
    my ($n, @wrong) = (0);
    for my $hr (Time::Keeper::Star->brighter_than(99)) {
        my $f = Time::Keeper::Star->find(hr => $hr);
        next unless $f->{constellation};
        my $c = Time::Keeper::Sky->constellation_of($f->{right_ascension}, $f->{declination});
        push @wrong, "HR $hr in $c" unless lc $c eq lc $f->{constellation};
        $n++;
    }
    is($n, 3143, 'the 3,143 stars with a Bayer or Flamsteed designation');
    is_deeply(\@wrong, [], '  every one in the constellation it is named for (J2000 positions, precessed to 1875)');
    is(Time::Keeper::Sky->constellation_of(Time::Keeper::Star->find(hr => 3579)->{right_ascension}, Time::Keeper::Star->find(hr => 3579)->{declination}), 'Lyn',
       'HR 3579, once 10 UMa, is in Lynx (the catalogue dropped the name)');
    is(Time::Keeper::Sky->constellation_of(0, 90), 'UMi', 'the north pole of J2000 is in Ursa Minor');
    is(Time::Keeper::Sky->constellation_of(0, -90), 'Oct', 'the south pole in Octans');
    is(Time::Keeper::Sky->constellation_of(359.9999, 0), Time::Keeper::Sky->constellation_of(-0.0001, 0), 'right ascension wraps');
}

# ---- positions of date, far from J2000 ------------------------------------------------------

{
    # In AD 2800 precession has moved every place by about 11 degrees: the
    # stars' apparent places of that date, taken back through the date's frame,
    # must still be in the constellations they are named for. Within the
    # minute of arc aberration and nutation put on an apparent place, a star on
    # a boundary may not be: those are counted, and must be few.
    my $t = Time::Keeper->new(year => 2800, month => 6, day => 1, zone => 'UTC');
    my ($n, $right, $moved) = (0, 0, 0);
    for my $hr (Time::Keeper::Star->brighter_than(99)) {
        my $f = Time::Keeper::Star->find(hr => $hr);
        next unless $f->{constellation};
        my $p = Time::Keeper::Star->position($hr, $t);
        $right++ if lc Time::Keeper::Sky->constellation_of($p->{right_ascension}, $p->{declination}, $t) eq lc $f->{constellation};
        $moved++ if lc(Time::Keeper::Sky->constellation_of($p->{right_ascension}, $p->{declination}) // '') ne lc $f->{constellation};
        $n++;
    }
    cmp_ok($right, '>=', $n - 10, "AD 2800: $right of $n stars, at their places of date, in their constellations by the date's frame");
    cmp_ok($moved, '>', 100, "  ($moved of them would not be, read as J2000: the frame matters)");
    for my $p (Time::Keeper::Planet->planets) {
        next if $p eq 'pluto';
        my $q = Time::Keeper::Planet->position($p, $t);
        is($q->{constellation}, Time::Keeper::Sky->constellation_of($q->{right_ascension}, $q->{declination}, $t), "AD 2800: ${p}'s constellation is its place of date's ($q->{constellation})");
    }
    my $m = Time::Keeper::Moon->position($t);
    is($m->{constellation}, Time::Keeper::Sky->constellation_of($m->{right_ascension}, $m->{declination}, $t), "  and the moon's ($m->{constellation})");
}

# ---- the names --------------------------------------------------------------------------------

{
    my @all = Time::Keeper::Sky->constellations;
    is(scalar @all, 88, 'the 88 constellations');
    my %seen;
    $seen{$_}++ for @all;
    is(scalar keys %seen, 88, '  each once');
    is_deeply(Time::Keeper::Sky->constellation('Ori'), { abbreviation => 'Ori', name => 'Orion', genitive => 'Orionis' }, 'Orion');
    is(Time::Keeper::Sky->constellation('ursa major')->{genitive}, 'Ursae Majoris', 'by name, case not minded');
    is(Time::Keeper::Sky->constellation('CVN')->{name}, 'Canes Venatici', 'by abbreviation, case not minded');
    is(Time::Keeper::Sky->constellation('CrA')->{name}, 'Corona Australis', 'Corona Australis, as the IAU has it now');
    is(Time::Keeper::Sky->constellation('Cam')->{name}, 'Camelopardalis', 'Camelopardalis');
    ok(!defined Time::Keeper::Sky->constellation('Argo'), 'Argo is no longer one');
    for my $a (@all) {
        my $c = Time::Keeper::Sky->constellation($a);
        $seen{$a} = 0 unless $c && $c->{abbreviation} eq $a && length $c->{genitive} && Time::Keeper::Sky->constellation($c->{name})->{abbreviation} eq $a;
    }
    is(scalar(grep { $seen{$_} } @all), 88, 'every abbreviation and name finds its constellation, with a genitive');
    ok(!eval { Time::Keeper::Sky->constellation(undef); 1 }, 'constellation needs a name');
    ok(!eval { Time::Keeper::Sky->constellation_of(0, 91); 1 }, 'a declination beyond the pole dies');
    like($@, qr/declination must be from -90 to 90/, '  saying so');
}

# ---- the moon's and the planets' --------------------------------------------------------------

{
    my $t = Time::Keeper->new(year => 2026, month => 10, day => 19, zone => 'UTC');
    my $m = Time::Keeper::Moon->position($t);
    is($m->{constellation}, Time::Keeper::Sky->constellation_of($m->{right_ascension}, $m->{declination}, $t), "the moon's place names its constellation ($m->{constellation})");
    for my $p (Time::Keeper::Planet->planets) {
        my $q = Time::Keeper::Planet->position($p, $t);
        is($q->{constellation}, Time::Keeper::Sky->constellation_of($q->{right_ascension}, $q->{declination}, $t), "$p ($q->{constellation})");
    }
    # the moon passes through the zodiac (and Ophiuchus, Cetus, Orion and
    # Sextans at its extremes) every month
    my %seen;
    for my $h (0 .. 27 * 24) {
        $seen{ Time::Keeper::Moon->position($t->epoch + $h * 3600)->{constellation} }++;
    }
    ok($seen{$_}, "in a month the moon passes through $_") for qw(Ari Tau Gem Cnc Leo Vir Lib Sco Sgr Cap Aqr Psc);
}

done_testing;
