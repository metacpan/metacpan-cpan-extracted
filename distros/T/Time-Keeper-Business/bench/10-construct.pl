#!perl
use strict; use warnings;
BEGIN { require './bench/common.pl' }
use Time::Keeper; use Time::Keeper::Business;
my @h = map { sprintf '2026-%02d-%02d', 1 + $_ % 12, 1 + $_ % 28 } 0 .. 99;
my @d = map { Time::Keeper::Date->parse($_) } @h;
Time::Keeper::Business->new(holidays => \@h);
mark_rate('new with 100 literal holidays', rate(sub { Time::Keeper::Business->new(holidays => \@h) }, '100 strings'), 5e4);
printf "info new with 100 Dates: %s; new with none: %s; with a locale weekend: %s\n",
    fmt_rate(rate(sub { Time::Keeper::Business->new(holidays => \@d) }, '100 Dates')),
    fmt_rate(rate(sub { Time::Keeper::Business->new }, 'none')),
    fmt_rate(rate(sub { Time::Keeper::Business->new(weekend => 'ar-EG') }, 'ar-EG'));
done();
