#!/usr/bin/env perl
use strict;
use warnings;
use v5.10;

use Time::HiRes  qw[time];
use Time::Str    qw[time2str str2time];
use Getopt::Long qw[GetOptions];

sub usage {
    print STDERR <<EOF;
Usage: $0 [options]

Round-trip a Time::HiRes timestamp through Time::Str.

Options:
  --format <FMT>    Time::Str format (default: RFC3339)
  --time <FLOAT>    Unix timestamp (default: Time::HiRes::time)
  --offset <MIN>    Timezone offset in minutes (default: 0)
  --precision <N>   Fractional digits 0-9 (default: auto)

Examples:
  $0
  $0 --precision 3
  $0 --time 0.123456789
  $0 --format ISO9075 --offset 60
EOF
    exit 1;
}

my $format    = 'RFC3339';
my $time      = time;
my $offset    = 0;
my $precision;

GetOptions(
  'format=s'    => \$format,
  'time=f'      => \$time,
  'offset=i'    => \$offset,
  'precision=i' => \$precision,
) or usage();

my @options = (
  format => $format,
  offset => $offset,
  (defined $precision ? (precision => $precision) : ())
);

my $str  = time2str($time, @options);
my $back = str2time($str, format => $format);

printf "time:     %f\n", $time;
printf "time2str: %s\n", $str;
printf "str2time: %f\n", $back;
