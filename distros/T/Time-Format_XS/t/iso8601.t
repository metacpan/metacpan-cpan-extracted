#!/perl -I..

use strict;
use Test::More tests => 231;

BEGIN { use_ok 'Time::Format_XS' }

# "import" time_format function
*time_format = \&Time::Format_XS::time_format;

# Get day/month names in current locale
my ($Thursday, $Thu, $June, $Jun);
my ($Saturday, $Sat, $December, $Dec);
my ($Tuesday,  $Tue, $February, $Feb);
unless (eval
    {
        require I18N::Langinfo;
        I18N::Langinfo->import qw(langinfo DAY_3 MON_12 DAY_5 ABDAY_5 MON_6 ABMON_6);
        ($Tuesday,  $Tue, $February, $Feb) = map ucfirst lc langinfo($_), (DAY_3(), ABDAY_3(), MON_2(),  ABMON_2());
        ($Thursday, $Thu, $June, $Jun)     = map ucfirst lc langinfo($_), (DAY_5(), ABDAY_5(), MON_6(),  ABMON_6());
        ($Saturday, $Sat, $December, $Dec) = map ucfirst lc langinfo($_), (DAY_7(), ABDAY_7(), MON_12(), ABMON_12());
        1;
    })
{
    ($Tuesday,  $Tue, $February, $Feb) = qw(Tuesday  Tue February Feb);
    ($Thursday, $Thu, $June, $Jun)     = qw(Thursday Thu June Jun);
    ($Saturday, $Sat, $December, $Dec) = qw(Saturday Sat December Dec);
}

my $t;
$t = q{2003-06-05T13:58:09};

is time_format('Weekday, Month d, yyyy, H:mm:ssam', $t), "$Thursday, $June 5, 2003, 1:58:09pm" => "spelled out";

# Individual format code tests (32)
is time_format('yyyy',$t),      '2003'      => '4-digit year';
is time_format('yy',$t),        '03'        => '2-digit year';
is time_format('mm{on}',$t),    '06'        => 'month: mm';
is time_format('m{on}',$t),     '6'         => 'month: m';
is time_format('?m{on}',$t),    ' 6'        => 'month: ?m';
is time_format('Month',$t),      $June      => 'month name';
is time_format('MONTH',$t),   uc $June      => 'uc month name';
is time_format('month',$t),   lc $June      => 'lc month name';
is time_format('Mon',$t),        $Jun       => 'abbr month name';
is time_format('MON',$t),     uc $Jun       => 'uc abbr month name';
is time_format('mon',$t),     lc $Jun       => 'lc abbr month name';
is time_format('dd',$t),        '05'        => '2-digit day';
is time_format('d',$t),         '5'         => '1-digit day';
is time_format('?d',$t),        ' 5'        => 'spaced day';
is time_format('Weekday',$t),    $Thursday  => 'weekday';
is time_format('WEEKDAY',$t), uc $Thursday  => 'uc weekday';
is time_format('weekday',$t), lc $Thursday  => 'lc weekday';
is time_format('Day',$t),        $Thu       => 'weekday abbr';
is time_format('DAY',$t),     uc $Thu       => 'uc weekday abbr';
is time_format('day',$t),     lc $Thu       => 'lc weekday abbr';
is time_format('hh',$t),        '13'        => '2-digit 24-hour';
is time_format('h',$t),         '13'        => '1-digit 24-hour';
is time_format('?h',$t),        '13'        => 'spaced 24-hour';
is time_format('HH',$t),        '01'        => '2-digit 12-hour';
is time_format('H',$t),         '1'         => '1-digit 12-hour';
is time_format('?H',$t),        ' 1'        => 'spaced 12-hour';
is time_format('mm{in}',$t),    '58'        => 'm minute: 1';
is time_format('m{in}',$t),     '58'        => 'm minute: 2';
is time_format('?m{in}',$t),    '58'        => 'm minute: 3';
is time_format('ss',$t),        '09'        => '2-digit second';
is time_format('s',$t),         '9'         => '1-digit second';
is time_format('?s',$t),        ' 9'        => 'spaced second';

# am/pm tests (8)
is time_format('am',$t),        'pm'        => 'am';
is time_format('AM',$t),        'PM'        => 'AM';
is time_format('pm',$t),        'pm'        => 'pm';
is time_format('PM',$t),        'PM'        => 'PM';
is time_format('a.m.',$t),      'p.m.'      => 'a.m.';
is time_format('A.M.',$t),      'P.M.'      => 'A.M.';
is time_format('p.m.',$t),      'p.m.'      => 'p.m.';
is time_format('P.M.',$t),      'P.M.'      => 'P.M.';

