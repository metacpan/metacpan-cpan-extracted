#!/usr/bin/env perl
use strict;
use warnings;
use v5.10;

use Time::Str          qw[str2date];
use Time::Moment       qw[];
use DateTime::TimeZone qw[];
use Getopt::Long       qw[GetOptions];

sub usage {
    print STDERR <<EOF;
Usage: $0 <string> [options]

Parse a date/time string and print the corresponding Time::Moment.

Options:
  --format <FMT>        Time::Str format (default: DateTime)
  --tz-local <IANA>     IANA timezone for strings without zone info
                        (default: local system timezone)
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

my $tm = Time::Moment->new(
  year       => $date{year},
  month      => $date{month}      // 1,
  day        => $date{day}        // 1,
  hour       => $date{hour}       // 0,
  minute     => $date{minute}     // 0,
  second     => $date{second}     // 0,
  nanosecond => $date{nanosecond} // 0,
);

if (exists $date{tz_offset}) {
  $tm = $tm->with_offset_same_local($date{tz_offset});
}
elsif (exists $date{tz_abbrev}) {
  my $iana = $tz_map{$date{tz_abbrev}}
    or die "Unknown timezone abbreviation '$date{tz_abbrev}',"
         . " use --tz-map $date{tz_abbrev}=<IANA name>\n";
  $tm = with_local_tz($tm, $iana);
}
else {
  $tm = with_local_tz($tm, $tz_local // 'local');
}

say $tm->to_string;

sub with_local_tz {
  my ($tm, $name) = @_;
  my $tz     = DateTime::TimeZone->new(name => $name);
  my $offset = $tz->offset_for_local_datetime($tm) / 60;
  return $tm->with_offset_same_local($offset);
}
