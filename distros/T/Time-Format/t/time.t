#!/perl -I..

use strict;
use Test::More tests => 78;

BEGIN { $Time::Format::NOXS = 1 }
BEGIN { use_ok 'Time::Format', qw(%time) }
my $tl_notok;
BEGIN {$tl_notok = eval ('use Time::Local; 1')? 0 : 1}

# Get day/month names in current locale
my ($Weekday, $Day, $Month, $Mon);
unless (eval
    {
        require I18N::Langinfo;
        I18N::Langinfo->import(qw(langinfo DAY_5 ABDAY_5 MON_6 ABMON_6));
        ($Weekday, $Day, $Month, $Mon) = map langinfo($_), (DAY_5(), ABDAY_5(), MON_6(), ABMON_6());
        1;
    })
{
    ($Weekday, $Day, $Month, $Mon) = qw(Thursday Thu June Jun);
}


SKIP:
{
    skip 'Time::Local not available', 77  if $tl_notok;
    my $t = timelocal(9, 58, 13, 5, 5, 103);    # June 5, 2003 at 1:58:09 pm
    $t .= '.987654321';

    # Basic tests (34)
    is $time{'yyyy',$t},      '2003'      => '4-digit year';
    is $time{'yy',$t},        '03'        => '2-digit year';
    is $time{'mm{on}',$t},    '06'        => 'month: mm';
    is $time{'m{on}',$t},     '6'         => 'month: m';
    is $time{'?m{on}',$t},    ' 6'        => 'month: ?m';
    is $time{'Month',$t},      $Month     => 'month name';
    is $time{'MONTH',$t},   uc $Month     => 'uc month name';
    is $time{'month',$t},   lc $Month     => 'lc month name';
    is $time{'Mon',$t},        $Mon       => 'abbr month name';
    is $time{'MON',$t},     uc $Mon       => 'uc abbr month name';
    is $time{'mon',$t},     lc $Mon       => 'lc abbr month name';
    is $time{'dd',$t},        '05'        => '2-digit day';
    is $time{'d',$t},         '5'         => '1-digit day';
    is $time{'?d',$t},        ' 5'        => 'spaced day';
    is $time{'Weekday',$t},    $Weekday   => 'weekday';
    is $time{'WEEKDAY',$t}, uc $Weekday   => 'uc weekday';
    is $time{'weekday',$t}, lc $Weekday   => 'lc weekday';
    is $time{'Day',$t},        $Day       => 'weekday abbr';
    is $time{'DAY',$t},     uc $Day       => 'uc weekday abbr';
    is $time{'day',$t},     lc $Day       => 'lc weekday abbr';
    is $time{'hh',$t},        '13'        => '2-digit 24-hour';
    is $time{'h',$t},         '13'        => '1-digit 24-hour';
    is $time{'?h',$t},        '13'        => 'spaced 24-hour';
    is $time{'HH',$t},        '01'        => '2-digit 12-hour';
    is $time{'H',$t},         '1'         => '1-digit 12-hour';
    is $time{'?H',$t},        ' 1'        => 'spaced 12-hour';
    is $time{'mm{in}',$t},    '58'        => 'minute: mm';
    is $time{'m{in}',$t},     '58'        => 'minute: m';
    is $time{'?m{in}',$t},    '58'        => 'minute: ?m';
    is $time{'ss',$t},        '09'        => '2-digit second';
    is $time{'s',$t},         '9'         => '1-digit second';
    is $time{'?s',$t},        ' 9'        => 'spaced second';
    is $time{'mmm',$t},       '987'       => 'millisecond';
    is $time{'uuuuuu',$t},    '987654'    => 'microsecond';

    # am/pm tests (16)
    is $time{'am',$t},        'pm'        => 'am';
    is $time{'AM',$t},        'PM'        => 'AM';
    is $time{'pm',$t},        'pm'        => 'pm';
    is $time{'PM',$t},        'PM'        => 'PM';
    is $time{'a.m.',$t},      'p.m.'      => 'a.m.';
    is $time{'A.M.',$t},      'P.M.'      => 'A.M.';
    is $time{'p.m.',$t},      'p.m.'      => 'p.m.';
    is $time{'P.M.',$t},      'P.M.'      => 'P.M.';
    is $time{'am',$t-9999},   'am'        => 'am 2';
    is $time{'AM',$t-9999},   'AM'        => 'AM 2';
    is $time{'pm',$t-9999},   'am'        => 'pm 2';
    is $time{'PM',$t-9999},   'AM'        => 'PM 2';
    is $time{'a.m.',$t-9999}, 'a.m.'      => 'a.m. 2';
    is $time{'A.M.',$t-9999}, 'A.M.'      => 'A.M. 2';
    is $time{'p.m.',$t-9999}, 'a.m.'      => 'p.m. 2';
    is $time{'P.M.',$t-9999}, 'A.M.'      => 'P.M. 2';

    # ordinal suffix tests (8)
    is $time{'dth',$t},        '5th'        => '5th';
    is $time{'dTH',$t},        '5TH'        => '5TH';
    is $time{'dth',$t-4*86400},'1st'        => '1st';
    is $time{'dth',$t-3*86400},'2nd'        => '2nd';
    is $time{'dth',$t-2*86400},'3rd'        => '3rd';
    is $time{'dTH',$t-2*86400},'3RD'        => '3RD';
    is $time{'dth',$t+6*86400},'11th'       => '11th';
    is $time{'dth',$t+16*86400},'21st'      => '21st';


    # Make sure 'm' guessing works reasonably well (18)
    is $time{'yyyymm',$t},    '200306'      => 'm test: year';
    is $time{'yymm',$t},      '0306'        => 'm test: year2';
    is $time{'mmdd',$t},      '0605'        => 'm test: day';
    is $time{'yyyy/m',$t},    '2003/6'      => 'm test: year/';
    is $time{'yy/m',$t},      '03/6'        => 'm test: year2/';
    is $time{'m/d',$t},       '6/5'         => 'm test: /day';
    is $time{'m/dd',$t},      '6/05'        => 'm test: /Day';
    is $time{'?d/mm',$t},     ' 5/06'       => 'm test: d/m';
    is $time{'?m/yyyy',$t},   ' 6/2003'     => 'm test: m/y';
    is $time{'m/yy',$t},      '6/03'        => 'm test: m/y2';

    # This test was broken until v1.06 (2008/03/28): was hardcoded to "jun".
    is $time{'yyyy mon',$t},  "2003 \L$Mon" => 'm test: year mon';

    is $time{'hhmm',$t},      '1358'        => 'm test: hour';
    is $time{'mmss',$t},      '5809'        => 'm test: sec';
    is $time{'hh:mm',$t},     '13:58'       => 'm test: hour:';
    is $time{'?m:ss',$t},     '58:09'       => 'm test: :sec';
    is $time{'H:mm',$t},      '1:58'        => 'm test: Hour:';
    is $time{'HH:mm',$t},     '01:58'       => 'm test: hour12:';
    is $time{'?H:m',$t},      ' 1:58'       => 'm test: Hour12:';

    # Current time value (1)
    # localtime seems always to return English day/month
    my ($m,$d) = (localtime)[4,6];
    my $mon = (qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec))[$m];
    my $day = (qw(Sun Mon Tue Wed Thu Fri Sat))[$d];
    is "$day $mon $time{'?d hh:mm:ss yyyy'}", scalar(localtime)  => 'current time';
    #
    # Note that there are two race conditions in the last section, above.
    # 1: The day or month could change between the first localtime()
    #         call and the second.
    # 2: The time (especially the seconds) could change between the
    #         %time call and the second localtime().
    # The first is extremely rare; the second more frequent.

    # Re-run the test suite if there is any doubt.
}
