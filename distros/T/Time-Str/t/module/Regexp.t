#!perl
use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok('Time::Str::Regexp', qw[ $ANSIC_Rx
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
                                  $W3CDTF_Rx ]);
}

sub captures {
  my ($string, $rx) = @_;
  if ($string =~ $rx) {
    return { %+ };
  }
  return undef;
}

# RFC 3339

{
  my $c = captures('2012-12-24T15:30:45Z', $RFC3339_Rx);
  ok($c, 'RFC3339: basic Z');
  is($c->{year},   '2012', 'RFC3339: year');
  is($c->{month},  '12',   'RFC3339: month');
  is($c->{day},    '24',   'RFC3339: day');
  is($c->{hour},   '15',   'RFC3339: hour');
  is($c->{minute}, '30',   'RFC3339: minute');
  is($c->{second}, '45',   'RFC3339: second');
  is($c->{tz_utc}, 'Z',    'RFC3339: tz_utc');

  $c = captures('2012-12-24T15:30:45.123Z', $RFC3339_Rx);
  is($c->{fraction}, '123', 'RFC3339: fraction');

  $c = captures('2012-12-24T15:30:45+01:00', $RFC3339_Rx);
  is($c->{tz_offset}, '+01:00', 'RFC3339: positive offset');
  ok(!exists $c->{tz_utc}, 'RFC3339: no tz_utc with offset');

  $c = captures('2012-12-24T15:30:45-05:30', $RFC3339_Rx);
  is($c->{tz_offset}, '-05:30', 'RFC3339: negative offset');

  $c = captures('2012-12-24t15:30:45z', $RFC3339_Rx);
  ok($c, 'RFC3339: lowercase t and z');

  $c = captures('2012-12-24 15:30:45Z', $RFC3339_Rx);
  ok($c, 'RFC3339: space separator');

  ok(!captures('2012-12-24',  $RFC3339_Rx), 'RFC3339: date only rejects');
  ok(!captures('not-a-date',  $RFC3339_Rx), 'RFC3339: garbage rejects');
  ok(!captures('',            $RFC3339_Rx), 'RFC3339: empty string rejects');
}

# RFC 9557

{
  my $c = captures('2012-12-24T15:30:45Z[Europe/Stockholm]', $RFC9557_Rx);
  ok($c, 'RFC9557: with annotation');
  is($c->{tz_annotation}, '[Europe/Stockholm]', 'RFC9557: tz_annotation');

  $c = captures('2012-12-24T15:30:45+01:00[Europe/Stockholm][u-ca-gregory]', $RFC9557_Rx);
  ok($c, 'RFC9557: multiple annotations');
  is($c->{tz_annotation}, '[Europe/Stockholm][u-ca-gregory]', 'RFC9557: multiple tz_annotation');

  ok(!captures('2012-12-24T15:30:45Z[]', $RFC9557_Rx), 'RFC9557: empty annotation rejects');
}

# RFC 2822

{
  my $c = captures('Mon, 24 Dec 2012 15:30:45 +0100', $RFC2822_Rx);
  ok($c, 'RFC2822: full');
  is($c->{day_name},  'Mon',   'RFC2822: day_name');
  is($c->{day},       '24',    'RFC2822: day');
  is($c->{month},     'Dec',   'RFC2822: month');
  is($c->{year},      '2012',  'RFC2822: year');
  is($c->{tz_offset}, '+0100', 'RFC2822: tz_offset');

  $c = captures('24 Dec 2012 15:30:45 +0100', $RFC2822_Rx);
  ok($c, 'RFC2822: without day name');

  $c = captures('24 Dec 2012 15:30 +0100', $RFC2822_Rx);
  ok($c, 'RFC2822: without second');
  ok(!exists $c->{second}, 'RFC2822: second not captured');

  $c = captures('Mon, 24 Dec 2012 15:30:45 GMT', $RFC2822_Rx);
  is($c->{tz_utc}, 'GMT', 'RFC2822: tz_utc GMT');

  $c = captures('Mon, 24 Dec 2012 15:30:45 UTC', $RFC2822_Rx);
  is($c->{tz_utc}, 'UTC', 'RFC2822: tz_utc UTC');

  $c = captures('Mon, 24 Dec 2012 15:30:45 UT', $RFC2822_Rx);
  is($c->{tz_utc}, 'UT', 'RFC2822: tz_utc UT');

  $c = captures('Mon, 24 Dec 2012 15:30:45 CET', $RFC2822_Rx);
  is($c->{tz_abbrev}, 'CET', 'RFC2822: tz_abbrev');

  $c = captures('Mon, 24 Dec 2012 15:30:45 +0100 (CET)', $RFC2822_Rx);
  ok($c, 'RFC2822: with comment');
}