# ordinal suffix tests (2)
is time_format('dth',$t),        '5th'        => '5th';
is time_format('dTH',$t),        '5TH'        => '5TH';

# Make sure 'm' guessing works reasonably well (19)
is time_format('yyyymm',$t),    '200306'    => 'm test: year';
is time_format('yymm',$t),      '0306'      => 'm test: year2';
is time_format('mmyy',$t),      '0603'      => 'm test: year2 2';
is time_format('mmdd',$t),      '0605'      => 'm test: day';
is time_format('yyyy/m',$t),    '2003/6'    => 'm test: year/';
is time_format('yy/m',$t),      '03/6'      => 'm test: year2/';
is time_format('m/d',$t),       '6/5'       => 'm test: /day';
is time_format('m/dd',$t),      '6/05'      => 'm test: /Day';
is time_format('?d/mm',$t),     ' 5/06'     => 'm test: d/m';
is time_format('?m/yyyy',$t),   ' 6/2003'   => 'm test: m/y';
is time_format('m/yy',$t),      '6/03'      => 'm test: m/y2';
is time_format('yyyy mon',$t),  "2003 \L$Jun"  => 'm test: year mon';
is time_format('hhmm',$t),      '1358'      => 'm test: hour';
is time_format('mmss',$t),      '5809'      => 'm test: sec';
is time_format('hh:mm',$t),     '13:58'     => 'm test: hour:';
is time_format('?m:ss',$t),     '58:09'     => 'm test: :sec';
is time_format('H:mm',$t),      '1:58'      => 'm test: Hour:';
is time_format('HH:mm',$t),     '01:58'     => 'm test: hour12:';
is time_format('?H:m',$t),      ' 1:58'     => 'm test: Hour12:';


# No date or time separators; _ datetime separator
$t = q{20051203_010203};   # Saturday, December 3, 2005, 1:02:03am

# Combined format (1)
is time_format('Weekday, Month d, yyyy, H:mm:ssam', $t), "$Saturday, $December 3, 2005, 1:02:03am" => "spelled out";

# Individual format code tests (32)
is time_format('yyyy',$t),      '2005'      => '4-digit year';
is time_format('yy',$t),        '05'        => '2-digit year';
is time_format('mm{on}',$t),    '12'        => 'month: mm';
is time_format('m{on}',$t),     '12'        => 'month: m';
is time_format('?m{on}',$t),    '12'        => 'month: ?m';
is time_format('Month',$t),      $December  => 'month name';
is time_format('MONTH',$t),   uc $December  => 'uc month name';
is time_format('month',$t),   lc $December  => 'lc month name';
is time_format('Mon',$t),        $Dec       => 'abbr month name';
is time_format('MON',$t),     uc $Dec       => 'uc abbr month name';
is time_format('mon',$t),     lc $Dec       => 'lc abbr month name';
is time_format('dd',$t),        '03'        => '2-digit day';
is time_format('d',$t),         '3'         => '1-digit day';
is time_format('?d',$t),        ' 3'        => 'spaced day';
is time_format('Weekday',$t),    $Saturday  => 'weekday';
is time_format('WEEKDAY',$t), uc $Saturday  => 'uc weekday';
is time_format('weekday',$t), lc $Saturday  => 'lc weekday';
is time_format('Day',$t),        $Sat       => 'weekday abbr';
is time_format('DAY',$t),     uc $Sat       => 'uc weekday abbr';
is time_format('day',$t),     lc $Sat       => 'lc weekday abbr';
is time_format('hh',$t),        '01'        => '2-digit 24-hour';
is time_format('h',$t),         '1'         => '1-digit 24-hour';
is time_format('?h',$t),        ' 1'        => 'spaced 24-hour';
is time_format('HH',$t),        '01'        => '2-digit 12-hour';
is time_format('H',$t),         '1'         => '1-digit 12-hour';
is time_format('?H',$t),        ' 1'        => 'spaced 12-hour';
is time_format('mm{in}',$t),    '02'        => 'm minute: 1';
is time_format('m{in}',$t),     '2'         => 'm minute: 2';
is time_format('?m{in}',$t),    ' 2'        => 'm minute: 3';
is time_format('ss',$t),        '03'        => '2-digit second';
is time_format('s',$t),         '3'         => '1-digit second';
is time_format('?s',$t),        ' 3'        => 'spaced second';

