#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Time::Keeper;
use Time::Keeper::Sun;
use Time::Keeper::Moon;

# place => on the moon's methods (T1): a Time::Keeper::Sun place gives the
# zone and locale, which zone => and locale => override in either order;
# position with a place adds the topocentric altitude and azimuth.

sub utc { Time::Keeper->new(@_, zone => 'UTC') }
sub near { my ($got, $want, $tol, $name) = @_; cmp_ok(abs($got - $want), '<=', $tol, "$name: $got within $tol of $want") }

my $tokyo = Time::Keeper::Sun->new(place => 'Asia/Tokyo', locale => 'ja');
my $date = Time::Keeper::Date->new(year => 2026, month => 10, day => 11);
my $t = utc(year => 2026, month => 10, day => 26, hour => 4);

# ---- on ------------------------------------------------------------------

{
    my $d = Time::Keeper::Moon->on($date, place => $tokyo);
    is($d->zone_name, 'Asia/Tokyo', 'on: the zone follows the place');
    is($d->start->locale, 'ja', 'and the locale');
    is($d->phase_name, 'new', 'the new moon of 10 October 15:50 UT is the 11th in Tokyo');
    isa_ok($d->place, 'Time::Keeper::Sun');
    is($d->place->latitude, $tokyo->latitude, 'the day keeps the place');
    is(Time::Keeper::Moon->on($date, place => $tokyo, zone => 'UTC')->zone_name, 'UTC', 'zone => after place overrides it');
    is(Time::Keeper::Moon->on($date, zone => 'UTC', place => $tokyo)->zone_name, 'UTC', 'and before it');
    is(Time::Keeper::Moon->on($date, place => $tokyo, locale => 'fr')->start->locale, 'fr', 'locale => too');
    ok(!defined Time::Keeper::Moon->on($date)->place, 'without a place, place is undef');
    is(Time::Keeper::Moon->on($date)->zone_name, 'UTC', 'and the zone UTC');
}

# ---- position --------------------------------------------------------------

{
    my $london = Time::Keeper::Sun->new(place => 'Europe/London');
    my $geo = Time::Keeper::Moon->position($t);
    my $top = Time::Keeper::Moon->position($t, place => $london);
    is(join(' ', sort keys %$top), 'altitude apparent_altitude azimuth bright_limb constellation declination distance hour_angle latitude longitude parallactic_angle parallax right_ascension',
       'with a place, thirteen keys');
    is($top->{$_}, $geo->{$_}, "$_ is the geocentric one") for qw(longitude latitude right_ascension declination distance parallax);
    my (undef, $alt_geo, undef, undef, $alt, $app, $az) = Time::Keeper::Sun::_moon_view($london, $t);
    is($top->{altitude}, $alt, 'the altitude is the topocentric one');
    is($top->{apparent_altitude}, $app, 'with refraction in apparent_altitude');
    is($top->{azimuth}, $az, 'the azimuth');
    ok($top->{altitude} < $alt_geo, 'below the geocentric altitude by the parallax');
    near($top->{altitude}, 28.09 - 0.879, 0.02, 'London 2026-10-26 04:00 UT: USNO\'s geocentric 28.09 less its parallax in altitude 0.879');
    ok($top->{hour_angle} > -180 && $top->{hour_angle} <= 180, 'the hour angle between -180 and 180');
}

# ---- next, previous, phases ---------------------------------------------------------

{
    my $n = Time::Keeper::Moon->next(phase => 'full', after => $t->minus(days => 1), place => $tokyo);
    is($n->zone_name, 'Asia/Tokyo', 'next: the zone follows the place');
    is($n->locale, 'ja', 'and the locale');
    is($n->epoch, Time::Keeper::Moon->next(phase => 'full', after => $t->minus(days => 1))->epoch, 'the same instant as without');
    is(Time::Keeper::Moon->previous(phase => 'new', before => $t, place => $tokyo, zone => 'UTC')->zone_name, 'UTC', 'previous with zone => over the place');
    my @p = Time::Keeper::Moon->phases(from => utc(year => 2026, month => 10, day => 1), to => utc(year => 2026, month => 10, day => 31), place => $tokyo);
    is($p[0][1]->zone_name, 'Asia/Tokyo', 'phases: the zone follows the place');
}

# ---- deaths and magic --------------------------------------------------------------

for my $bad (
    [sub { Time::Keeper::Moon->on($date, place => {}) }, qr/^Time::Keeper::Moon->on: not a Time::Keeper::Sun place/],
    [sub { Time::Keeper::Moon->on($date, place => $date) }, qr/not a Time::Keeper::Sun place/],
    [sub { Time::Keeper::Moon->on($date, place => undef) }, qr/not a Time::Keeper::Sun place/],
    [sub { Time::Keeper::Moon->position($t, place => 'Europe/London') }, qr/^Time::Keeper::Moon->position: not a Time::Keeper::Sun place/],
    [sub { Time::Keeper::Moon->position($t, zone => 'UTC') }, qr/^Time::Keeper::Moon->position: unknown argument 'zone'/],
    [sub { Time::Keeper::Moon->position($t, 'place') }, qr/takes an instant and then name and value pairs/],
    [sub { Time::Keeper::Moon->next(phase => 'full', place => Time::Keeper->now) }, qr/^Time::Keeper::Moon->next: not a Time::Keeper::Sun place/],
    [sub { Time::Keeper::Moon->phases(from => $t, to => $t, place => []) }, qr/^Time::Keeper::Moon->phases: not a Time::Keeper::Sun place/],
) {
    my ($code, $re) = @$bad;
    ok(!eval { $code->(); 1 }, 'a bad place dies');
    like($@, $re, 'by name');
}
{
    package Tied;
    sub TIESCALAR { my ($c, $v) = @_; bless \$v, $c }
    sub FETCH { ${ $_[0] } }
}
{
    tie my $place, 'Tied', $tokyo;
    is(Time::Keeper::Moon->on($date, place => $place)->zone_name, 'Asia/Tokyo', 'a tied place is read through its magic');
    is(Time::Keeper::Moon->position($t, place => $place)->{altitude}, Time::Keeper::Moon->position($t, place => $tokyo)->{altitude}, 'by position too');
}

done_testing;
