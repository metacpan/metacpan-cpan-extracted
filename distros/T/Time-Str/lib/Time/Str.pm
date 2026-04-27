package Time::Str;
use strict;
use warnings;
use v5.10;

our $VERSION     = '0.02';
our @EXPORT_OK   = qw[ time2str str2time str2date ];
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

use Exporter qw[import];
use Carp     qw[croak];
use POSIX    qw[floor];

my $DefaultPivotYear = 1950;

sub MIN_TIME () { -62135596800 } # 0001-01-01T00:00:00Z
sub MAX_TIME () { 253402300799 } # 9999-12-31T23:59:59Z

sub NANOS_PER_SECOND  () { 1_000_000_000 }

BEGIN {
  *DEFAULT_PRECISION = (length pack('F', 0) > 8) ? sub () {9} : sub () {6};
}

my %MonthIndexMap = qw(
  i     1 jan  1 january    1
  ii    2 feb  2 february   2
  iii   3 mar  3 march      3
  iv    4 apr  4 april      4
  v     5 may  5
  vi    6 jun  6 june       6
  vii   7 jul  7 july       7
  viii  8 aug  8 august     8
  ix    9 sep  9 september  9 sept 9
  x    10 oct 10 october   10
  xi   11 nov 11 november  11
  xii  12 dec 12 december  12
);

my %MeridiemMap = qw(
    am AM a.m. AM
    pm PM p.m. PM
);

