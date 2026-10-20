#!perl
use strict; use warnings;
BEGIN { require './bench/common.pl' }
use Time::Keeper; use Time::Keeper::Business;

# A schedule with rules materialises the years an iterator reaches, and its
# thousand-year cap holds; the iterator starts again every 50,000 steps
# (about two centuries) so the mark measures a step and not the cap.
my $b = Time::Keeper::Business->new(holidays => Time::Keeper::Business::Rule->uk, weekend => 'en-GB');
my $start = Time::Keeper::Date->new(year => 2026, month => 1, day => 1);
my ($it, $n) = ($b->iterate_business_days($start), 0);
mark_rate('iterate_business_days, a step', rate(sub { if (++$n > 50_000) { $n = 0; $it = $b->iterate_business_days($start) } $it->() }, 'iterate'), 3e6);
done();
