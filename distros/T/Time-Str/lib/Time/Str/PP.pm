package Time::Str::PP;
use strict;
use warnings;
use v5.10.1;

our @EXPORT_OK = qw[ time2str
                     str2date
                     str2time ];

our @CARP_NOT  = qw[ Time::Str::PP::Calendar
                     Time::Str::PP::Token ];

use Carp     qw[croak];
use Exporter qw[import];

{
  package
  Time::Str::PP::Calendar; # hide from PAUSE/indexers

  our @EXPORT_OK = qw[ month_days
                       leap_year
                       rdn_to_dow
                       rdn_to_ymd
                       resolve_century
                       valid_ymd
                       ymd_to_dow
                       ymd_to_rdn ];

   use Carp     qw[croak];
   use Exporter qw[import];

   use constant RDN_MIN =>       1; # 0001-01-01
   use constant RDN_MAX => 3652059; # 9999-12-31

   sub leap_year {
     @_ == 1 or croak q/Usage: leap_year(year)/;
     my ($y) = @_;
     return (($y & 3) == 0 && ($y % 100 != 0 || $y % 400 == 0));
   }

   sub month_days {
     @_ == 2 or croak q/Usage: month_days(year, month)/;
     my ($y, $m) = @_;

     ($m >= 1 && $m <= 12)
       or croak q/Parameter 'month' is out of range [1, 12]/;

     return 29 if $m == 2 && leap_year($y);
     return (0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)[$m];
   }

   sub valid_ymd {
     @_ == 3 or croak q/Usage: valid_ymd(year, month, day)/;
     my ($y, $m, $d) = @_;
     return ($y >= 1 && $y <= 9999)
         && ($m >= 1 && $m <= 12)
         && ($d >= 1 && ($d <= 28 || $d <= month_days($y, $m)));
   }

   sub ymd_to_rdn {
     @_ == 3 or croak q/Usage: ymd_to_rdn(year, month, day)/;
     my ($y, $m, $d) = @_;

     ($y >= 1 && $y <= 9999)
       or croak q/Parameter 'year' is out of range [1, 9999]/;
     ($m >= 1 && $m <= 12)
       or croak q/Parameter 'month' is out of range [1, 12]/;
     ($d >= 1 && $d <= 31)
       or croak q/Parameter 'day' is out of range [1, 31]/;

     use integer;
     if ($m < 3) {
       $y--, $m += 12;
     }
     return ((1461 * $y) >> 2) - $y / 100 + $y / 400
       + $d + ((979 * $m - 2918) >> 5) - 306;
   }

   sub rdn_to_ymd {
     @_ == 1 or croak q/Usage: rdn_to_ymd(rdn)/;
     my ($rdn) = @_;

     ($rdn >= RDN_MIN && $rdn <= RDN_MAX)
       or croak q/Parameter 'rdn' is out of range/;

     use integer;
     my $Z = $rdn + 306;
     my $H = 100 * $Z - 25;
     my $A = $H / 3652425;
     my $B = $A - ($A >> 2);
     my $y = (100 * $B + $H) / 36525;
     my $C = $B + $Z - ((1461 * $y) >> 2);
     my $m = (535 * $C + 48950) >> 14;
     my $d = $C - ((979 * $m - 2918) >> 5);
     if ($m > 12) {
       $y++, $m -= 12;
     }
     return ($y, $m, $d);
   }

   sub rdn_to_dow {
     @_ == 1 or croak q/Usage: rdn_to_dow(rdn)/;
     my ($rdn) = @_;

     ($rdn >= RDN_MIN && $rdn <= RDN_MAX)
       or croak q/Parameter 'rdn' is out of range/;
     return 1 + ($rdn + 6) % 7;
   }

   {
     my @DayOffset = (0, 6, 2, 1, 4, 6, 2, 4, 0, 3, 5, 1, 3);
     sub ymd_to_dow {
       @_ == 3 or croak q/Usage: ymd_to_dow(year, month, day)/;
       my ($y, $m, $d) = @_;

       ($y >= 1 && $y <= 9999)
         or croak q/Parameter 'year' is out of range [1, 9999]/;
       ($m >= 1 && $m <= 12)
         or croak q/Parameter 'month' is out of range [1, 12]/;
       ($d >= 1 && $d <= 31)
         or croak q/Parameter 'day' is out of range [1, 31]/;

       use integer;
       if ($m < 3) {
         $y--;
       }
       return 1 + ($y + $y/4 - $y/100 + $y/400 + $DayOffset[$m] + $d) % 7;
     }
   }

   sub resolve_century {
     @_ == 2 or croak q/Usage: resolve_century(year, pivot_year)/;
     my ($year, $pivot_year) = @_;

     ($year >= 0 && $year <= 99)
       or croak q/Parameter 'year' is out of range [0, 99]/;
     ($pivot_year >= 0 && $pivot_year <= 9899)
       or croak q/Parameter 'pivot_year' is out of range [0, 9899]/;

     use integer;
     my $century = $pivot_year / 100;
     my $base = $century * 100;
     my $pivot_offset = $pivot_year - $base;

     my $resolved = $base + $year;
     if ($year < $pivot_offset) {
       $resolved += 100;
     }
     return $resolved;
   }
}