#
# Generic DateTime
#
#  Parses a broad set of real-world date and time formats, accepting only 
#  those that can be parsed deterministically. Numeric-only dates must use 
#  Y-M-D order with separators. Any other ordering requires the month to 
#  be given as a name or Roman numeral. Every date must include a four-digit 
#  year. Optional time components include hours, minutes, seconds, fractional 
#  seconds, AM/PM, and time zones. Parsing is structurally deterministic; 
#  semantic validation occurs after matching.
#
# ISO 8601 - Date and time format:
#   2012-12-24
#   2012-12-24T15:30
#   2012-12-24T15:30+01
#   2012-12-24T15:30:45,500+01
#
# RFC 3339 - Internet timestamps:
#   2012-12-24T15:30:45+01:00
#   2012-12-24T15:30:45.500+01:00
#
# RFC 9557 - Timestamps with additional information:
#   2012-12-24T15:30:45.500+01:00[Europe/Stockholm]
#
# RFC 2822 - Internet Message Format:
#   Mon, 24 Dec 2012 15:30:45 +0100
#   Mon, 24 Dec 2012 15:30 +0100
#   24 Dec 2012 15:30:45 +0100
#   24 Dec 2012 15:30 +0100
#
# RFC 2616 - HTTP-date:
#   Mon, 24 Dec 2012 15:30:45 GMT
#
# RFC 9051 - IMAP date-time:
#   24-Dec-2012 15:30:45 +0100
#
# ISO 9075 - SQL timestamp w/ and w/o zone:
#   2012-12-24 15:30:45
#   2012-12-24 15:30:45 +01:00
#   2012-12-24 15:30:45.500
#   2012-12-24 15:30:45.500 +01:00
#
# ECMAScript Date.prototype.toString:
#   Mon Dec 24 2012 15:30:45 GMT+0100 (Central European Time)
#
# Long-form Textual:
#   Monday, 24 December 2012, 15:30 GMT+1
#   Monday, 24th December 2012 at 3:30 pm UTC+1 (CET)
#   Monday, December 24, 2012, 3:30 PM
#   December 24th, 2012 at 3:30 PM
#
# Short-form Variations:
#   Dec/24/2012 03:30:45 PM
#   24. XII. 2012 12PM UTC+1 (CET)
#   24DEC2012 12:30:45.500 UTC+1
#   24.Dec.2012 15:30:45
#
my $GenericDateTime_Rx = qr{
  (?(DEFINE)
    (?<DayNameShort>   (?i: Mon|Tue|Tues|Wed|Thu|Thurs|Fri|Sat|Sun))
    (?<DayNameLong>    (?i: Monday|Tuesday|Wednesday|Thursday|Friday|
                            Saturday|Sunday))
    (?<DayName>        (?&DayNameShort) | (?&DayNameLong))
    (?<DayNamePrefix>  (?&DayName) [.]?[,]? [ ])
    (?<MonthNameShort> (?i: Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Sept|Oct|Nov|Dec))
    (?<MonthNameLong>  (?i: January|February|March|April|May|June|
                            July|August|September|October|November|December))
    (?<MonthName>      (?&MonthNameShort) | (?&MonthNameLong))
    (?<MonthRoman>     (?i: I|II|III|IV|V|VI|VII|VIII|IX|X|XI|XII))
    (?<MonthTextual>   (?&MonthName) | (?&MonthRoman))
    (?<OrdinalSuffix>  (?i: st|nd|rd|th))
    (?<Meridiem>       (?: [AaPp] (?: [Mm] | [.][Mm][.])))
    (?<TimeZoneOffset>  (?: [+-] (?: [0-9]{4} | [0-9]{1,2} (?: [:][0-9]{2})? )))
    (?<TimeZoneAbbrev> [A-Z][A-Za-z][A-Z]{1,4})
  )

  \A

  # Note: Day names and ordinal suffixes (e.g., "Mon", "th") are matched by the
  # regex but are not validated against the parsed date. (XXX reconsider this!)

  (?&DayNamePrefix)?

  (?:
      (?:
                   (?<year>  [0-9]{4})
           ([-./]) (?<month> (?&MonthName) | [0-9]{1,2})
           \g{-2}  (?<day>   [0-9]{1,2})
        |
                   (?<day>   [0-9]{1,2})
           ([-./]) (?<month> (?&MonthTextual))
           \g{-2}  (?<year>  [0-9]{4})
        |
                   (?<month> (?&MonthName))
           ([-./]) (?<day>   [0-9]{1,2})
           \g{-2}  (?<year>  [0-9]{4})
      )
    |
      (?:
               (?<day>   [0-9]{1,2}) (?: (?&OrdinalSuffix) | [.] )?
           [ ] (?<month> (?&MonthTextual)) [.,]?
           [ ] (?<year>  [0-9]{4})
        |
               (?<month> (?&MonthName)) [.,]?
           [ ] (?<day>   [0-9]{1,2}) (?&OrdinalSuffix)? [,]?
           [ ] (?<year>  [0-9]{4})
      )
    |
      (?:
           (?<year> [0-9]{4})   (?<month> (?&MonthName))    (?<day>  [0-9]{1,2})
        |  (?<day>  [0-9]{1,2}) (?<month> (?&MonthTextual)) (?<year> [0-9]{4})
      )
  )

  (?:

    (?: (?: [ ] (?: [Aa][Tt][ ] )? ) | (?: [,][ ]) | [Tt] )

    # Note: Dot-separated times (HH.MM or HH.MM.SS) are not accepted; only HH:MM
    # or HH:MM:SS are allowed. This avoids ambiguity where ISO 8601 decimal hours
    # or minutes could be misinterpreted as hour–minute or minute–second notation.

    (?:
             (?<hour>     [0-9]{1,2})
         [:] (?<minute>   [0-9]{2}) (?: [:]  (?<second>   [0-9]{2})
                                    (?: [.,] (?<fraction> [0-9]{1,9}) )?)?

         (?: [ ]? (?<meridiem> (?&Meridiem)) )?
      |
              (?<hour>     [0-9]{1,2})
         [ ]? (?<meridiem> (?&Meridiem))
    )

    (?:

      [ ]?

      (?:
           (?<tz_offset> (?&TimeZoneOffset))
        |  (?<tz_utc>    (?:GMT|UTC)) (?: (?<tz_offset> (?&TimeZoneOffset)) )?
        |  (?<tz_utc>    [Zz])
        |  (?<tz_abbrev> (?&TimeZoneAbbrev))
      )
      
      # Annotation tags as defined in RFC 9557 (IXDTF) and Java’s [ZoneID].
      (?:
        (?<tz_annotation> (?: \[ [^\[\]]+ \] )+ )
      )?

      # Accept parenthesized comment (typically time-zone abbreviations
      # or descriptive zone names).
      (?:
        [ ] (?: \( [^()]+ \) )
      )?

    )?
  )?

  \z
}x;