# am/pm tests (8)
is time_format('am',$t),        'am'        => 'am';
is time_format('AM',$t),        'AM'        => 'AM';
is time_format('pm',$t),        'am'        => 'pm';
is time_format('PM',$t),        'AM'        => 'PM';
is time_format('a.m.',$t),      'a.m.'      => 'a.m.';
is time_format('A.M.',$t),      'A.M.'      => 'A.M.';
is time_format('p.m.',$t),      'a.m.'      => 'p.m.';
is time_format('P.M.',$t),      'A.M.'      => 'P.M.';

# ordinal suffix tests (2)
is time_format('dth',$t),        '3rd'        => '3rd';
is time_format('dTH',$t),        '3RD'        => '3RD';

# Make sure 'm' guessing works reasonably well (19)
is time_format('yyyymm',$t),    '200512'     => 'm test: year';
is time_format('yymm',$t),      '0512'       => 'm test: year2';
is time_format('mmyy',$t),      '1205'       => 'm test: year2 2';
is time_format('mmdd',$t),      '1203'       => 'm test: day';
is time_format('yyyy/m',$t),    '2005/12'    => 'm test: year/';
is time_format('yy/m',$t),      '05/12'      => 'm test: year2/';
is time_format('m/d',$t),       '12/3'       => 'm test: /day';
is time_format('m/dd',$t),      '12/03'      => 'm test: /Day';
is time_format('?d/mm',$t),     ' 3/12'      => 'm test: d/m';
is time_format('?m/yyyy',$t),   '12/2005'    => 'm test: m/y';
is time_format('m/yy',$t),      '12/05'      => 'm test: m/y2';
is time_format('yyyy mon',$t),  "2005 \L$Dec"  => 'm test: year mon';
is time_format('hhmm',$t),      '0102'      => 'm test: hour';
is time_format('mmss',$t),      '0203'      => 'm test: sec';
is time_format('hh:mm',$t),     '01:02'     => 'm test: hour:';
is time_format('?m:ss',$t),     ' 2:03'     => 'm test: :sec';
is time_format('H:mm',$t),      '1:02'      => 'm test: Hour:';
is time_format('HH:mm',$t),     '01:02'     => 'm test: hour12:';
is time_format('?H:m',$t),      ' 1:2'      => 'm test: Hour12:';


# Time only
$t = q{13:58:09};

# Combined format (1)
is time_format('H:mm:ssam', $t), "1:58:09pm" => "spelled out";

# Individual format code tests (26)
is time_format('yyyy',$t),      '1969'      => '4-digit year';
is time_format('yy',$t),        '69'        => '2-digit year';
is time_format('mm{on}',$t),    '12'        => 'month: mm';
is time_format('m{on}',$t),     '12'        => 'month: m';
is time_format('?m{on}',$t),    '12'        => 'month: ?m';
is time_format('Month',$t),      $December  => 'month name';
is time_format('MONTH',$t),   uc $December  => 'uc month name';
is time_format('month',$t),   lc $December  => 'lc month name';
is time_format('Mon',$t),        $Dec       => 'abbr month name';
is time_format('MON',$t),     uc $Dec       => 'uc abbr month name';
is time_format('mon',$t),     lc $Dec       => 'lc abbr month name';
is time_format('dd',$t),        '31'        => '2-digit day';
is time_format('d',$t),         '31'        => '1-digit day';
is time_format('?d',$t),        '31'        => 'spaced day';
is time_format('hh',$t),        '13'        => '2-digit 24-hour';
is time_format('h',$t),         '13'        => '1-digit 24-hour';
is time_format('?h',$t),        '13'        => 'spaced 24-hour';
is time_format('HH',$t),        '01'        => '2-digit 12-hour';
is time_format('H',$t),         '1'         => '1-digit 12-hour';
is time_format('?H',$t),        ' 1'        => 'spaced 12-hour';
is time_format('mm{in}',$t),    '58'        => 'm minute: 1';
is time_format('m{in}',$t),     '58'        => 'm minute: 2';
is time_format('?m{in}',$t),    '58'        => 'm minute: 3';
is time_format('ss',$t),        '09'        => '2-digit second';
is time_format('s',$t),         '9'         => '1-digit second';
is time_format('?s',$t),        ' 9'        => 'spaced second';