# RFC 2822 FWS

{
  my $c = captures("  Mon,  24  Dec  2012  15:30:45  +0100", $RFC2822FWS_Rx);
  ok($c, 'RFC2822FWS: folding white space');
  is($c->{day_name}, 'Mon', 'RFC2822FWS: day_name');

  $c = captures("Mon, 24 Dec 2012 15:30:45 +0100 (nested (comment))", $RFC2822FWS_Rx);
  ok($c, 'RFC2822FWS: nested comment');
}

# RFC 2616

{
  my $c = captures('Mon, 24 Dec 2012 15:30:45 GMT', $RFC2616_Rx);
  ok($c, 'RFC2616: IMF-fixdate');
  is($c->{day_name}, 'Mon',  'RFC2616: day_name');
  is($c->{tz_utc},   'GMT',  'RFC2616: tz_utc');

  $c = captures('Monday, 24-Dec-12 15:30:45 GMT', $RFC2616_Rx);
  ok($c, 'RFC2616: RFC 850');
  is($c->{day_name}, 'Monday', 'RFC2616: RFC 850 day_name');
  is($c->{year},     '12',     'RFC2616: RFC 850 two-digit year');

  $c = captures('Mon Dec 24 15:30:45 2012', $RFC2616_Rx);
  ok($c, 'RFC2616: ANSI C ctime');
  ok(!exists $c->{tz_utc}, 'RFC2616: ctime has no tz_utc');

  $c = captures('Sun Nov  6 08:49:37 1994', $RFC2616_Rx);
  ok($c, 'RFC2616: ctime single-digit day');
  is($c->{day}, '6', 'RFC2616: ctime single-digit day value');
}

# RFC 4287

{
  my $c = captures('2012-12-24T15:30:45Z', $RFC4287_Rx);
  ok($c, 'RFC4287: basic');
  is($c->{year}, '2012', 'RFC4287: year');

  $c = captures('2012-12-24T15:30:45.500+01:00', $RFC4287_Rx);
  ok($c, 'RFC4287: with fraction and offset');
  is($c->{fraction}, '500', 'RFC4287: fraction');

  ok(!captures('2012-12-24t15:30:45Z', $RFC4287_Rx), 'RFC4287: lowercase T rejects');
}

# RFC 3501

{
  my $c = captures('24-Dec-2012 15:30:45 +0100', $RFC3501_Rx);
  ok($c, 'RFC3501: basic');
  is($c->{day},       '24',    'RFC3501: day');
  is($c->{month},     'Dec',   'RFC3501: month');
  is($c->{tz_offset}, '+0100', 'RFC3501: tz_offset');
}

# RFC 5280

{
  my $c = captures('121224153045Z', $RFC5280_Rx);
  ok($c, 'RFC5280: UTCTime');
  is($c->{year},   '12',  'RFC5280: two-digit year');
  is($c->{tz_utc}, 'Z',   'RFC5280: tz_utc');

  $c = captures('20121224153045Z', $RFC5280_Rx);
  ok($c, 'RFC5280: GeneralizedTime');
  is($c->{year}, '2012', 'RFC5280: four-digit year');
}

# RFC 5545

{
  my $c = captures('20121224T153045Z', $RFC5545_Rx);
  ok($c, 'RFC5545: with time and Z');
  is($c->{year}, '2012', 'RFC5545: year');
  is($c->{tz_utc}, 'Z',  'RFC5545: tz_utc');

  $c = captures('20121224T153045', $RFC5545_Rx);
  ok($c, 'RFC5545: with time without Z');
  ok(!exists $c->{tz_utc}, 'RFC5545: no tz_utc');

  $c = captures('20121224', $RFC5545_Rx);
  ok($c, 'RFC5545: date only');
  ok(!exists $c->{hour}, 'RFC5545: no hour in date-only');
}

# ISO 8601