# ITU-T X.680 (ISO/IEC 8824-1) Abstract Syntax Notation One (ASN.1)
# <https://www.itu.int/rec/T-REC-X.680-202102-I>
# <https://www.iso.org/standard/81416.html>
#
#  ASN.1 GeneralizedTime
#   YYYYMMDDhh[mm[ss]][(.|,)fraction][Z|±hh[mm]]
#
my $ASN1GT_Rx = qr{
   \A

   (?<year>   [0-9]{4})
   (?<month>  [0-9]{2})
   (?<day>    [0-9]{2})
   (?<hour>   [0-9]{2}) (?: (?<minute> [0-9]{2})
                        (?: (?<second> [0-9]{2}))?)?

   (?: [.,] (?<fraction> [0-9]{1,9}))?

   (?:
        (?<tz_offset> [+-][0-9]{2} (?: [0-9]{2})? )
     |  (?<tz_utc>    [Z])
   )?
   \z
}x;

#  ASN.1 UTCTime
#   YYMMDDhhmm[ss](Z|±hhmm)
#
my $ASN1UT_Rx = qr{
   \A

   (?<year>   [0-9]{2})
   (?<month>  [0-9]{2})
   (?<day>    [0-9]{2})
   (?<hour>   [0-9]{2})
   (?<minute> [0-9]{2}) (?: (?<second> [0-9]{2}))?
   (?:
        (?<tz_offset> [+-][0-9]{4})
     |  (?<tz_utc>    [Z])
   )
   \z
}x;

# W3 Consortium Date and Time Formats
# <https://www.w3.org/TR/NOTE-datetime>
#
#   YYYY
#   YYYY-MM
#   YYYY-MM-DD
#   YYYY-MM-DDThh:mm:ss[.fraction](Z|±hh:mm)
#
my $W3CDTF_Rx = qr{
   \A

   (?<year> [0-9]{4})

   (?: [-] (?<month>  [0-9]{2})
   (?: [-] (?<day>    [0-9]{2})
   (?: [T] (?<hour>   [0-9]{2})
       [:] (?<minute> [0-9]{2})
       [:] (?<second> [0-9]{2}) (?: [.] (?<fraction> [0-9]{1,9}) )?
           (?:
                (?<tz_offset> [+-][0-9]{2}[:][0-9]{2})
             |  (?<tz_utc>    [Z])
           )
   )?)?)?
   \z
}x;

# RFC 2616 Hypertext Transfer Protocol (HTTP/1.1)
# <https://datatracker.ietf.org/doc/html/rfc2616#section-3.3>
# <https://datatracker.ietf.org/doc/html/rfc7231#section-7.1.1.1>
#
#   DDD, DD MMM YYYY hh:mm:ss GMT   # IMF-fixdate
#   DDDD, DD-MMM-YY hh:mm:ss GMT    # RFC 850
#   DDD MMM (_D|DD) hh:mm:ss YYYY   # ANSI C's ctime
#
my $RFC2616_Rx = qr{
  (?(DEFINE)
    (?<DayNameShort>   (?: Mon|Tue|Wed|Thu|Fri|Sat|Sun))
    (?<DayNameLong>    (?: Monday|Tuesday|Wednesday|Thursday|Friday|
                            Saturday|Sunday))
    (?<MonthNameShort> (?: Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec))
  )
  \A
  (?:
    # IMF-fixdate
    (?:
      (?&DayNameShort) [,]
      [ ] (?<day>    [0-9]{2})
      [ ] (?<month>  (?&MonthNameShort))
      [ ] (?<year>   [0-9]{4})
      [ ] (?<hour>   [0-9]{2})
      [:] (?<minute> [0-9]{2})
      [:] (?<second> [0-9]{2})
      [ ] (?<tz_utc> GMT)
    )
  | # RFC 850
    (?:
      (?&DayNameLong) [,]
      [ ] (?<day>    [0-9]{2})
      [-] (?<month>  (?&MonthNameShort))
      [-] (?<year>   [0-9]{2})
      [ ] (?<hour>   [0-9]{2})
      [:] (?<minute> [0-9]{2})
      [:] (?<second> [0-9]{2})
      [ ] (?<tz_utc> GMT)
    )
  | # ANSI C's ctime
    (?:
      (?&DayNameShort)
      [ ] (?<month>  (?&MonthNameShort))
      (?:
          (?: [ ]{2} (?<day> [0-9]{1}))
        | (?: [ ]{1} (?<day> [0-9]{2}))
      )
      [ ] (?<hour>   [0-9]{2})
      [:] (?<minute> [0-9]{2})
      [:] (?<second> [0-9]{2})
      [ ] (?<year>   [0-9]{4})
    )
  )
  \z
}x;

