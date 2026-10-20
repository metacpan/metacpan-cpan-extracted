#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Time::Keeper;
use Time::Keeper::Sun;

# Crossings of any altitude, and golden and blue hour. The horizon's and the
# twilights' depths through crossings are sunrise, sunset, dawn and dusk to
# the second, on every day of t/usno-oneday.tsv; a crossing is at the
# altitude asked; the spans hold together at the poles.

sub near { my ($got, $want, $tol, $name) = @_; cmp_ok(abs($got - $want), '<=', $tol, "$name: $got within $tol of $want") }
sub ep { [map { $_->epoch } @_] }

my $file = -e 't/usno-oneday.tsv' ? 't/usno-oneday.tsv' : 'usno-oneday.tsv';
open my $fh, '<', $file or die "$file: $!";
my ($days, $same, $ordered, $at) = (0, 1, 1, 0);
my @bad;
while (<$fh>) {
    next if /^#/;
    chomp;
    my ($place, $date, $lat, $lon, $zone) = split /\t/;
    next unless defined $zone;
    my ($y, $m, $d) = split /-/, $date;
    my $sun = Time::Keeper::Sun->new(latitude => $lat, longitude => $lon, zone => $zone);
    my $day = $sun->on(year => $y, month => $m, day => $d);
    my %by = (-50 / 60 => [[$day->sunrises], [$day->sunsets]]);
    $by{-6}  = [[$day->dawns], [$day->dusks]];
    $by{-12} = [[$day->dawns(kind => 'nautical')], [$day->dusks(kind => 'nautical')]];
    $by{-18} = [[$day->dawns(kind => 'astronomical')], [$day->dusks(kind => 'astronomical')]];
    for my $alt (keys %by) {
        my @x = $day->crossings(altitude => $alt);
        my @r = map { $_->[0] } grep { $_->[1] eq 'rising' } @x;
        my @s = map { $_->[0] } grep { $_->[1] eq 'setting' } @x;
        # sunrises and the rest keep two of a kind; a day with three is not in the file
        unless ("@{ ep(@r) }" eq "@{ ep(@{ $by{$alt}[0] }) }" && "@{ ep(@s) }" eq "@{ ep(@{ $by{$alt}[1] }) }") {
            $same = 0;
            push @bad, "$place $date $alt";
        }
        for my $i (1 .. $#x) { $ordered = 0 if $x[$i][0]->epoch < $x[$i - 1][0]->epoch }
        for my $c (@x) {
            my $h = $sun->position($c->[0])->{altitude};
            my $dh = abs($h - $alt);
            $at = $dh if $dh > $at;
        }
    }
    $days++;
}
close $fh;
cmp_ok($days, '>=', 80, "USNO one-day rows read ($days)");
ok($same, 'crossings of the horizon and of 6, 12 and 18 below are sunrises, sunsets, dawns and dusks to the second') or diag("@bad");
ok($ordered, 'in order of time');
cmp_ok($at, '<=', 0.005, "the sun is at the altitude asked, to the second's motion (worst $at)");

# ---- what a day holds -------------------------------------------------------------

{
    my $london = Time::Keeper::Sun->new(place => 'Europe/London');
    my $dec = $london->on(year => 2026, month => 12, day => 21);
    is(scalar(my @x = $dec->crossings(altitude => 20)), 0, 'London at midwinter: never 20 degrees up');
    my @y = $dec->crossings(altitude => 10);
    is_deeply([map { $_->[1] } @y], [qw(rising setting)], '  but 10, once each way');
    like($y[0][0], qr/^2026-12-21T\d\d:\d\d:\d\d\+00:00$/, '  as values in the place\'s zone');
    my $t = Time::Keeper::Sun->new(latitude => 69.6496, longitude => 18.9560, zone => 'Europe/Oslo')->on(year => 2026, month => 6, day => 21);
    is(scalar(my @z = $t->crossings(altitude => 0)), 0, 'Tromso at midsummer: no crossing of the horizon');
    @z = $t->crossings(altitude => 10);
    is(scalar @z, 2, '  but two of 10 degrees');
}

# ---- golden and blue hour --------------------------------------------------------

sub spans { [map { [map { defined $_ ? $_->epoch : undef } @$_] } @_] }

{
    my $london = Time::Keeper::Sun->new(place => 'Europe/London');
    my $day = $london->on(year => 2026, month => 10, day => 19);
    my @g = $day->golden_hours;
    my @b = $day->blue_hours;
    is(scalar @g, 2, 'London, October: two golden hours');
    is(scalar @b, 2, 'and two blue');
    my ($m6, $e6) = map { $_->[0]->epoch } $day->crossings(altitude => 6);
    my ($m4, $e4) = map { $_->[0]->epoch } $day->crossings(altitude => -4);
    my ($mb, $eb) = map { $_->[0]->epoch } $day->crossings(altitude => -6);
    is_deeply(spans(@g), [[$m4, $m6], [$e6, $e4]], 'golden: rising from -4 to 6, then setting from 6 to -4');
    is_deeply(spans(@b), [[$mb, $m4], [$e4, $eb]], 'blue: -6 to -4 each way, meeting golden hour');
    like($g[0][0], qr/\+01:00$/, 'values in the place\'s zone');
}

{
    my $tromso = Time::Keeper::Sun->new(latitude => 69.6496, longitude => 18.9560, zone => 'Europe/Oslo');
    my $jun = $tromso->on(year => 2026, month => 6, day => 21);
    my @g = $jun->golden_hours;
    is(scalar @g, 2, 'Tromso at midsummer: golden hour twice');
    ok(!defined $g[0][0] && defined $g[0][1], '  the first began the evening before: no start');
    ok(defined $g[1][0] && !defined $g[1][1], '  the second runs on past midnight: no end');
    is(scalar(my @b = $jun->blue_hours), 0, '  and no blue hour: the sun is never 4 below');

    my $dec = $tromso->on(year => 2026, month => 12, day => 10);
    @g = $dec->golden_hours;
    is(scalar @g, 1, 'Tromso in the polar night: one golden span at midday');
    ok(defined $g[0][0] && defined $g[0][1], '  with both ends');
    my @x = $dec->crossings(altitude => -4);
    is_deeply(spans(@g), [[map { $_->[0]->epoch } @x]], '  between the crossings of -4');

    my $lyr = Time::Keeper::Sun->new(latitude => 78.2232, longitude => 15.6267, zone => 'Arctic/Longyearbyen')->on(year => 2026, month => 12, day => 21);
    is(scalar(my @n = $lyr->golden_hours), 0, 'Longyearbyen at midwinter: no golden hour');
    is(scalar(@n = $lyr->blue_hours), 0, '  nor blue: the sun stays below 6 degrees down');

    my $pole = Time::Keeper::Sun->new(latitude => 89.9, longitude => 0, zone => 'UTC')->on(year => 2026, month => 9, day => 25);
    is_deeply(spans($pole->golden_hours), [[undef, undef]], 'near the pole at the equinox: golden hour all day, no start or end');
}

# ---- the arguments ----------------------------------------------------------------

{
    my $day = Time::Keeper::Sun->new(place => 'Europe/London')->on(year => 2026, month => 10, day => 19);
    for ([[], qr/crossings takes altitude => degrees/, 'no argument'],
         [[altitude => 6, 1], qr/crossings takes altitude => degrees/, 'too many'],
         [[height => 6], qr/crossings: unknown argument 'height'/, 'another name'],
         [[altitude => 'high'], qr/crossings: altitude must be a number of degrees/, 'a word'],
         [[altitude => undef], qr/crossings: altitude must be a number of degrees/, 'undef'],
         [[altitude => 91], qr/crossings: altitude must be from -90 to 90 degrees/, 'above the zenith'],
         [[altitude => -90.5], qr/crossings: altitude must be from -90 to 90 degrees/, 'below the nadir'],
         [[altitude => 'nan'], qr/crossings: altitude must be/, 'not a number']) {
        my ($args, $re, $what) = @$_;
        ok(!eval { $day->crossings(@$args); 1 }, "crossings dies: $what");
        like($@, $re, '  with its message');
    }
    {
        package Tied;
        sub TIESCALAR { my ($c, $v) = @_; bless \$v, $c }
        sub FETCH { ${ $_[0] } }
    }
    tie my $alt, 'Tied', 6;
    tie my $key, 'Tied', 'altitude';
    is(scalar(my @x = $day->crossings($key => $alt)), 2, 'a tied name and altitude are read');
    is(scalar(@x = $day->crossings(altitude => substr('x6', 1))), 2, 'and a substr');
    ok(!eval { Time::Keeper::Sun::Day::golden_hours('London'); 1 }, 'golden_hours on something not a day dies');
    like($@, qr/golden_hours: not a Time::Keeper::Sun::Day/, '  naming the method');
    ok(!eval { Time::Keeper::Sun::Day::blue_hours([]); 1 }, 'and blue_hours');
    like($@, qr/blue_hours: not a Time::Keeper::Sun::Day/, '  naming it');
}

done_testing;