{
  my $c = captures('2012-12-24', $ISO8601_Rx);
  ok($c, 'ISO8601: date only');
  is($c->{year},  '2012', 'ISO8601: year');
  is($c->{month}, '12',   'ISO8601: month');
  is($c->{day},   '24',   'ISO8601: day');

  $c = captures('2012-12-24T15:30:45Z', $ISO8601_Rx);
  ok($c, 'ISO8601: extended with Z');
  is($c->{tz_utc}, 'Z', 'ISO8601: tz_utc');

  $c = captures('2012-12-24T15:30:45+01:00', $ISO8601_Rx);
  is($c->{tz_offset}, '+01:00', 'ISO8601: extended offset');

  $c = captures('2012-12-24T15', $ISO8601_Rx);
  ok($c, 'ISO8601: hour only');
  is($c->{hour}, '15', 'ISO8601: hour');
  ok(!exists $c->{minute}, 'ISO8601: no minute');

  $c = captures('2012-12-24T15:30', $ISO8601_Rx);
  ok($c, 'ISO8601: hour and minute');

  $c = captures('2012-12-24T15:30:45,500Z', $ISO8601_Rx);
  is($c->{fraction}, '500', 'ISO8601: comma fraction');

  $c = captures('20121224', $ISO8601_Rx);
  ok($c, 'ISO8601: basic date');

  $c = captures('20121224T153045Z', $ISO8601_Rx);
  ok($c, 'ISO8601: basic with time');

  $c = captures('20121224T153045+0100', $ISO8601_Rx);
  is($c->{tz_offset}, '+0100', 'ISO8601: basic offset');
}

# ISO 9075

{
  my $c = captures('2012-12-24', $ISO9075_Rx);
  ok($c, 'ISO9075: date only');

  $c = captures('2012-12-24 15:30:45', $ISO9075_Rx);
  ok($c, 'ISO9075: without offset');
  ok(!exists $c->{tz_offset}, 'ISO9075: no tz_offset');

  $c = captures('2012-12-24 15:30:45.500', $ISO9075_Rx);
  is($c->{fraction}, '500', 'ISO9075: fraction');

  $c = captures('2012-12-24 15:30:45 +01:00', $ISO9075_Rx);
  is($c->{tz_offset}, '+01:00', 'ISO9075: offset');
}

# W3CDTF

{
  my $c = captures('2012', $W3CDTF_Rx);
  ok($c, 'W3CDTF: year only');
  is($c->{year}, '2012', 'W3CDTF: year');
  ok(!exists $c->{month}, 'W3CDTF: no month');

  $c = captures('2012-12', $W3CDTF_Rx);
  ok($c, 'W3CDTF: year-month');
  ok(!exists $c->{day}, 'W3CDTF: no day');

  $c = captures('2012-12-24', $W3CDTF_Rx);
  ok($c, 'W3CDTF: date only');
  ok(!exists $c->{hour}, 'W3CDTF: no hour');

  $c = captures('2012-12-24T15:30:45Z', $W3CDTF_Rx);
  ok($c, 'W3CDTF: full with Z');

  $c = captures('2012-12-24T15:30:45.500+01:00', $W3CDTF_Rx);
  ok($c, 'W3CDTF: full with fraction and offset');
}

# ASN.1 GeneralizedTime

{
  my $c = captures('20121224153045Z', $ASN1GT_Rx);
  ok($c, 'ASN1GT: full with Z');
  is($c->{year},   '2012', 'ASN1GT: year');
  is($c->{month},  '12',   'ASN1GT: month');
  is($c->{day},    '24',   'ASN1GT: day');
  is($c->{hour},   '15',   'ASN1GT: hour');
  is($c->{minute}, '30',   'ASN1GT: minute');
  is($c->{second}, '45',   'ASN1GT: second');

  $c = captures('2012122415Z', $ASN1GT_Rx);
  ok($c, 'ASN1GT: hour only');
  ok(!exists $c->{minute}, 'ASN1GT: no minute');

  $c = captures('201212241530Z', $ASN1GT_Rx);
  ok($c, 'ASN1GT: hour and minute');
  ok(!exists $c->{second}, 'ASN1GT: no second');

  $c = captures('20121224153045.500Z', $ASN1GT_Rx);
  is($c->{fraction}, '500', 'ASN1GT: fraction');

  $c = captures('20121224153045+0100', $ASN1GT_Rx);
  is($c->{tz_offset}, '+0100', 'ASN1GT: offset');

  $c = captures('20121224153045', $ASN1GT_Rx);
  ok($c, 'ASN1GT: no timezone');
  ok(!exists $c->{tz_utc},    'ASN1GT: no tz_utc');
  ok(!exists $c->{tz_offset}, 'ASN1GT: no tz_offset');
}

