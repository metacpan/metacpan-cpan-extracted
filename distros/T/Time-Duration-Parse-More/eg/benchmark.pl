#!/usr/bin/env perl

use strict;
use warnings;
use Benchmark 'cmpthese';
use Time::Duration::Parse::More ();
use Time::Duration::Parse       ();

my $in_ml = '1 year 1 month 1 day 1 hour minus 25 minutes 20 seconds';
my $in_bl = '1 year 1 month 1 day 1 hour 25 minutes 20 seconds';

my $in_s = '4 hours';

print "\nBenchmark '$in_ml': long duration, very uncommon...\n\n";
cmpthese(
  -3,
  { 'cached (long)'   => sub { Time::Duration::Parse::More::parse_duration($in_ml) },
    'no cache (long)' => sub { Time::Duration::Parse::More::parse_duration_nc($in_ml) },
    'base (long)'     => sub { Time::Duration::Parse::parse_duration($in_bl) },
  }
);


print "\n\nBenchmark '$in_s': usual duration...\n\n";
cmpthese(
  -3,
  { 'cached (common)'   => sub { Time::Duration::Parse::More::parse_duration($in_s) },
    'no cache (common)' => sub { Time::Duration::Parse::More::parse_duration_nc($in_s) },
    'base (common)'     => sub { Time::Duration::Parse::parse_duration($in_s) },
  }
);