# RFC 2822 Internet Message Format
# <https://datatracker.ietf.org/doc/html/rfc2822#section-3.3>
# <https://datatracker.ietf.org/doc/html/rfc5322#section-3.3>
#
#   [DDD,] D MMM YYYY hh:mm[:ss] (±hhmm|UT|UTC|GMT|ZONE)
#
my $RFC2822_Rx = qr{
  (?(DEFINE)
    (?<DayName>        (?i: Mon|Tue|Wed|Thu|Fri|Sat|Sun))
    (?<MonthName>      (?i: Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec))
    (?<TimeZoneAbbrev> [A-Z][A-Za-z][A-Z]{1,4})
    (?<NestedComment>  \( (?: \\\( | \\\) | [^()] | (?&NestedComment) )* \) )
  )
  \A
  (?: \s* (?&DayName)[,] )?
  \s* (?<day>    [0-9]{1,2})
  \s+ (?<month>  (?&MonthName))
  \s+ (?<year>   [0-9]{4})
  \s+ (?<hour>   [0-9]{2})
  [:] (?<minute> [0-9]{2}) (?: [:](?<second> [0-9]{2}))?
  \s+
  (?:
       (?<tz_offset> [+-][0-9]{4})
    |  (?<tz_utc>    UT[C]?|GMT)
    |  (?<tz_abbrev> (?&TimeZoneAbbrev))
  )
  (?: \s+ (?&NestedComment) )?
  \z
}x;

# RFC 3339 Date and Time on the Internet: Timestamps
# <https://datatracker.ietf.org/doc/html/rfc3339#section-5.6>
#
#   YYYY-MM-DD(T|t|space)hh:mm:ss[.fraction](Z|z|±hh:mm)
#
my $RFC3339_Rx = qr{
  \A
        (?<year>   [0-9]{4})
  [-]   (?<month>  [0-9]{2})
  [-]   (?<day>    [0-9]{2})
  [Tt ] (?<hour>   [0-9]{2})
  [:]   (?<minute> [0-9]{2})
  [:]   (?<second> [0-9]{2}) (?: [.] (?<fraction> [0-9]{1,9}) )?
  (?:
       (?<tz_offset> [+-][0-9]{2}[:][0-9]{2})
    |  (?<tz_utc>    [Zz])
  )
  \z
}x;

# RFC 4287 Atom Format
# <https://datatracker.ietf.org/doc/html/rfc4287#section-3.3>
#
#   YYYY-MM-DDThh:mm:ss[.fraction](Z|±hh:mm)
#
my $RFC4287_Rx = qr{
  \A
      (?<year>   [0-9]{4})
  [-] (?<month>  [0-9]{2})
  [-] (?<day>    [0-9]{2})
  [T] (?<hour>   [0-9]{2})
  [:] (?<minute> [0-9]{2})
  [:] (?<second> [0-9]{2}) (?: [.] (?<fraction> [0-9]{1,9}) )?
  (?:
       (?<tz_offset> [+-][0-9]{2}[:][0-9]{2})
    |  (?<tz_utc>    [Z])
  )
  \z
}x;

