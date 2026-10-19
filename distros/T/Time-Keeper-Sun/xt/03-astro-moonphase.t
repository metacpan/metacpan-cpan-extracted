#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Time::Keeper;
use Time::Keeper::Moon;

# Author test: Astro::MoonPhase (a port of Moontool) as a second opinion,
# when it is installed: its phasehunt gives the five principal phases
# around an instant, its phase the illuminated fraction. The marks are five
# minutes and 0.02: Moontool's phases are a few minutes out (160 s was seen
# against this dist, which USNO puts within a minute).

eval { require Astro::MoonPhase; 1 } or plan skip_all => 'Astro::MoonPhase is not installed';

my ($n, $worst, $worst_k) = (0, 0, 0);
for my $epoch (map { 1700000000 + $_ * 86400 * 23 } 0 .. 40) {
    my $t = Time::Keeper->from_epoch($epoch);
    my @hunt = Astro::MoonPhase::phasehunt($epoch);     # new, first, full, last, new around the instant
    my @ours = (
        Time::Keeper::Moon->previous(phase => 'new', before => $t->plus(days => 15)),
    );
    my $new = $ours[0];
    my @mine = ($new,
        Time::Keeper::Moon->next(phase => 'first_quarter', after => $new),
        Time::Keeper::Moon->next(phase => 'full', after => $new),
        Time::Keeper::Moon->next(phase => 'last_quarter', after => $new),
        Time::Keeper::Moon->next(phase => 'new', after => $new));
    for my $i (0 .. 4) {
        my $diff = abs($mine[$i]->epoch - $hunt[$i]);
        # phasehunt's lunation may be the one before or after ours: skip a pair a lunation apart
        next if $diff > 20 * 86400;
        $worst = $diff if $diff > $worst;
        cmp_ok($diff, '<=', 300, "$t: phase $i within five minutes of Astro::MoonPhase (" . sprintf('%.0f', $diff) . ' s)');
        $n++;
    }
    my ($frac_cycle, $illum) = Astro::MoonPhase::phase($epoch);
    my $dk = abs(Time::Keeper::Moon->illumination($t) - $illum);
    $worst_k = $dk if $dk > $worst_k;
    cmp_ok($dk, '<=', 0.02, "$t: illumination within 0.02 of Astro::MoonPhase");
}
diag("$n phases compared, worst $worst s; worst illumination difference $worst_k");
done_testing;
