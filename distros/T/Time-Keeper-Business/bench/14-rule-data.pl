#!perl
use strict; use warnings;
BEGIN { require './bench/common.pl' }
use Time::Keeper; use Time::Keeper::Business;
my $uk = Time::Keeper::Business::Rule->uk;
mark_rate('TO_JSON then from_spec of Rule->uk', rate(sub { Time::Keeper::Business::Rule->from_spec($uk->TO_JSON) }, 'round trip'), 2e4);
printf "info TO_JSON alone: %s\n", fmt_rate(rate(sub { $uk->TO_JSON }, 'TO_JSON'));
done();