{
  package
  Time::Str::PP::Token; # hide from PAUSE/indexers

  our @EXPORT_OK  = qw[ parse_day
                        parse_day_name
                        parse_meridiem
                        parse_month
                        parse_tz_offset ];

  use Carp     qw[croak];
  use Exporter qw[import];

  {
    my %DayMap = (
      '01' =>  1,  '1' =>  1,  '1st' =>  1,
      '02' =>  2,  '2' =>  2,  '2nd' =>  2,
      '03' =>  3,  '3' =>  3,  '3rd' =>  3,
      '04' =>  4,  '4' =>  4,  '4th' =>  4,
      '05' =>  5,  '5' =>  5,  '5th' =>  5,
      '06' =>  6,  '6' =>  6,  '6th' =>  6,
      '07' =>  7,  '7' =>  7,  '7th' =>  7,
      '08' =>  8,  '8' =>  8,  '8th' =>  8,
      '09' =>  9,  '9' =>  9,  '9th' =>  9,
                  '10' => 10, '10th' => 10,
                  '11' => 11, '11th' => 11,
                  '12' => 12, '12th' => 12,
                  '13' => 13, '13th' => 13,
                  '14' => 14, '14th' => 14,
                  '15' => 15, '15th' => 15,
                  '16' => 16, '16th' => 16,
                  '17' => 17, '17th' => 17,
                  '18' => 18, '18th' => 18,
                  '19' => 19, '19th' => 19,
                  '20' => 20, '20th' => 20,
                  '21' => 21, '21st' => 21,
                  '22' => 22, '22nd' => 22,
                  '23' => 23, '23rd' => 23,
                  '24' => 24, '24th' => 24,
                  '25' => 25, '25th' => 25,
                  '26' => 26, '26th' => 26,
                  '27' => 27, '27th' => 27,
                  '28' => 28, '28th' => 28,
                  '29' => 29, '29th' => 29,
                  '30' => 30, '30th' => 30,
                  '31' => 31, '31st' => 31,
    );

    sub parse_day {
      @_ == 1 or croak q/Usage: parse_day(string)/;
      return $DayMap{ lc shift } // croak q/Unable to parse: day is invalid/;
    }
  }

  {
    my %DayNameMap = (
      'mon' => 1, 'monday'    => 1,
      'tue' => 2, 'tuesday'   => 2, 'tues'  => 2,
      'wed' => 3, 'wednesday' => 3,
      'thu' => 4, 'thursday'  => 4, 'thurs' => 4,
      'fri' => 5, 'friday'    => 5,
      'sat' => 6, 'saturday'  => 6,
      'sun' => 7, 'sunday'    => 7,
    );

    sub parse_day_name {
      @_ == 1 or croak q/Usage: parse_day_name(string)/;
      return $DayNameMap{ lc shift } // croak q/Unable to parse: day name is invalid/;
    }
  }

  {
    my %MeridiemMap = (
      'am' =>  0, 'a.m.' =>  0,
      'pm' => 12, 'p.m.' => 12,
    );

    sub parse_meridiem {
      @_ == 1 or croak q/Usage: parse_meridiem(string)/;
      return $MeridiemMap{ lc shift } // croak q/Unable to parse: meridiem is invalid/;
    }
  }

  {
    my %MonthMap = (
      '01' =>  1,  '1' =>  1, 'i'    =>  1, 'jan' =>  1, 'january'   =>  1,
      '02' =>  2,  '2' =>  2, 'ii'   =>  2, 'feb' =>  2, 'february'  =>  2,
      '03' =>  3,  '3' =>  3, 'iii'  =>  3, 'mar' =>  3, 'march'     =>  3,
      '04' =>  4,  '4' =>  4, 'iv'   =>  4, 'apr' =>  4, 'april'     =>  4,
      '05' =>  5,  '5' =>  5, 'v'    =>  5, 'may' =>  5,
      '06' =>  6,  '6' =>  6, 'vi'   =>  6, 'jun' =>  6, 'june'      =>  6,
      '07' =>  7,  '7' =>  7, 'vii'  =>  7, 'jul' =>  7, 'july'      =>  7,
      '08' =>  8,  '8' =>  8, 'viii' =>  8, 'aug' =>  8, 'august'    =>  8,
      '09' =>  9,  '9' =>  9, 'ix'   =>  9, 'sep' =>  9, 'september' =>  9, 'sept' => 9,
                  '10' => 10, 'x'    => 10, 'oct' => 10, 'october'   => 10,
                  '11' => 11, 'xi'   => 11, 'nov' => 11, 'november'  => 11,
                  '12' => 12, 'xii'  => 12, 'dec' => 12, 'december'  => 12,
    );

    sub parse_month {
      @_ == 1 or croak q/Usage: parse_month(string)/;
      return $MonthMap{ lc shift } // croak q/Unable to parse: month is invalid/;
    }
  }

  {
    # Fast path for whole-hour offsets
    my %OffsetMap = (
      '-09' => -9*60, '-0900' => -9*60, '-09:00' => -9*60,
      '-08' => -8*60, '-0800' => -8*60, '-08:00' => -8*60,
      '-07' => -7*60, '-0700' => -7*60, '-07:00' => -7*60,
      '-06' => -6*60, '-0600' => -6*60, '-06:00' => -6*60,
      '-05' => -5*60, '-0500' => -5*60, '-05:00' => -5*60,
      '-04' => -4*60, '-0400' => -4*60, '-04:00' => -4*60,
      '-03' => -3*60, '-0300' => -3*60, '-03:00' => -3*60,
      '-02' => -2*60, '-0200' => -2*60, '-02:00' => -2*60,
      '-01' => -1*60, '-0100' => -1*60, '-01:00' => -1*60,
      '+00' =>  0*60, '+0000' =>  0*60, '+00:00' =>  0*60,
      '+01' =>  1*60, '+0100' =>  1*60, '+01:00' =>  1*60,
      '+02' =>  2*60, '+0200' =>  2*60, '+02:00' =>  2*60,
      '+03' =>  3*60, '+0300' =>  3*60, '+03:00' =>  3*60,
      '+04' =>  4*60, '+0400' =>  4*60, '+04:00' =>  4*60,
      '+05' =>  5*60, '+0500' =>  5*60, '+05:00' =>  5*60,
      '+06' =>  6*60, '+0600' =>  6*60, '+06:00' =>  6*60,
      '+07' =>  7*60, '+0700' =>  7*60, '+07:00' =>  7*60,
      '+08' =>  8*60, '+0800' =>  8*60, '+08:00' =>  8*60,
      '+09' =>  9*60, '+0900' =>  9*60, '+09:00' =>  9*60,
    );

    # ±H ±HH ±HHMM ±H:MM ±HH:MM
    my $Offset_Rx = qr{
      \A
        (?<sign> [+-])
        (?:
            (?:
              (?<hour> [0-9]{2}) (?: [:]? (?<minute> [0-9]{2}) )?
            )
          |
            (?:
              (?<hour> [0-9]{1}) (?: [:] (?<minute> [0-9]{2}) )?
            )
        )
      \z
    }x;

    sub parse_tz_offset {
      @_ == 1 or croak q/Usage: parse_tz_offset(string)/;
      my $string = shift;

      return $OffsetMap{$string} // do {
        ($string =~ $Offset_Rx)
          or croak q/Unable to parse: timezone offset is invalid/;

        my $h = $+{hour};
        my $m = $+{minute} // 0;
        ($h <= 23 && $m <= 59)
          or croak q/Unable to parse: timezone offset is invalid/;

        my $offset = $h * 60 + $m;
        if ($+{sign} eq '-') {
          $offset *= -1;
        }
        $offset;
      };
    }
  }
}

