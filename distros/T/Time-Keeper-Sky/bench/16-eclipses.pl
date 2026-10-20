#!perl
use strict; use warnings;
BEGIN { require './bench/common.pl' }
use Time::Keeper; use Time::Keeper::Sky; use Time::Keeper::Eclipse;

# The next lunar and solar eclipse from an instant, one place's view of a
# solar eclipse, a central line, and a century of each. plan_time_keeper_sky/07
# and 08 set no speed mark: these are figures.
my $sky = Time::Keeper::Sky->new(place => 'Europe/London');
my $t = Time::Keeper->new(year => 2026, month => 1, day => 1, zone => 'UTC');
my $c0 = Time::Keeper->new(year => 2001, month => 1, day => 1, zone => 'UTC');
my $c1 = Time::Keeper->new(year => 2100, month => 12, day => 31, zone => 'UTC');
my $solar = Time::Keeper::Eclipse->next(kind => 'solar', after => $t);
my $lunar = rate(sub { Time::Keeper::Eclipse->next(kind => 'lunar', after => $t) }, 'next lunar');
my $sol = rate(sub { Time::Keeper::Eclipse->next(kind => 'solar', after => $t) }, 'next solar');
my $loc = rate(sub { $solar->local(place => $sky) }, 'local');
my $line = rate(sub { $solar->central_line }, 'central_line');
my $lc = rate(sub { my @x = Time::Keeper::Eclipse->between(kind => 'lunar', from => $c0, to => $c1) }, 'century lunar');
my $sc = rate(sub { my @x = Time::Keeper::Eclipse->between(kind => 'solar', from => $c0, to => $c1) }, 'century solar');
printf "info Eclipse->next lunar %s (%.2f ms), solar %s (%.2f ms)\n", fmt_rate($lunar), 1000 / $lunar, fmt_rate($sol), 1000 / $sol;
printf "info local %s (%.2f ms); central_line %s (%.1f ms)\n", fmt_rate($loc), 1000 / $loc, fmt_rate($line), 1000 / $line;
printf "info 2001-2100: lunar %.0f ms, solar %.0f ms\n", 1000 / $lc, 1000 / $sc;
done();