# ISO 9075 Database Language SQL — Part 2: Foundation (SQL/Foundation)
# <https://www.iso.org/standard/76583.html>
#
#   YYYY-MM-DD
#   YYYY-MM-DD hh:mm:ss[.fraction]
#   YYYY-MM-DD hh:mm:ss[.fraction] ±hh:mm
#
my $ISO9075_Rx = qr{
  \A
      (?<year>   [0-9]{4})
  [-] (?<month>  [0-9]{2})
  [-] (?<day>    [0-9]{2})
  (?:
    [ ] (?<hour>   [0-9]{2})
    [:] (?<minute> [0-9]{2})
    [:] (?<second> [0-9]{2}) (?: [.] (?<fraction> [0-9]{1,9}) )?
    (?:
      [ ] (?<tz_offset> [+-][0-9]{2}[:][0-9]{2})
    )?
  )?
  \z
}x;

# Common Log Format
# <https://httpd.apache.org/docs/2.4/logs.html#accesslog>
# <https://httpd.apache.org/docs/2.4/mod/mod_log_config.html#formats>
#
#   DD/MMM/YYYY:hh:mm:ss[.fraction] ±hhmm
#
my $CommonLogFormat_Rx = qr{
  (?(DEFINE)
    (?<MonthName> (?: Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec))
  )
  \A
      (?<day>       [0-9]{2})
  [/] (?<month>     (?&MonthName))
  [/] (?<year>      [0-9]{4})
  [:] (?<hour>      [0-9]{2})
  [:] (?<minute>    [0-9]{2})
  [:] (?<second>    [0-9]{2}) (?: [.] (?<fraction> [0-9]{1,9}) )?
  [ ] (?<tz_offset> [+-][0-9]{4})
  \z
}x;

# ANSI/ISO C ctime
# <https://www.open-std.org/jtc1/sc22/wg14/www/project>
# <https://pubs.opengroup.org/onlinepubs/7908799/xsh/asctime.html>
#
#   DDD MMM (_D|DD) hh:mm:ss YYYY
#
my $ANSIC_Rx = qr{
  (?(DEFINE)
    (?<DayName>   (?: Mon|Tue|Wed|Thu|Fri|Sat|Sun))
    (?<MonthName> (?: Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec))
  )
  \A
  (?:
    (?&DayName)
    [ ] (?<month>  (?&MonthName))
    (?:
        (?: [ ]{2} (?<day> [0-9]{1}))
      | (?: [ ]{1} (?<day> [0-9]{2}))
    )
    [ ] (?<hour>   [0-9]{2})
    [:] (?<minute> [0-9]{2})
    [:] (?<second> [0-9]{2})
    [ ] (?<year>   [0-9]{4})
  )
  \z
}x;

# Unix Date
# <https://pubs.opengroup.org/onlinepubs/9699919799/utilities/date.html>
#
#  The date command output format.
#
#   DDD MMM (_D|DD) hh:mm:ss (±hhmm|UTC|GMT|ZONE) YYYY
#   DDD MMM (_D|DD) hh:mm:ss YYYY (±hhmm|UTC|GMT|ZONE)
#
my $UnixDate_Rx = qr{
  (?(DEFINE)
    (?<DayName>        (?: Mon|Tue|Wed|Thu|Fri|Sat|Sun))
    (?<MonthName>      (?: Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec))
    (?<TimeZoneAbbrev> [A-Z][A-Za-z][A-Z]{1,4})
  )
  \A
  (?:
    (?&DayName)
    [ ] (?<month>  (?&MonthName))
    (?:
        (?: [ ]{2} (?<day> [0-9]{1}))
      | (?: [ ]{1} (?<day> [0-9]{2}))
    )
    [ ] (?<hour>   [0-9]{2})
    [:] (?<minute> [0-9]{2})
    [:] (?<second> [0-9]{2})
    [ ]   
    (?:
        (?:
             (?<tz_offset> [+-][0-9]{4})
          |  (?<tz_utc>    UTC|GMT)
          |  (?<tz_abbrev> (?&TimeZoneAbbrev))
        )
        [ ] (?<year> [0-9]{4})
      |
            (?<year> [0-9]{4})
        [ ] 
        (?:
             (?<tz_offset> [+-][0-9]{4})
          |  (?<tz_utc>    UTC|GMT)
          |  (?<tz_abbrev> (?&TimeZoneAbbrev))
        )
    )
  )
  \z
}x;

