#!perl
use strict; use warnings;
BEGIN { require './bench/common.pl' }
use Time::Keeper; use Time::Keeper::Sun; use Time::Keeper::Moon;

# A day's tracks as lnation.org's page takes them: 26 hours at 2 minutes,
# 781 samples each of the sun and of the moon from a place, against the same
# samples through position, one call each.
my $sun = Time::Keeper::Sun->new(place => 'Europe/London');
my $from = Time::Keeper->new(year => 2026, month => 10, day => 19, zone => 'Europe/London')->epoch - 3600;
my $to = $from + 26 * 3600;
my $tracks = rate(sub {
    $sun->track(from => $from, to => $to, step => 120);
    Time::Keeper::Moon->track(from => $from, to => $to, step => 120, place => $sun);
}, 'track, sun and moon');
my $loop = rate(sub {
    for (my $e = $from; $e <= $to; $e += 120) {
        $sun->position($e);
        Time::Keeper::Moon->position($e, place => $sun);
    }
}, 'position, 781 times each');
printf "info a day's sun and moon tracks %s (%.2f ms); through position %s (%.2f ms)\n",
    fmt_rate($tracks), 1000 / $tracks, fmt_rate($loop), 1000 / $loop;
mark_less('a day\'s sun and moon tracks', sprintf('%.2f', 1000 / $tracks), 3, 1, 'the mark', 'ms');
mark('track against position in a loop', $tracks, $loop, 1, 'position');
done();
