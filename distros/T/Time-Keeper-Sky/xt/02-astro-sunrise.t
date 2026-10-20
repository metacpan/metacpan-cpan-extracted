#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Time::Keeper;
use Time::Keeper::Sun;

# Author test: Astro::Sunrise as a second opinion, when it is installed. It
# knows no Delta T and no nutation, and takes a UTC offset, so the mark is
# two minutes. Its sunrise() takes a date; its sun_rise() answers for today
# whatever is passed, and is not used.

eval { require Astro::Sunrise; 1 } or plan skip_all => 'Astro::Sunrise is not installed';
Astro::Sunrise->import(qw(sunrise));

my @places = ([51.5074, -0.1278, 'Europe/London'], [-33.8688, 151.2093, 'Australia/Sydney'], [-0.1807, -78.4678, 'America/Guayaquil'],
              [64.1466, -21.9426, 'Atlantic/Reykjavik'], [35.6762, 139.6503, 'Asia/Tokyo']);
my ($n, $worst) = (0, 0);
for my $p (@places) {
    my ($lat, $lon, $zone) = @$p;
    my $sun = Time::Keeper::Sun->new(latitude => $lat, longitude => $lon, zone => $zone);
    for my $month (1 .. 12) {
        my $day = $sun->on(year => 2026, month => $month, day => 15);
        my $tz = $day->start->offset / 3600;
        my ($their_rise, $their_set) = sunrise({ lon => $lon, lat => $lat, tz => $tz, year => 2026, month => $month, day => 15, precise => 1 });
        for my $which (qw(rise set)) {
            my $ours = $which eq 'rise' ? $day->sunrise : $day->sunset;
            next unless $ours;
            my $theirs = $which eq 'rise' ? $their_rise : $their_set;
            my ($h, $m) = split /:/, $theirs;
            my $diff = abs($ours->hour * 60 + $ours->minute + $ours->second / 60 - ($h * 60 + $m));
            $worst = $diff if $diff > $worst;
            cmp_ok($diff, '<=', 2, "$zone 2026-$month-15 sun$which within two minutes of Astro::Sunrise ($theirs)");
            $n++;
        }
    }
}
diag("$n events, worst $worst minutes");
done_testing;