# ASN.1 UTCTime

{
  my $c = captures('121224153045Z', $ASN1UT_Rx);
  ok($c, 'ASN1UT: full with Z');
  is($c->{year}, '12', 'ASN1UT: two-digit year');

  $c = captures('1212241530Z', $ASN1UT_Rx);
  ok($c, 'ASN1UT: without second');
  ok(!exists $c->{second}, 'ASN1UT: no second');

  $c = captures('121224153045+0100', $ASN1UT_Rx);
  is($c->{tz_offset}, '+0100', 'ASN1UT: offset');

  ok(!captures('121224153045', $ASN1UT_Rx), 'ASN1UT: timezone required');
}

# CLF

{
  my $c = captures('24/Dec/2012:15:30:45 +0100', $CLF_Rx);
  ok($c, 'CLF: basic');
  is($c->{day},       '24',    'CLF: day');
  is($c->{month},     'Dec',   'CLF: month');
  is($c->{tz_offset}, '+0100', 'CLF: tz_offset');

  $c = captures('24/Dec/2012:15:30:45.500 +0100', $CLF_Rx);
  is($c->{fraction}, '500', 'CLF: fraction');
}

# ANSIC

{
  my $c = captures('Mon Dec 24 15:30:45 2012', $ANSIC_Rx);
  ok($c, 'ANSIC: basic');
  is($c->{day_name}, 'Mon',  'ANSIC: day_name');
  is($c->{month},    'Dec',  'ANSIC: month');
  is($c->{day},      '24',   'ANSIC: day');
  is($c->{year},     '2012', 'ANSIC: year');

  $c = captures('Sun Nov  6 08:49:37 1994', $ANSIC_Rx);
  ok($c, 'ANSIC: single-digit day');
  is($c->{day}, '6', 'ANSIC: single-digit day value');
}

# ECMAScript

{
  my $c = captures('Mon Dec 24 2012 15:30:45 GMT+0100', $ECMAScript_Rx);
  ok($c, 'ECMAScript: basic');
  is($c->{day_name},  'Mon',   'ECMAScript: day_name');
  is($c->{tz_utc},    'GMT',   'ECMAScript: tz_utc');
  is($c->{tz_offset}, '+0100', 'ECMAScript: tz_offset');

  $c = captures('Mon Dec 24 2012 15:30:45 GMT+0100 (Central European Time)', $ECMAScript_Rx);
  ok($c, 'ECMAScript: with comment');

  $c = captures('Mon Dec 24 2012 15:30:45 +0100', $ECMAScript_Rx);
  ok($c, 'ECMAScript: without UTC prefix');
  ok(!exists $c->{tz_utc} || !defined $c->{tz_utc}, 'ECMAScript: no tz_utc without prefix');
}

# GitDate

{
  my $c = captures('Mon Dec 24 15:30:45 2012 +0100', $GitDate_Rx);
  ok($c, 'GitDate: basic');
  is($c->{day_name},  'Mon',   'GitDate: day_name');
  is($c->{day},       '24',    'GitDate: day');
  is($c->{tz_offset}, '+0100', 'GitDate: tz_offset');

  $c = captures('Mon Dec 1 15:30:45 2012 +0100', $GitDate_Rx);
  ok($c, 'GitDate: single-digit day');
  is($c->{day}, '1', 'GitDate: single-digit day value');
}

# RubyDate

{
  my $c = captures('Mon Dec 24 15:30:45 +0100 2012', $RubyDate_Rx);
  ok($c, 'RubyDate: basic');
  is($c->{day_name},  'Mon',   'RubyDate: day_name');
  is($c->{year},      '2012',  'RubyDate: year');
  is($c->{tz_offset}, '+0100', 'RubyDate: tz_offset');
}

# UnixDate