{
  package
  Time::Str::PP::Time; # hide from PAUSE/indexers

  our @EXPORT_OK = qw[ timegm_posix
                       timegm_modern
                       valid_hms
                       valid_hms60 ];

  use Carp     qw[croak];
  use Exporter qw[import];

  use constant RDN_UNIX_EPOCH => 719163; # 1970-01-01

  sub valid_hms {
    @_ == 3 or croak q/Usage: valid_hms(hour, minute, second)/;
    my ($h, $m, $s) = @_;
    return ($h >= 0 && $h <= 23)
        && ($m >= 0 && $m <= 59)
        && ($s >= 0 && $s <= 59);
  }

  sub valid_hms60 {
    @_ == 3 or croak q/Usage: valid_hms60(hour, minute, second)/;
    my ($h, $m, $s) = @_;
    return ($h >= 0 && $h <= 23)
        && ($m >= 0 && $m <= 59)
        && ($s >= 0 && $s <= 60);
  }

  sub timegm_modern {
    @_ == 6 or croak q/Usage: timegm_modern(sec, min, hour, mday, mon, year)/;
    my ($S, $M, $H, $d, $m, $y) = @_;

    ($y >= 1 && $y <= 9999)
      or croak q/Parameter 'year' is out of range [1, 9999]/;
    ($m >= 1 && $m <= 12)
      or croak q/Parameter 'month' is out of range [1, 12]/;
    ($d >= 1 && ($d <= 28 || $d <= Time::Str::PP::Calendar::month_days($y, $m)))
      or croak q/Parameter 'day' is out of range/;
    ($H >= 0 && $H <= 23)
      or croak q/Parameter 'hour' is out of range [0, 23]/;
    ($M >= 0 && $M <= 59)
      or croak q/Parameter 'minute' is out of range [0, 59]/;
    ($S >= 0 && $S <= 59)
      or croak q/Parameter 'second' is out of range [0, 59]/;

    my $rdn = do {
      use integer;
      if ($m < 3) {
        $y--, $m += 12;
      }
      ((1461 * $y) >> 2) - $y / 100 + $y / 400
        + $d + ((979 * $m - 2918) >> 5) - 306;
    };
    return ($rdn - RDN_UNIX_EPOCH) * 86400 + $H * 3600 + $M * 60 + $S;
  }

  sub timegm_posix {
    @_ == 6 or croak q/Usage: timegm_posix(sec, min, hour, mday, mon, year)/;
    my ($S, $M, $H, $d, $m, $y) = @_;
    return timegm_modern($S, $M, $H, $d, $m + 1, $y + 1900);
  }
}