# am/pm tests (8)
is time_format('am',$t),        'pm'        => 'am';
is time_format('AM',$t),        'PM'        => 'AM';
is time_format('pm',$t),        'pm'        => 'pm';
is time_format('PM',$t),        'PM'        => 'PM';
is time_format('a.m.',$t),      'p.m.'      => 'a.m.';
is time_format('A.M.',$t),      'P.M.'      => 'A.M.';
is time_format('p.m.',$t),      'p.m.'      => 'p.m.';
is time_format('P.M.',$t),      'P.M.'      => 'P.M.';

# ordinal suffix tests (2)
is time_format('dth',$t),        '31st'        => '3rd';
is time_format('dTH',$t),        '31ST'        => '3RD';

# Make sure 'm' guessing works reasonably well (19)
is time_format('yyyymm',$t),    '196912'     => 'm test: year';
is time_format('yymm',$t),      '6912'       => 'm test: year2';
is time_format('mmyy',$t),      '1269'       => 'm test: year2 2';
is time_format('mmdd',$t),      '1231'       => 'm test: day';
is time_format('yyyy/m',$t),    '1969/12'    => 'm test: year/';
is time_format('yy/m',$t),      '69/12'      => 'm test: year2/';
is time_format('m/d',$t),       '12/31'      => 'm test: /day';
is time_format('m/dd',$t),      '12/31'      => 'm test: /Day';
is time_format('?d/mm',$t),     '31/12'      => 'm test: d/m';
is time_format('?m/yyyy',$t),   '12/1969'    => 'm test: m/y';
is time_format('m/yy',$t),      '12/69'      => 'm test: m/y2';
is time_format('yyyy mon',$t),  "1969 \L$Dec"  => 'm test: year mon';
is time_format('hhmm',$t),      '1358'      => 'm test: hour';
is time_format('mmss',$t),      '5809'      => 'm test: sec';
is time_format('hh:mm',$t),     '13:58'     => 'm test: hour:';
is time_format('?m:ss',$t),     '58:09'     => 'm test: :sec';
is time_format('H:mm',$t),      '1:58'      => 'm test: Hour:';
is time_format('HH:mm',$t),     '01:58'     => 'm test: hour12:';
is time_format('?H:m',$t),      ' 1:58'     => 'm test: Hour12:';


# Time only requires separators!
$t = q{135809};   # should be interpreted as an epoch time, not HHMMSS.
my ($sec, $min, $hr) = localtime (135809);
my $test = sprintf '%02d:%02d:%02d', $hr, $min, $sec;

# Combined format (1)
is time_format('hh:mm:ss', $t), $test => "spelled out";

# Date only
$t = q{2003/06/05};

is time_format('Weekday, Month d, yyyy, H:mm:ssam', $t), "$Thursday, $June 5, 2003, 12:00:00am" => "spelled out";

# Individual format code tests (32)
is time_format('yyyy',$t),      '2003'      => '4-digit year';
is time_format('yy',$t),        '03'        => '2-digit year';
is time_format('mm{on}',$t),    '06'        => 'month: mm';
is time_format('m{on}',$t),     '6'         => 'month: m';
is time_format('?m{on}',$t),    ' 6'        => 'month: ?m';
is time_format('Month',$t),      $June      => 'month name';
is time_format('MONTH',$t),   uc $June      => 'uc month name';
is time_format('month',$t),   lc $June      => 'lc month name';
is time_format('Mon',$t),        $Jun       => 'abbr month name';
is time_format('MON',$t),     uc $Jun       => 'uc abbr month name';
is time_format('mon',$t),     lc $Jun       => 'lc abbr month name';
is time_format('dd',$t),        '05'        => '2-digit day';
is time_format('d',$t),         '5'         => '1-digit day';
is time_format('?d',$t),        ' 5'        => 'spaced day';
is time_format('Weekday',$t),    $Thursday  => 'weekday';
is time_format('WEEKDAY',$t), uc $Thursday  => 'uc weekday';
is time_format('weekday',$t), lc $Thursday  => 'lc weekday';
is time_format('Day',$t),        $Thu       => 'weekday abbr';
is time_format('DAY',$t),     uc $Thu       => 'uc weekday abbr';
is time_format('day',$t),     lc $Thu       => 'lc weekday abbr';
is time_format('hh',$t),        '00'        => '2-digit 24-hour';
is time_format('h',$t),         '0'         => '1-digit 24-hour';
is time_format('?h',$t),        ' 0'        => 'spaced 24-hour';
is time_format('HH',$t),        '12'        => '2-digit 12-hour';
is time_format('H',$t),         '12'        => '1-digit 12-hour';
is time_format('?H',$t),        '12'        => 'spaced 12-hour';
is time_format('mm{in}',$t),    '00'        => 'm minute: 1';
is time_format('m{in}',$t),     '0'         => 'm minute: 2';
is time_format('?m{in}',$t),    ' 0'        => 'm minute: 3';
is time_format('ss',$t),        '00'        => '2-digit second';
is time_format('s',$t),         '0'         => '1-digit second';
is time_format('?s',$t),        ' 0'        => 'spaced second';

