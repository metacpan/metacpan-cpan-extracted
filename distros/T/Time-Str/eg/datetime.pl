#!/usr/bin/env perl
use strict;
use warnings;
use v5.10;

use Time::Str          qw[str2date];
use DateTime           qw[];
use DateTime::TimeZone qw[];
use Getopt::Long       qw[GetOptions];

sub usage {
    print STDERR <<EOF;
Usage: $0 <string> [options]

Parse a date/time string and print the corresponding DateTime.

Options:
  --format <FMT>        Time::Str format (default: DateTime)
  --tz-local <IANA>     IANA timezone for strings without zone info
                        (default: DateTime's floating timezone)
  --tz-map ABBR=IANA    Map a timezone abbreviation to an IANA name
                        (may be repeated)

Examples:
  $0 "24th December 2012 3PM"
  $0 "24th December 2012 3PM" --tz-local Europe/Stockholm
  $0 "24th December 2012 3PM CET" --tz-map CET=Europe/Stockholm
  $0 2024-12-24T15:30:45Z --format RFC3339
EOF
    exit 1;
}

my $format = 'DateTime';
my $tz_local;
my %tz_map;

GetOptions(
  'format=s'   => \$format,
  'tz-local=s' => \$tz_local,
  'tz-map=s'   => \%tz_map,
) or usage();

my $input = shift @ARGV or usage();
my %date  = str2date($input, format => $format);

my $dt = DateTime->new(
  year       => $date{year},
  month      => $date{month}      // 1,
  day        => $date{day}        // 1,
  hour       => $date{hour}       // 0,
  minute     => $date{minute}     // 0,
  second     => $date{second}     // 0,
  nanosecond => $date{nanosecond} // 0,
);

my $time_zone = do {
  if (exists $date{tz_offset}) {
    if ($date{tz_offset} == 0) {
      'UTC'
    }
    else {
      DateTime::TimeZone->offset_as_string($date{tz_offset} * 60);
    }
  }
  elsif (exists $date{tz_abbrev}) {
    my $iana = $tz_map{$date{tz_abbrev}}
      or die "Unknown timezone abbreviation '$date{tz_abbrev}',"
           . " use --tz-map $date{tz_abbrev}=<IANA name>\n";
    $iana;
  }
  else {
    $tz_local // 'floating';
  }
};

$dt->set_time_zone($time_zone);

# Note: DateTime silently drops fractional seconds.
# RFC 3339 requires UTC or a time zone offset, but
# DateTime omits that for local date/times.
say $dt->rfc3339;