# Git Date
# <https://git-scm.com/docs/git-log#_commit_formatting>
#
#  The default date format used by Git.
#
#   DDD MMM D hh:mm:ss YYYY ±hhmm
#
my $GitDate_Rx = qr{
  (?(DEFINE)
    (?<DayName>   (?: Mon|Tue|Wed|Thu|Fri|Sat|Sun))
    (?<MonthName> (?: Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec))
  )
  \A
  (?&DayName)
  [ ] (?<month>     (?&MonthName))
  [ ] (?<day>       [0-9]{1,2})
  [ ] (?<hour>      [0-9]{2})
  [:] (?<minute>    [0-9]{2})
  [:] (?<second>    [0-9]{2})
  [ ] (?<year>      [0-9]{4})
  [ ] (?<tz_offset> [+-][0-9]{4})
  \z
}x;

# Ruby Date
#
#  Popularized by Ruby on Rails and Twitter.
#
#   DDD MMM DD hh:mm:ss ±hhmm YYYY
#
my $RubyDate_Rx = qr{
  (?(DEFINE)
    (?<DayName>   (?: Mon|Tue|Wed|Thu|Fri|Sat|Sun))
    (?<MonthName> (?: Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec))
  )
  \A
  (?&DayName)
  [ ] (?<month>     (?&MonthName))
  [ ] (?<day>       [0-9]{2})
  [ ] (?<hour>      [0-9]{2})
  [:] (?<minute>    [0-9]{2})
  [:] (?<second>    [0-9]{2})
  [ ] (?<tz_offset> [+-][0-9]{4})
  [ ] (?<year>      [0-9]{4})
  \z
}x;

sub leap_year {
    my ($y) = @_;
    return ($y % 4 == 0 && ($y % 100 != 0 || $y % 400 == 0));
}

# 1 <= $m <= 12
sub month_days {
    my ($y, $m) = @_;
    return 29 if $m == 2 && leap_year($y);
    return (0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)[$m];
}

sub valid_ymd {
    my ($y, $m, $d) = @_;
    return ($y >= 1 && $y <= 9999)
        && ($m >= 1 && $m <= 12)
        && ($d >= 1 && ($d <= 28 || $d <= month_days($y, $m)));
}

sub valid_hm {
    my ($h, $m) = @_;
    return ($h >= 0 && $h <= 23
         && $m >= 0 && $m <= 59);
}

sub valid_hms {
    my ($h, $m, $s) = @_;
    return ($h >= 0 && $h <= 23
         && $m >= 0 && $m <= 59
         && $s >= 0 && $s <= 60);
}

sub expand_two_digit_year {
  @_ == 2 or croak q/Usage: expand_two_digit_year(yy, pivot_year)/;
  my ($yy, $pivot_year) = @_;

  ($pivot_year >= 0 && $pivot_year <= 9899)
    or croak q/Parameter 'pivot_year' is out of range (0-9899)/;

  use integer;
  my $century = $pivot_year / 100;
  my $base = $century * 100;
  my $pivot_offset = $pivot_year - $base;

  my $year = $base + $yy;
  if ($yy < $pivot_offset) {
    $year += 100;
  }
  return $year;
}

sub meridiem_to_24h {
  @_ == 2 or croak q/Usage: meridiem_to_24h(hour, meridiem)/;
  my ($hour, $meridiem) = @_;

  ($hour >= 1 && $hour <= 12)
    or croak q/Parameter 'hour' is out of range (1-12)/;

  ($meridiem eq 'AM' || $meridiem eq 'PM')
    or croak q/Parameter 'meridiem' is not AM or PM/;

  return $meridiem eq 'AM' ? ($hour == 12 ? 0  : $hour)
                           : ($hour == 12 ? 12 : $hour + 12);
}