# am/pm tests (2)
is time_format('PM',$t),        'AM'        => 'PM';
is time_format('A.M.',$t),      'A.M.'      => 'A.M.';


# No date or time separators; No datetime separator
$t = q{20051203010203};   # Saturday, December 3, 2005, 1:02:03am

# Combined format (1)
is time_format('Weekday, Month d, yyyy, H:mm:ssam', $t), "$Saturday, $December 3, 2005, 1:02:03am" => "No separators; spelled out";

# No date separator; ":" time separators; No datetime separator.  This is Date::Manip's format.
$t = q{19990619163100};   # Saturday, June 19, 1999, 4:31:00pm

# Combined format (1)
is time_format('Weekday, Month d, yyyy, H:mm:ssam', $t), "$Saturday, $June 19, 1999, 4:31:00pm" => "Date::Manip format";



# Now let's go for some errors.
my $fmt;

$t = q{2003-13-05T13:58:09};
eval { $fmt = time_format('Weekday, Month d, yyyy, H:mm:ssam', $t)  };
like ($@, qr{\A\QInvalid month "13" in iso8601 string\E}, "Invalid month 13");

$t = q{2003-06-32T13:58:09};
eval { $fmt = time_format('Weekday, Month d, yyyy, H:mm:ssam', $t)  };
like ($@, qr{\A\QInvalid day "32" in iso8601 string\E}, "Invalid day 32");

$t = q{2003-06-31T13:58:09};
eval { $fmt = time_format('Weekday, Month d, yyyy, H:mm:ssam', $t)  };
like ($@, qr{\A\QInvalid day "31" for month 06 in iso8601 string\E}, "Invalid day 31");

$t = q{2003-02-29T13:58:09};
eval { $fmt = time_format('Weekday, Month d, yyyy, H:mm:ssam', $t)  };
like ($@, qr{\A\QInvalid day "29" for 02/2003 in iso8601 string\E}, "Invalid day 29");

$t = q{2000-02-29T13:58:09};
eval { $fmt = time_format('Weekday, Month d, yyyy, H:mm:ssam', $t)  };
is ($@, q{}, "2/29/2000 no error");
is ($fmt, qq{$Tuesday, $February 29, 2000, 1:58:09pm}, "2/29/2000 okay");

$t = q{2003-06-05T24:58:09};
eval { $fmt = time_format('Weekday, Month d, yyyy, H:mm:ssam', $t)  };
like ($@, qr{\A\QInvalid hour "24" in iso8601 string\E}, "Invalid hour 24");

$t = q{2003-06-05T13:60:09};
eval { $fmt = time_format('Weekday, Month d, yyyy, H:mm:ssam', $t)  };
like ($@, qr{\A\QInvalid minute "60" in iso8601 string\E}, "Invalid minute 60");

$t = q{2003-06-05T13:58:62};
eval { $fmt = time_format('Weekday, Month d, yyyy, H:mm:ssam', $t)  };
like ($@, qr{\A\QInvalid second "62" in iso8601 string\E}, "Invalid second 62");

$t = q{2003-13-05X13:58:09};
eval { $fmt = time_format('Weekday, Month d, yyyy, H:mm:ssam', $t)  };
like ($@, qr{\A\QCan't understand time value "\E}, "Invalid datetime separator");

$t = q{2003:13:05};
eval { $fmt = time_format('Weekday, Month d, yyyy, H:mm:ssam', $t)  };
like ($@, qr{\A\QCan't understand time value "\E}, "Invalid date separator");

$t = q{13/58/09};
eval { $fmt = time_format('Weekday, Month d, yyyy, H:mm:ssam', $t)  };
like ($@, qr{\A\QCan't understand time value "\E}, "Invalid time separator");