{
  my $c = captures('Mon Dec 24 15:30:45 +0100 2012', $UnixDate_Rx);
  ok($c, 'UnixDate: tz before year');
  is($c->{tz_offset}, '+0100', 'UnixDate: tz_offset');

  $c = captures('Mon Dec 24 15:30:45 2012 +0100', $UnixDate_Rx);
  ok($c, 'UnixDate: year before tz');

  $c = captures('Mon Dec 24 15:30:45 UTC 2012', $UnixDate_Rx);
  is($c->{tz_utc}, 'UTC', 'UnixDate: tz_utc');

  $c = captures('Mon Dec 24 15:30:45 CET 2012', $UnixDate_Rx);
  is($c->{tz_abbrev}, 'CET', 'UnixDate: tz_abbrev');

  $c = captures('Sun Nov  6 08:49:37 1994 UTC', $UnixDate_Rx);
  ok($c, 'UnixDate: single-digit day');
}

# UnixStamp

{
  my $c = captures('Mon Dec 24 15:30:45 +0100 2012', $UnixStamp_Rx);
  ok($c, 'UnixStamp: basic');

  $c = captures('Dec 24 15:30:45 2012', $UnixStamp_Rx);
  ok($c, 'UnixStamp: without day name');
  ok(!exists $c->{day_name}, 'UnixStamp: no day_name');

  $c = captures('Mon Dec 24 15:30:45.500 UTC 2012', $UnixStamp_Rx);
  ok($c, 'UnixStamp: with fraction');
  is($c->{fraction}, '500', 'UnixStamp: fraction');

  $c = captures('Mon Dec 24 15:30 2012', $UnixStamp_Rx);
  ok($c, 'UnixStamp: without seconds');
  ok(!exists $c->{second}, 'UnixStamp: no second');

  $c = captures('Dec  6 15:30:45 2012', $UnixStamp_Rx);
  ok($c, 'UnixStamp: single-digit day');
  is($c->{day}, '6', 'UnixStamp: single-digit day value');
}

# DateTime

{
  my $c = captures('2012-12-24', $DateTime_Rx);
  ok($c, 'DateTime: date only');

  $c = captures('2012-12-24T15:30:45Z', $DateTime_Rx);
  ok($c, 'DateTime: ISO 8601 style');

  $c = captures('2012-12-24T15:30:45+01:00', $DateTime_Rx);
  ok($c, 'DateTime: with offset');

  $c = captures('24-Dec-2012', $DateTime_Rx);
  ok($c, 'DateTime: day-month-year textual');
  is($c->{month}, 'Dec', 'DateTime: textual month');

  $c = captures('December 24, 2012', $DateTime_Rx);
  ok($c, 'DateTime: long month name');

  $c = captures('24-XII-2012', $DateTime_Rx);
  ok($c, 'DateTime: Roman numeral month');
  is($c->{month}, 'XII', 'DateTime: Roman numeral');

  $c = captures('Mon, 24 Dec 2012 15:30:45 +0100', $DateTime_Rx);
  ok($c, 'DateTime: RFC 2822 style');
  is($c->{day_name}, 'Mon', 'DateTime: day_name');

  $c = captures('2012-12-24 03:30:45 PM', $DateTime_Rx);
  ok($c, 'DateTime: with PM');
  is($c->{meridiem}, 'PM', 'DateTime: meridiem');

  $c = captures('2012-12-24 03:30:45 a.m.', $DateTime_Rx);
  ok($c, 'DateTime: with a.m.');
  is($c->{meridiem}, 'a.m.', 'DateTime: dotted meridiem');

  $c = captures('Mon Dec 24 2012 15:30:45 GMT+0100', $DateTime_Rx);
  ok($c, 'DateTime: ECMAScript style');

  $c = captures('24 Dec 2012 15:30:45 CET', $DateTime_Rx);
  ok($c, 'DateTime: tz_abbrev');
  is($c->{tz_abbrev}, 'CET', 'DateTime: tz_abbrev value');

  $c = captures('2012-12-24T15:30:45+01:00[Europe/Stockholm]', $DateTime_Rx);
  ok($c, 'DateTime: with annotation');
  is($c->{tz_annotation}, '[Europe/Stockholm]', 'DateTime: tz_annotation');

  $c = captures('24th December 2012', $DateTime_Rx);
  ok($c, 'DateTime: ordinal suffix');

  $c = captures('2012/12/24', $DateTime_Rx);
  ok($c, 'DateTime: slash separator');

  $c = captures('2012.12.24', $DateTime_Rx);
  ok($c, 'DateTime: dot separator');

  ok(!captures('', $DateTime_Rx), 'DateTime: empty string rejects');
}

done_testing();