sub parse_numeric_offset {
  @_ == 1 or croak q/Usage: parse_numeric_offset(string)/;
  my ($string) = @_;

  $string =~ s/://; # ±H ±HH ±H:MM ±HH:MM ±HHMM
  my ($sign, $h, $m) = ($string =~ m/^([+-])([0-9]{1,2})([0-9]{2})?$/)
    or croak q/Unable to parse: timezone offset is invalid/;

  $m //= 0;
  valid_hm($h, $m)
    or croak qq/Unable to parse: timezone offset is out of range ($string)/;

  my $offset = $h * 60 + $m;
  if ($sign eq '-') {
    $offset *= -1;
  }

  return $offset;
}

my %RegexpMap = (
  ansic    => $ANSIC_Rx,
  asn1gt   => $ASN1GT_Rx,
  asn1ut   => $ASN1UT_Rx,
  atom     => $RFC4287_Rx,
  clf      => $CommonLogFormat_Rx,
  ctime    => $ANSIC_Rx,
  email    => $RFC2822_Rx,
  generic  => $GenericDateTime_Rx,
  git      => $GitDate_Rx,
  http     => $RFC2616_Rx,
  imf      => $RFC2822_Rx,
  iso9075  => $ISO9075_Rx,
  rfc2616  => $RFC2616_Rx,
  rfc2822  => $RFC2822_Rx,
  rfc3339  => $RFC3339_Rx,
  rfc4287  => $RFC4287_Rx,
  rfc5322  => $RFC2822_Rx,
  rfc7231  => $RFC2616_Rx,
  ruby     => $RubyDate_Rx,
  sql      => $ISO9075_Rx,
  unix     => $UnixDate_Rx,
  w3c      => $W3CDTF_Rx,
  w3cdtf   => $W3CDTF_Rx,
);