{
  package
  Time::Str::PP::Util; # hide from PAUSE/indexers

  our @EXPORT_OK = qw[ lower_bound
                       upper_bound ];

  use Carp     qw[croak];
  use Exporter qw[import];

  sub lower_bound {
    (@_ >= 2 && @_ <= 4) or croak q/Usage: lower_bound(array, value [, lo [, h i]])/;
    my ($array, $value, $lo, $hi) = @_;

    ref $array eq 'ARRAY'
      or croak q/Parameter 'array' must be an array reference/;

    $lo //= 0;
    $hi //= @$array;
    while ($lo < $hi) {
      my $mid = ($lo + $hi) >> 1;
      if   ($array->[$mid] < $value) { $lo = $mid + 1 }
      else                           { $hi = $mid     }
    }
    return $lo;
  }

  sub upper_bound {
    (@_ >= 2 && @_ <= 4) or croak q/Usage: upper_bound(array, value [, lo [, hi ]])/;
    my ($array, $value, $lo, $hi) = @_;

    ref $array eq 'ARRAY'
      or croak q/Parameter 'array' must be an array reference/;

    $lo //= 0;
    $hi //= @$array;
    while ($lo < $hi) {
      my $mid = ($lo + $hi) >> 1;
      if   ($array->[$mid] <= $value) { $lo = $mid + 1 }
      else                            { $hi = $mid     }
    }
    return $lo;
  }
}

{
  my @import = qw [ valid_ymd
                    resolve_century
                    ymd_to_dow
                    ymd_to_rdn ];
  Time::Str::PP::Calendar->import(@import);
}
{
  my @import = qw[ parse_day
                   parse_day_name
                   parse_meridiem
                   parse_month
                   parse_tz_offset ];
  Time::Str::PP::Token->import(@import);
}

use constant DEFAULT_PRECISION  => length pack('F', 0) > 8 ? 9 : 6;
use constant DEFAULT_PIVOT_YEAR => 1950;
use constant NANOS_PER_SECOND   => 1_000_000_000;

my %CanonicalFormatName = (
  ansic      => 'ANSIC',
  asn1gt     => 'ASN.1 GeneralizedTime',
  asn1ut     => 'ASN.1 UTCTime',
  clf        => 'Common Log Format',
  datetime   => 'DateTime',
  ecmascript => 'ECMAScript',
  gitdate    => 'GitDate',
  iso8601    => 'ISO 8601',
  iso9075    => 'ISO 9075',
  rfc2616    => 'RFC 2616',
  rfc2822    => 'RFC 2822',
  rfc2822fws => 'RFC 2822 (Folding WS)',
  rfc3339    => 'RFC 3339',
  rfc3501    => 'RFC 3501',
  rfc4287    => 'RFC 4287',
  rfc5280    => 'RFC 5280',
  rfc5545    => 'RFC 5545',
  rfc9557    => 'RFC 9557',
  rubydate   => 'RubyDate',
  unixdate   => 'UnixDate',
  unixstamp  => 'UnixStamp',
  w3cdtf     => 'W3CDTF',
);

my (%RegexpMap, $RFC2616_Rx, $RFC3339_Rx);

