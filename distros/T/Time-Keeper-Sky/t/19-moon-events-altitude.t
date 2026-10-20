#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Time::Keeper;
use Time::Keeper::Sun;
use Time::Keeper::Moon;

# The event engine follows the moon by a lean altitude of its own (the
# nutation from the moon's place, the parallax constants once); position
# computes it in full. At every moonrise and moonset the two must agree: the
# upper limb from position, the centre plus 0.2725 of the parallax, is at the
# horizon's depth to within the moon's motion in the half second a time is
# rounded to: the moon rises at up to 0.0042 degrees a second at the equator,
# so 0.0021 at most.

my @places = (
    [51.5074, -0.1278, 'Europe/London'], [-33.8688, 151.2093, 'Australia/Sydney'],
    [35.6762, 139.6503, 'Asia/Tokyo'],   [-0.1807, -78.4678, 'America/Guayaquil'],
    [64.1466, -21.9426, 'Atlantic/Reykjavik'], [39.7392, -104.9903, 'America/Denver'],
);
my ($n, $worst) = (0, 0);
for my $p (@places) {
    my $sun = Time::Keeper::Sun->new(latitude => $p->[0], longitude => $p->[1], zone => $p->[2]);
    for my $d (1 .. 28) {
        my $day = Time::Keeper::Moon->on(Time::Keeper->new(year => 2026, month => 10, day => $d, hour => 12, zone => $p->[2]), place => $sun);
        for my $t ($day->moonrises, $day->moonsets) {
            my $q = Time::Keeper::Moon->position($t, place => $sun);
            my $limb = $q->{altitude} + 0.2725 * $q->{parallax};
            my $d = abs($limb - (-34 / 60));
            $worst = $d if $d > $worst;
            $n++;
        }
    }
}
cmp_ok($n, '>', 300, "moonrises and moonsets checked ($n)");
cmp_ok($worst, '<=', 0.0022, "at each, the upper limb from position is at 34 arcminutes down (worst $worst degrees)");

done_testing;
