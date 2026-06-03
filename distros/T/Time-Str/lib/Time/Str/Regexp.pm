package Time::Str::Regexp;
use strict;
use warnings;
use v5.10.1;

our $VERSION   = '0.89';
our @EXPORT_OK = qw[ $ANSIC_Rx
                     $ASN1GT_Rx
                     $ASN1UT_Rx
                     $CLF_Rx
                     $DateTime_Rx
                     $ECMAScript_Rx
                     $GitDate_Rx
                     $ISO8601_Rx
                     $ISO9075_Rx
                     $RFC2616_Rx
                     $RFC2822_Rx
                     $RFC2822FWS_Rx
                     $RFC3339_Rx
                     $RFC3501_Rx
                     $RFC4287_Rx
                     $RFC5280_Rx
                     $RFC5545_Rx
                     $RFC9557_Rx
                     $RubyDate_Rx
                     $UnixDate_Rx
                     $UnixStamp_Rx
                     $W3CDTF_Rx ];

use Exporter qw[import];

# DateTime
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
our $DateTime_Rx = qr{
  (?(DEFINE)
    (?<DayNameShort>      (?i: Mon|Tue|Tues|Wed|Thu|Thurs|Fri|Sat|Sun))
    (?<DayNameLong>       (?i: Monday|Tuesday|Wednesday|Thursday|Friday|
                               Saturday|Sunday))
    (?<DayName>           (?&DayNameShort) | (?&DayNameLong))
    (?<MonthNameShort>    (?i: Jan|Feb|Mar|Apr|May|Jun|Jul|
                               Aug|Sep|Sept|Oct|Nov|Dec))
    (?<MonthNameLong>     (?i: January|February|March|April|May|June|
                               July|August|September|October|November|December))
    (?<MonthName>         (?&MonthNameShort) | (?&MonthNameLong))
    (?<MonthRoman>        (?i: I|II|III|IV|V|VI|VII|VIII|IX|X|XI|XII))
    (?<MonthTextual>      (?&MonthName) | (?&MonthRoman))
    (?<OrdinalSuffix>     (?i: st|nd|rd|th))
    (?<Meridiem>          (?: [AaPp] (?: [Mm] | [.][Mm][.])))
    (?<TimeZoneOffset>    (?: [+-] (?: [0-9]{4} | [0-9]{2}   (?: [:][0-9]{2})? )))
    (?<TimeZoneOffsetUTC> (?: [+-] (?: [0-9]{4} | [0-9]{1,2} (?: [:][0-9]{2})? )))
    (?<TimeZoneAbbrev>    [A-Z][A-Za-z][A-Z]{1,4})
  )

  \A

  (?: (?<day_name> (?&DayName)) [.]?[,]? [ ] )?

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
               (?<day>   [0-9]{1,2} (?&OrdinalSuffix)?) [.]?
           [ ] (?<month> (?&MonthTextual)) [.,]?
           [ ] (?<year>  [0-9]{4})
        |
               (?<month> (?&MonthName)) [.,]?
           [ ] (?<day>   [0-9]{1,2} (?&OrdinalSuffix)?) [,]?
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
    # could be misinterpreted as hour-minute notation.

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
        |  (?<tz_utc>    (?:GMT|UTC)) (?: (?<tz_offset> (?&TimeZoneOffsetUTC)) )?
        |  (?<tz_utc>    [Zz])
        |  (?<tz_abbrev> (?&TimeZoneAbbrev))
      )

      # RFC 9557 (IXDTF) annotation tag, e.g. [Europe/Paris]
      (?:
        (?<tz_annotation> (?: \[ [^\[\]]+ \] )+ )
      )?

      # Parenthesized comment, e.g. (Central European Time)
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
our $ASN1GT_Rx = qr{
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
our $ASN1UT_Rx = qr{
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
our $W3CDTF_Rx = qr{
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
our $RFC2616_Rx = qr{
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
          (?<day_name> (?&DayNameShort)) [,]
      [ ] (?<day>      [0-9]{2})
      [ ] (?<month>    (?&MonthNameShort))
      [ ] (?<year>     [0-9]{4})
      [ ] (?<hour>     [0-9]{2})
      [:] (?<minute>   [0-9]{2})
      [:] (?<second>   [0-9]{2})
      [ ] (?<tz_utc>   GMT)
    )
  | # RFC 850
    (?:
          (?<day_name> (?&DayNameLong)) [,]
      [ ] (?<day>      [0-9]{2})
      [-] (?<month>    (?&MonthNameShort))
      [-] (?<year>     [0-9]{2})
      [ ] (?<hour>     [0-9]{2})
      [:] (?<minute>   [0-9]{2})
      [:] (?<second>   [0-9]{2})
      [ ] (?<tz_utc>   GMT)
    )
  | # ANSI C's ctime
    (?:
          (?<day_name> (?&DayNameShort))
      [ ] (?<month>    (?&MonthNameShort))
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

# RFC 2822 Internet Message Format (canonical)
# <https://datatracker.ietf.org/doc/html/rfc2822#section-3.3>
# <https://datatracker.ietf.org/doc/html/rfc5322#section-3.3>
#
#   [DDD,] D MMM YYYY hh:mm[:ss] (±hhmm|UT|UTC|GMT|ZONE) [(comment)]
#
our $RFC2822_Rx = qr{
  (?(DEFINE)
    (?<DayName>        (?i: Mon|Tue|Wed|Thu|Fri|Sat|Sun))
    (?<MonthName>      (?i: Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec))
    (?<TimeZoneAbbrev> [A-Z][A-Za-z][A-Z]{1,4})
  )
  \A
  (?: (?<day_name> (?&DayName))[,][ ] )?
      (?<day>      [0-9]{1,2})
  [ ] (?<month>    (?&MonthName))
  [ ] (?<year>     [0-9]{4})
  [ ] (?<hour>     [0-9]{2})
  [:] (?<minute>   [0-9]{2}) (?: [:](?<second> [0-9]{2}))?
  [ ]
  (?:
       (?<tz_offset> [+-][0-9]{4})
    |  (?<tz_utc>    UT[C]?|GMT)
    |  (?<tz_abbrev> (?&TimeZoneAbbrev))
  )
  (?: [ ] \( [^()]+ \) )?
  \z
}x;

# RFC 2822 Internet Message Format (with folding white space and nested comments)
#
#   [DDD,] D MMM YYYY hh:mm[:ss] (±hhmm|UT|UTC|GMT|ZONE) [(comment)]
#
our $RFC2822FWS_Rx = qr{
  (?(DEFINE)
    (?<DayName>        (?i: Mon|Tue|Wed|Thu|Fri|Sat|Sun))
    (?<MonthName>      (?i: Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec))
    (?<TimeZoneAbbrev> [A-Z][A-Za-z][A-Z]{1,4})
    (?<NestedComment>  \( (?: \\\( | \\\) | [^()] | (?&NestedComment) )* \) )
  )
  \A
  (?: \s* (?<day_name> (?&DayName))[,] )?
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

# RFC 3501 Internet Message Access Protocol (IMAP)
# <https://datatracker.ietf.org/doc/html/rfc3501#section-2.3.3>
# <https://datatracker.ietf.org/doc/html/rfc9051#section-2.3.3>
#
#   DD-MMM-YYYY hh:mm:ss ±hhmm
#
our $RFC3501_Rx = qr{
  (?(DEFINE)
    (?<MonthName> (?i: Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec))
  )
  \A
      (?<day>       [0-9]{2})
  [-] (?<month>     (?&MonthName))
  [-] (?<year>      [0-9]{4})
  [ ] (?<hour>      [0-9]{2})
  [:] (?<minute>    [0-9]{2})
  [:] (?<second>    [0-9]{2})
  [ ] (?<tz_offset> [+-][0-9]{4})
  \z
}x;

# RFC 3339 Date and Time on the Internet: Timestamps
# <https://datatracker.ietf.org/doc/html/rfc3339#section-5.6>
#
#   YYYY-MM-DD(T|t|space)hh:mm:ss[.fraction](Z|z|±hh:mm)
#
our $RFC3339_Rx = qr{
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

# RFC 9557 Date and Time on the Internet: Timestamps with Additional Information
# <https://datatracker.ietf.org/doc/html/rfc9557>
#
#   YYYY-MM-DD(T|t|space)hh:mm:ss[.fraction](Z|z|±hh:mm)[TAGS]
#
our $RFC9557_Rx = qr{
  (?(DEFINE)
    (?<Tag> \[ [0-9A-Za-z!+-._/]+ \])
  )
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
  (?:
    (?<tz_annotation> (?&Tag)+ )
  )?
  \z
}x;

# RFC 4287 Atom Format
# <https://datatracker.ietf.org/doc/html/rfc4287#section-3.3>
#
#   YYYY-MM-DDThh:mm:ss[.fraction](Z|±hh:mm)
#
our $RFC4287_Rx = qr{
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

# RFC 5280 PKIX Certificate and CRL Profile (x509)
# <https://datatracker.ietf.org/doc/html/rfc5280#section-4.1.2.5>
#
#   YYMMDDhhmmzzZ
#   YYYYMMDDhhmmssZ
#
our $RFC5280_Rx = qr{
  \A
  (?<year>   [0-9]{2}|[0-9]{4})
  (?<month>  [0-9]{2})
  (?<day>    [0-9]{2}) 
  (?<hour>   [0-9]{2})
  (?<minute> [0-9]{2})
  (?<second> [0-9]{2})
  (?<tz_utc> [Z])
  \z
}x;

# RFC 5545 iCalendar
# <https://datatracker.ietf.org/doc/html/rfc5545#section-3.3.4>
# <https://datatracker.ietf.org/doc/html/rfc5545#section-3.3.5>
#
#   YYYYMMDD
#   YYYYMMDDThhmmss[Z]
#
our $RFC5545_Rx = qr{
  \A
  (?<year>   [0-9]{4})
  (?<month>  [0-9]{2})
  (?<day>    [0-9]{2})
  (?:
    [T] 
    (?<hour>   [0-9]{2})
    (?<minute> [0-9]{2})
    (?<second> [0-9]{2})
    (?<tz_utc> [Z])?
  )?
  \z
}x;

# ISO 8601
# <https://www.iso.org/obp/ui/#iso:std:iso:8601>
#
#  Calendar date with optional time of day, a profile of ISO 8601.
#
#   YYYY-MM-DD
#   YYYY-MM-DDThh[:mm[:ss]][(.|,)fraction][Z|±hh[:mm]]
#   YYYYMMDD
#   YYYYMMDDThh[mm[ss]][(.|,)fraction][Z|±hh[mm]]
#
our $ISO8601_Rx = qr{
  \A

  (?<year> [0-9]{4})

  (?: # Extended format
     (?:
           [-] (?<month>  [0-9]{2})
           [-] (?<day>    [0-9]{2})
       (?: [T] (?<hour>   [0-9]{2}) (?: [:] (?<minute> [0-9]{2})
                                    (?: [:] (?<second> [0-9]{2}))?)?

         (?: [.,] (?<fraction> [0-9]{1,9}))?

         (?:
              (?<tz_offset> [+-][0-9]{2} (?: [:][0-9]{2})? )
           |  (?<tz_utc>    [Z])
         )?
       )?
     )
   | # Basic format
     (?:
               (?<month>  [0-9]{2})
               (?<day>    [0-9]{2})
       (?: [T] (?<hour>   [0-9]{2}) (?: (?<minute> [0-9]{2})
                                    (?: (?<second> [0-9]{2}))?)?

         (?: [.,] (?<fraction> [0-9]{1,9}))?

         (?:
              (?<tz_offset> [+-][0-9]{2} (?: [0-9]{2})? )
           |  (?<tz_utc>    [Z])
         )?
       )?
     )
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
our $ISO9075_Rx = qr{
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

# ECMAScript Date.prototype.toString
# <https://tc39.es/ecma262/multipage/numbers-and-dates.html#sec-date.prototype.tostring>
#
#   DDD MMM DD YYYY hh:mm:ss [GMT|UTC]±hhmm [comment]
#
our $ECMAScript_Rx = qr{
  (?(DEFINE)
    (?<DayName>   (?: Mon|Tue|Wed|Thu|Fri|Sat|Sun))
    (?<MonthName> (?: Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec))
  )
  \A
      (?<day_name> (?&DayName))
  [ ] (?<month>    (?&MonthName))
  [ ] (?<day>      [0-9]{2})
  [ ] (?<year>     [0-9]{4})
  [ ] (?<hour>     [0-9]{2})
  [:] (?<minute>   [0-9]{2})
  [:] (?<second>   [0-9]{2})
  [ ] (?<tz_utc>   UTC|GMT)? (?<tz_offset> [+-][0-9]{4})
  (?:
    [ ] (?: \( [^()]+ \) )
  )?
  \z
}x;

# Common Log Format
# <https://httpd.apache.org/docs/2.4/logs.html#accesslog>
# <https://httpd.apache.org/docs/2.4/mod/mod_log_config.html#formats>
#
#   DD/MMM/YYYY:hh:mm:ss[.fraction] ±hhmm
#
our $CLF_Rx = qr{
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
our $ANSIC_Rx = qr{
  (?(DEFINE)
    (?<DayName>   (?: Mon|Tue|Wed|Thu|Fri|Sat|Sun))
    (?<MonthName> (?: Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec))
  )
  \A
  (?:
        (?<day_name> (?&DayName))
    [ ] (?<month>    (?&MonthName))
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

# Git Date
# <https://git-scm.com/docs/git-log#_commit_formatting>
#
#  The default date format used by Git.
#
#   DDD MMM D hh:mm:ss YYYY ±hhmm
#
our $GitDate_Rx = qr{
  (?(DEFINE)
    (?<DayName>   (?: Mon|Tue|Wed|Thu|Fri|Sat|Sun))
    (?<MonthName> (?: Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec))
  )
  \A
      (?<day_name>  (?&DayName))
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
our $RubyDate_Rx = qr{
  (?(DEFINE)
    (?<DayName>   (?: Mon|Tue|Wed|Thu|Fri|Sat|Sun))
    (?<MonthName> (?: Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec))
  )
  \A
      (?<day_name>  (?&DayName))
  [ ] (?<month>     (?&MonthName))
  [ ] (?<day>       [0-9]{2})
  [ ] (?<hour>      [0-9]{2})
  [:] (?<minute>    [0-9]{2})
  [:] (?<second>    [0-9]{2})
  [ ] (?<tz_offset> [+-][0-9]{4})
  [ ] (?<year>      [0-9]{4})
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
our $UnixDate_Rx = qr{
  (?(DEFINE)
    (?<DayName>        (?: Mon|Tue|Wed|Thu|Fri|Sat|Sun))
    (?<MonthName>      (?: Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec))
    (?<TimeZoneAbbrev> [A-Z][A-Za-z][A-Z]{1,4})
    (?<TimeZoneOffset> [+-][0-9]{4})
  )
  \A
  (?:
        (?<day_name> (?&DayName))
    [ ] (?<month>    (?&MonthName))
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
             (?<tz_offset> (?&TimeZoneOffset))
          |  (?<tz_utc>    UTC|GMT)
          |  (?<tz_abbrev> (?&TimeZoneAbbrev))
        )
        [ ] (?<year> [0-9]{4})
      |
            (?<year> [0-9]{4})
        [ ] 
        (?:
             (?<tz_offset> (?&TimeZoneOffset))
          |  (?<tz_utc>    UTC|GMT)
          |  (?<tz_abbrev> (?&TimeZoneAbbrev))
        )
    )
  )
  \z
}x;

# UnixStamp
#
#  Unix date based format with optional fractional seconds and timezone
#
#   [DDD ]MMM (_D|D|DD) hh:mm[:ss[.fraction]] [±hhmm|UTC|GMT|ZONE] YYYY
#   [DDD ]MMM (_D|D|DD) hh:mm[:ss[.fraction]] YYYY [±hhmm|UTC|GMT|ZONE]
#
our $UnixStamp_Rx = qr{
  (?(DEFINE)
    (?<DayName>        (?: Mon|Tue|Wed|Thu|Fri|Sat|Sun))
    (?<MonthName>      (?: Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec))
    (?<TimeZoneAbbrev> [A-Z][A-Za-z][A-Z]{1,4})
    (?<TimeZoneOffset> [+-][0-9]{4})
  )
  \A
  (?:
    (?: (?<day_name> (?&DayName)) [ ] )?
        (?<month>  (?&MonthName))
    (?:
        (?: [ ]{2} (?<day> [0-9]{1}))
      | (?: [ ]{1} (?<day> [0-9]{1,2}))
    )
    [ ] (?<hour>   [0-9]{2})
    [:] (?<minute> [0-9]{2}) (?: [:] (?<second>   [0-9]{2})
                             (?: [.] (?<fraction> [0-9]{1,9}) )?)?
    [ ]
    (?:
        (?:
             (?<tz_offset> (?&TimeZoneOffset))
          |  (?<tz_utc>    UTC|GMT) (?: (?<tz_offset> (?&TimeZoneOffset)) )?
          |  (?<tz_abbrev> (?&TimeZoneAbbrev))
        )
        [ ] (?<year> [0-9]{4})
      |
            (?<year> [0-9]{4})
        (?:
          [ ]
          (?:
               (?<tz_offset> (?&TimeZoneOffset))
            |  (?<tz_utc>    UTC|GMT) (?: (?<tz_offset> (?&TimeZoneOffset)) )?
            |  (?<tz_abbrev> (?&TimeZoneAbbrev))
          )?
        )?
    )
  )
  \z
}x;

my %RegexpMap = (
  ansic      => $ANSIC_Rx,
  asn1gt     => $ASN1GT_Rx,
  asn1ut     => $ASN1UT_Rx,
  clf        => $CLF_Rx,
  datetime   => $DateTime_Rx,
  ecmascript => $ECMAScript_Rx,
  gitdate    => $GitDate_Rx,
  iso8601    => $ISO8601_Rx,
  iso9075    => $ISO9075_Rx,
  rfc2616    => $RFC2616_Rx,
  rfc2822    => $RFC2822_Rx,
  rfc2822fws => $RFC2822FWS_Rx,
  rfc3339    => $RFC3339_Rx,
  rfc3501    => $RFC3501_Rx,
  rfc4287    => $RFC4287_Rx,
  rfc5280    => $RFC5280_Rx,
  rfc5545    => $RFC5545_Rx,
  rfc9557    => $RFC9557_Rx,
  rubydate   => $RubyDate_Rx,
  unixdate   => $UnixDate_Rx,
  unixstamp  => $UnixStamp_Rx,
  w3cdtf     => $W3CDTF_Rx,
);

sub mapping {
  return wantarray ? %RegexpMap : { %RegexpMap };
}

1;