sub str2date {
  @_ & 1 or croak q/Usage: str2date(string [, format => 'RFC3339' ])/;
  my ($string, %p) = @_;

  my $format     = 'rfc3339';
  my $pivot_year = $DefaultPivotYear;
  my $regexp     = $RFC3339_Rx;

  if (exists $p{format}) {
    $format = lc delete $p{format};
    $regexp = $RegexpMap{$format};

    (defined $regexp)
      or croak qq/Parameter 'format' is unknown: '$format'/;
  }

  if (exists $p{pivot_year}) {
    $pivot_year = delete $p{pivot_year};

    ($pivot_year >= 0 && $pivot_year <= 9899)
      or croak q/Parameter 'pivot_year' is out of range (0-9899)/;
  }

  if (%p) {
    croak "Unknown named parameter: " . join ', ', sort keys %p;
  }

  (defined $string && $string =~ $regexp)
    or croak qq/Unable to parse: string does not match the $format format/;

  my %r = %+;

  if (exists $r{month} && $r{month} !~ /^[0-9]/) {
    $r{month} = $MonthIndexMap{ lc $r{month} };
  }

  if (exists $r{year}) {

    if (length $r{year} == 2) {
      $r{year} = expand_two_digit_year($r{year}, $pivot_year);
    }

    valid_ymd($r{year}, $r{month} // 1, $r{day} // 1)
      or croak q/Unable to parse: date is out of range/;
  }

  if (exists $r{hour}) {

    if (exists $r{meridiem}) {
      ($r{hour} >= 1 && $r{hour} <= 12)
        or croak q/Unable to parse: hour is out of range for 12-hour clock/;

      $r{hour} = meridiem_to_24h($r{hour}, $MeridiemMap{ lc delete $r{meridiem} });
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
      $r{tz_offset} = parse_numeric_offset($r{tz_offset});
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

  my $precision = DEFAULT_PRECISION;

  if (exists $p{precision}) {
    $precision = delete $p{precision};
    ($precision >= 0 && $precision <= 9)
      or croak(q/Parameter 'precision' is out of range (0-9)/);
  }

  my $r = str2date($string, %p);

  (exists $r->{tz_offset})
    or croak q/Unable to convert to time: no timezone offset or UTC designator/;

  my ($Y, $M, $D, $h, $m, $s) = @$r{qw(year month day hour minute second)};
  $m //= 0;
  $s //= 0;

  my $rdn = do {
    use integer;
    if ($M < 3) {
      $Y--, $M += 12;
    }
    (1461 * $Y) / 4 - $Y / 100 + $Y / 400
      + $D + ((979 * $M - 2918) >> 5) - 306;
  };
  my $sod  = ($h * 60 + $m) * 60 + $s;
  my $time = ($rdn - 719163) * 86400 + $sod - $r->{tz_offset} * 60;
  if (exists $r->{nanosecond}) {
    my $scale    = 10 ** $precision;
    my $fraction = int($r->{nanosecond} * $scale / 1E9);
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

  sub format_RFC3339 {
    my ($time, $offset, $fraction) = @_;

    $time += $offset * 60;
    my ($sec, $min, $hour, $mday, $mon, $year) = gmtime $time;
    my $zstr = format_offset_extended($offset, 'Z');
    return sprintf '%04d-%02d-%02dT%02d:%02d:%02d%s%s',
      $year + 1900, $mon + 1, $mday, $hour, $min, $sec, $fraction, $zstr;
  }

  sub format_ISO9075 {
    my ($time, $offset, $fraction) = @_;

    $time += $offset * 60;
    my ($sec, $min, $hour, $mday, $mon, $year) = gmtime $time;
    my $zstr = format_offset_extended($offset, '+00:00');
    return sprintf '%04d-%02d-%02d %02d:%02d:%02d%s %s',
      $year + 1900, $mon + 1, $mday, $hour, $min, $sec, $fraction, $zstr;
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
  ansic    => \&format_ANSIC,
  asn1gt   => \&format_ASN1GT,
  asn1ut   => \&format_ASN1UT,
  atom     => \&format_RFC3339,
  clf      => \&format_CLF,
  ctime    => \&format_ANSIC,
  email    => \&format_RFC2822,
  git      => \&format_GitDate,
  http     => \&format_RFC2616,
  imf      => \&format_RFC2822,
  iso9075  => \&format_ISO9075,
  rfc2616  => \&format_RFC2616,
  rfc2822  => \&format_RFC2822,
  rfc3339  => \&format_RFC3339,
  rfc4287  => \&format_RFC3339,
  rfc5322  => \&format_RFC2822,
  rfc7231  => \&format_RFC2616,
  ruby     => \&format_RubyDate,
  sql      => \&format_ISO9075,
  unix     => \&format_UnixDate,
  w3c      => \&format_RFC3339,
  w3cdtf   => \&format_RFC3339,
);

sub time2str {
  @_ & 1 or croak(q/Usage: time2str(time [, format => 'RFC3339' ])/);
  my ($time, %p) = @_;

  ($time >= MIN_TIME && $time < MAX_TIME + 1)
    or croak(q/Parameter 'time' is out of range (0001-01-01T00:00:00Z to 9999-12-31T23:59:59Z)/);

  my $formatter = \&format_RFC3339;

  if (exists $p{format}) {
    my $format =  delete $p{format};

    $formatter = $FormatMap{ lc $format };
    (defined $formatter)
      or croak(qq/Parameter 'format' is unknown: '$format'/);
  }

  my ($offset, $precision, $nanosecond) = (0);

  if (exists $p{offset}) {
    $offset = delete $p{offset};
    ($offset >= -1439 && $offset <= 1439)
      or croak(q/Parameter 'offset' is out of range (-1439 to 1439)/);
  }

  if (exists $p{precision}) {
    $precision = delete $p{precision};
    ($precision >= 0 && $precision <= 9)
      or croak(q/Parameter 'precision' is out of range (0-9)/);
  }

  if (exists $p{nanosecond}) {
    $nanosecond = delete $p{nanosecond};
    ($nanosecond >= 0 && $nanosecond <= 999_999_999)
      or croak(q/Parameter 'nanosecond' is out of range (0-999999999)/);
  }

  if (%p) {
    croak "Unknown named parameter: " . join ', ', sort keys %p;
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

    ($local_time >= MIN_TIME && $local_time <= MAX_TIME)
      or croak(q/Parameter 'time' is out of range for the given offset/);
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