BEGIN {
  require Time::Str::Regexp;
  %RegexpMap = Time::Str::Regexp::mapping();

  $RFC2616_Rx = $RegexpMap{rfc2616};
  $RFC3339_Rx = $RegexpMap{rfc3339};

  my %aliases = (
    atom       => 'rfc4287',
    ctime      => 'ansic',
    email      => 'rfc2822',
    generic    => 'datetime',
    git        => 'gitdate',
    http       => 'rfc2616',
    ical       => 'rfc5545',
    imap       => 'rfc3501',
    imf        => 'rfc2822',
    ixdtf      => 'rfc9557',
    javascript => 'ecmascript',
    rfc5322    => 'rfc2822',
    rfc7231    => 'rfc2616',
    rfc9051    => 'rfc3501',
    ruby       => 'rubydate',
    sql        => 'iso9075',
    unix       => 'unixdate',
    w3c        => 'w3cdtf',
    x509       => 'rfc5280',
  );

  while (my ($alias, $to) = each %aliases) {
    $RegexpMap{$alias} = $RegexpMap{$to};
    $CanonicalFormatName{$alias} = $CanonicalFormatName{$to};
  }
}

sub valid_hms {
    my ($h, $m, $s) = @_;
    return ($h >= 0 && $h <= 23
         && $m >= 0 && $m <= 59
         && $s >= 0 && ($s <= 59 || ($s == 60 && $h == 23 && $m == 59)));
}

sub str2date {
  @_ & 1 or croak q/Usage: str2date(string [, format => 'RFC3339' ])/;
  my ($string, %p) = @_;

  my ($format, $regexp, $pivot_year) = ('rfc3339', $RFC3339_Rx);

  while (my ($name, $v) = each %p) {
    if ($name eq 'format') {
      $format = lc $v;
      $regexp = $RegexpMap{$format};
      (defined $regexp)
        or croak qq/Parameter 'format' is unknown: '$v'/;
    }
    elsif ($name eq 'pivot_year') {
      $pivot_year = $v;
      ($pivot_year >= 0 && $pivot_year <= 9899)
        or croak q/Parameter 'pivot_year' is out of range [0, 9899]/;
    }
    else {
      croak qq/Unrecognised named parameter: '$name'/;
    }
  }

  (defined $string && $string =~ $regexp)
    or croak qq/Unable to parse: string does not match the $CanonicalFormatName{$format} format/;

  my %r = %+;

  if (length $r{year} == 2) {
    $r{year} = resolve_century($r{year}, $pivot_year // DEFAULT_PIVOT_YEAR);
  }

  if (exists $r{month}) {
    $r{month} = parse_month($r{month});
  }

  if (exists $r{day}) {
    $r{day} = parse_day($r{day});
  }

  valid_ymd($r{year}, $r{month} // 1, $r{day} // 1)
    or croak q/Unable to parse: date is out of range/;

  if (exists $r{day_name}) {
    my $dow = parse_day_name(delete $r{day_name});

    ($dow == ymd_to_dow($r{year}, $r{month} // 1, $r{day} // 1))
      or croak q/Unable to parse: day name does not match date/;
  }

  if (exists $r{hour}) {

    if (exists $r{meridiem}) {
      my $hour = $r{hour};

      ($hour >= 1 && $hour <= 12)
        or croak q/Unable to parse: hour is out of range for 12-hour clock/;
      $r{hour} = ($hour % 12) + parse_meridiem(delete $r{meridiem});
    }

    valid_hms($r{hour}, $r{minute} // 0, $r{second} // 0)
      or croak q/Unable to parse: time of day is out of range/;

    if (exists $r{fraction}) {
      my $f = delete $r{fraction};
      my $ns = $f * (10 ** (9 - length $f));

      if (exists $r{second}) {
        # HH.MM.SS.fraction
        $r{nanosecond} = $ns;
      }
      elsif (exists $r{minute}) {
        # HH.MM.fraction
        my $total_ns = $ns * 60;
        $r{second} = int($total_ns / NANOS_PER_SECOND);
        my $nsec = $total_ns % NANOS_PER_SECOND;
        if ($nsec != 0) {
          $r{nanosecond} = $nsec;
        }
      }
      else {
        # HH.fraction
        my $total_ns = $ns * 3600;
        my $min = int($total_ns / (60 * NANOS_PER_SECOND));
        $r{minute} = $min;
        $total_ns -= $min * 60 * NANOS_PER_SECOND;
        my $sec = int($total_ns / NANOS_PER_SECOND);
        my $nsec = $total_ns % NANOS_PER_SECOND;
        if ($sec != 0 || $nsec != 0) {
          $r{second} = $sec;
          if ($nsec != 0) {
            $r{nanosecond} = $nsec;
          }
        }
      }
    }

    if (exists $r{tz_offset}) {
      $r{tz_offset} = parse_tz_offset($r{tz_offset});
    }

    if (exists $r{tz_utc}) {
      $r{tz_offset} //= 0;
    }
  }

  if ($regexp == $RFC2616_Rx && !$r{tz_utc}) {
    $r{tz_utc} = 'GMT';
    $r{tz_offset} = 0;
  }

  {
    local @r{qw(tz_utc tz_abbrev tz_annotation)};
    $_ += 0 for values %r;
  }
  return wantarray ? %r : \%r;
}

sub str2time {
  @_ & 1 or croak q/Usage: str2time(string [, format => 'RFC3339' ])/;
  my ($string, %p) = @_;

  my $precision;

  if (exists $p{precision}) {
    $precision = delete $p{precision};
    ($precision >= 0 && $precision <= 9)
      or croak q/Parameter 'precision' is out of range [0, 9]/;
  }

  my $r = str2date($string, %p);

  (exists $r->{tz_offset})
    or croak q/Unable to convert: timestamp string without a UTC designator or numeric offset/;

  my ($Y, $M, $D, $h, $m, $s) = @$r{qw(year month day hour minute second)};
  $m //= 0;
  $s //= 0;

  my $rdn  = ymd_to_rdn($Y, $M, $D);
  my $sod  = ($h * 60 + $m) * 60 + $s;
  my $time = ($rdn - 719163) * 86400 + $sod - $r->{tz_offset} * 60;
  if (exists $r->{nanosecond}) {
    my $scale    = 10 ** ($precision // DEFAULT_PRECISION);
    my $fraction = int($r->{nanosecond} * $scale / NANOS_PER_SECOND);
    $time += $fraction / $scale;
  }
  return $time;
}

{
  my @DoW = qw[Sun Mon Tue Wed Thu Fri Sat];
  my @MoY = qw[Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec];

  sub format_offset_basic {
    my ($offset, $zulu) = @_;

    if ($offset == 0) {
      return $zulu;
    }
    else {
      my $sign = $offset < 0 ? -1 : 1;
      my $min  = abs $offset;
      return sprintf '%+.4d', $sign * int($min / 60) * 100 + $min % 60;
    }
  }

  sub format_offset_extended {
    my ($offset, $zulu) = @_;

    if ($offset == 0) {
      return $zulu;
    }
    else {
      my $sign = $offset < 0 ? ord '-' : ord '+';
      my $min  = abs $offset;
      return sprintf '%c%.2d:%.2d', $sign, int($min / 60), $min % 60;
    }
  }

  sub format_ASN1UT {
    my ($time, $offset) = @_;

    $time += $offset * 60;
    my ($sec, $min, $hour, $mday, $mon, $year) = gmtime $time;
    my $zstr = format_offset_basic($offset, 'Z');
    return sprintf '%02d%02d%02d%02d%02d%02d%s',
      ($year + 1900) % 100, $mon + 1, $mday, $hour, $min, $sec, $zstr;
  }

  sub format_ASN1GT {
    my ($time, $offset, $fraction) = @_;

    $time += $offset * 60;
    my ($sec, $min, $hour, $mday, $mon, $year) = gmtime $time;
    my $zstr = format_offset_basic($offset, 'Z');
    return sprintf '%04d%02d%02d%02d%02d%02d%s%s',
      $year + 1900, $mon + 1, $mday, $hour, $min, $sec, $fraction, $zstr;
  }
  
  sub format_CLF {
    my ($time, $offset, $fraction) = @_;

    $time += $offset * 60;
    my ($sec, $min, $hour, $mday, $mon, $year) = gmtime $time;
    my $zstr = format_offset_basic($offset, '+0000');
    return sprintf '%02d/%s/%04d:%02d:%02d:%02d%s %s',
      $mday, $MoY[$mon], $year + 1900, $hour, $min, $sec, $fraction, $zstr;
  }

  sub format_RFC2616 {
    my ($time, $offset) = @_;

    my ($sec, $min, $hour, $mday, $mon, $year, $wday) = gmtime $time;
    return sprintf '%s, %02d %s %04d %02d:%02d:%02d GMT',
      $DoW[$wday], $mday, $MoY[$mon], $year + 1900, $hour, $min, $sec;
  }

  sub format_RFC2822 {
    my ($time, $offset) = @_;

    $time += $offset * 60;
    my ($sec, $min, $hour, $mday, $mon, $year, $wday) = gmtime $time;
    my $zstr = format_offset_basic($offset, '+0000');
    return sprintf '%s, %d %s %04d %02d:%02d:%02d %s',
      $DoW[$wday], $mday, $MoY[$mon], $year + 1900, $hour, $min, $sec, $zstr;
  }
  
  sub format_RFC3501 {
    my ($time, $offset) = @_;

    $time += $offset * 60;
    my ($sec, $min, $hour, $mday, $mon, $year) = gmtime $time;
    my $zstr = format_offset_basic($offset, '+0000');
    return sprintf '%02d-%s-%04d %02d:%02d:%02d %s',
      $mday, $MoY[$mon], $year + 1900, $hour, $min, $sec, $zstr;
  }

  sub format_RFC3339 {
    my ($time, $offset, $fraction) = @_;

    $time += $offset * 60;
    my ($sec, $min, $hour, $mday, $mon, $year) = gmtime $time;
    my $zstr = format_offset_extended($offset, 'Z');
    return sprintf '%04d-%02d-%02dT%02d:%02d:%02d%s%s',
      $year + 1900, $mon + 1, $mday, $hour, $min, $sec, $fraction, $zstr;
  }

  sub TIME_20500101 () { 2524608000 }

  sub format_RFC5280 {
    my ($time) = @_;

    if ($time < TIME_20500101) {
      return format_ASN1UT($time, 0);
    }
    else {
      return format_ASN1GT($time, 0, '');
    }
  }

  sub format_RFC5545 {
    my ($time) = @_;

    my ($sec, $min, $hour, $mday, $mon, $year) = gmtime $time;
    return sprintf '%04d%02d%02dT%02d%02d%02dZ',
      $year + 1900, $mon + 1, $mday, $hour, $min, $sec;
  }

  sub format_ISO9075 {
    my ($time, $offset, $fraction) = @_;

    $time += $offset * 60;
    my ($sec, $min, $hour, $mday, $mon, $year) = gmtime $time;
    my $zstr = format_offset_extended($offset, '+00:00');
    return sprintf '%04d-%02d-%02d %02d:%02d:%02d%s %s',
      $year + 1900, $mon + 1, $mday, $hour, $min, $sec, $fraction, $zstr;
  }

  sub format_ECMAScript {
    my ($time, $offset) = @_;

    $time += $offset * 60;
    my ($sec, $min, $hour, $mday, $mon, $year, $wday) = gmtime $time;
    my $zstr = format_offset_basic($offset, '+0000');
    return sprintf '%s %s %02d %04d %02d:%02d:%02d GMT%s',
      $DoW[$wday], $MoY[$mon], $mday, $year + 1900, $hour, $min, $sec, $zstr;
  }

  sub format_ANSIC {
    my ($time) = @_;
    return scalar gmtime $time;
  }

  sub format_UnixDate {
    my ($time, $offset) = @_;

    $time += $offset * 60;
    my ($sec, $min, $hour, $mday, $mon, $year, $wday) = gmtime $time;
    my $zstr = format_offset_basic($offset, 'UTC');
    return sprintf '%s %s %2d %02d:%02d:%02d %s %04d',
      $DoW[$wday], $MoY[$mon], $mday, $hour, $min, $sec, $zstr, $year + 1900;
  }

  sub format_UnixStamp {
    my ($time, $offset, $fraction) = @_;

    $time += $offset * 60;
    my ($sec, $min, $hour, $mday, $mon, $year, $wday) = gmtime $time;
    my $zstr = format_offset_basic($offset, 'UTC');
    return sprintf '%s %s %2d %02d:%02d:%02d%s %s %04d',
      $DoW[$wday], $MoY[$mon], $mday, $hour, $min, $sec, $fraction, $zstr, $year + 1900;
  }

  sub format_RubyDate {
    my ($time, $offset) = @_;

    $time += $offset * 60;
    my ($sec, $min, $hour, $mday, $mon, $year, $wday) = gmtime $time;
    my $zstr = format_offset_basic($offset, '+0000');
    return sprintf '%s %s %02d %02d:%02d:%02d %s %04d',
      $DoW[$wday], $MoY[$mon], $mday, $hour, $min, $sec, $zstr, $year + 1900;
  }

  sub format_GitDate {
    my ($time, $offset) = @_;

    $time += $offset * 60;
    my ($sec, $min, $hour, $mday, $mon, $year, $wday) = gmtime $time;
    my $zstr = format_offset_basic($offset, '+0000');
    return sprintf '%s %s %d %02d:%02d:%02d %04d %s',
      $DoW[$wday], $MoY[$mon], $mday, $hour, $min, $sec, $year + 1900, $zstr;
  }
}

my %FormatMap = (
  ansic      => \&format_ANSIC,
  asn1gt     => \&format_ASN1GT,
  asn1ut     => \&format_ASN1UT,
  atom       => \&format_RFC3339,
  clf        => \&format_CLF,
  ctime      => \&format_ANSIC,
  ecmascript => \&format_ECMAScript,
  email      => \&format_RFC2822,
  git        => \&format_GitDate,
  gitdate    => \&format_GitDate,
  http       => \&format_RFC2616,
  ical       => \&format_RFC5545,
  imap       => \&format_RFC3501,
  imf        => \&format_RFC2822,
  iso8601    => \&format_RFC3339,
  iso9075    => \&format_ISO9075,
  ixdtf      => \&format_RFC3339,
  javascript => \&format_ECMAScript,
  rfc2616    => \&format_RFC2616,
  rfc2822    => \&format_RFC2822,
  rfc2822fws => \&format_RFC2822,
  rfc3339    => \&format_RFC3339,
  rfc3501    => \&format_RFC3501,
  rfc4287    => \&format_RFC3339,
  rfc5280    => \&format_RFC5280,
  rfc5322    => \&format_RFC2822,
  rfc5545    => \&format_RFC5545,
  rfc7231    => \&format_RFC2616,
  rfc9051    => \&format_RFC3501,
  rfc9557    => \&format_RFC3339,
  ruby       => \&format_RubyDate,
  rubydate   => \&format_RubyDate,
  sql        => \&format_ISO9075,
  unix       => \&format_UnixDate,
  unixdate   => \&format_UnixDate,
  unixstamp  => \&format_UnixStamp,
  w3c        => \&format_RFC3339,
  w3cdtf     => \&format_RFC3339,
  x509       => \&format_RFC5280,
);

BEGIN {
  if ($^V ge v5.40) {
    builtin->import(qw(floor));
  }
  else {
    require POSIX; POSIX->import(qw(floor));
  }
}

use constant MIN_TIME => -62135596800; # 0001-01-01T00:00:00Z
use constant MAX_TIME => 253402300799; # 9999-12-31T23:59:59Z

sub time2str {
  @_ & 1 or croak(q/Usage: time2str(time [, format => 'RFC3339' ])/);
  my ($time, %p) = @_;

  # Rejects NaN and Inf
  ($time >= MIN_TIME && $time < MAX_TIME + 1)
    or croak q/Parameter 'time' is out of range/;

  my ($formatter, $offset, $precision, $nanosecond) = (\&format_RFC3339, 0);

  while (my ($name, $v) = each %p) {
    if ($name eq 'format') {
      $formatter = $FormatMap{lc $v};
      (defined $formatter)
        or croak qq/Parameter 'format' is unknown: '$v'/;
    }
    elsif ($name eq 'precision') {
      $precision = $v;
      ($precision >= 0 && $precision <= 9)
        or croak q/Parameter 'precision' is out of range [0, 9]/;
    }
    elsif ($name eq 'nanosecond') {
      $nanosecond = $v;
      ($nanosecond >= 0 && $nanosecond <= 999_999_999)
        or croak q/Parameter 'nanosecond' is out of range [0, 999_999_999]/;
    }
    elsif ($name eq 'offset') {
      $offset = $v;
      ($offset >= -1439 && $offset <= 1439)
        or croak q/Parameter 'offset' is out of range [-1439, 1439]/;
    }
    else {
      croak qq/Unrecognised named parameter: '$name'/;
    }
  }

  if (!defined $nanosecond && int $time != $time) {
    my $sec   = floor($time);
    my $frac  = $time - $sec;
    my $scale = 10 ** ($precision // DEFAULT_PRECISION);

    $time = $sec;
    $frac = floor($frac * $scale + 0.5) / $scale;
    $nanosecond = floor($frac * NANOS_PER_SECOND + 0.5);

    if ($nanosecond >= NANOS_PER_SECOND) {
      $nanosecond -= NANOS_PER_SECOND;
      $time++;
    }
  }

  if ($offset) {
    my $local_time = $time + $offset * 60;

    # Most string formats cannot represent years outside 0001-9999;
    # an offset may shift a valid timestamp beyond that range
    ($local_time >= MIN_TIME && $local_time <= MAX_TIME)
      or croak q/Parameter 'time' is out of range for the given offset/;
  }

  my $fraction = '';
  if (defined $nanosecond || defined $precision) {

    if (!defined $precision) {
      if ($nanosecond == 0) {
        $precision = 0;
      }
      elsif (($nanosecond % 1_000_000) == 0) {
        $precision = 3;
      }
      elsif (($nanosecond % 1_000) == 0) {
        $precision = 6;
      }
      else {
        $precision = 9;
      }
    }

    if ($precision != 0) {
      $nanosecond //= 0;
      $fraction = sprintf '.%.*d',
        $precision, int($nanosecond / (10 ** (9 - $precision)));
    }
  }
  return $formatter->($time, $offset, $fraction);
}

1;
