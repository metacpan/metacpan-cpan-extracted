#!/perl -I..

use strict;
use Test::More tests => 80;

BEGIN { use_ok 'Time::Format_XS' }

# "import" time_format function
*time_format = \&Time::Format_XS::time_format;

my $dt_notok;
BEGIN {$dt_notok = eval ('use DateTime; 1')? 0 : 1}

# Get day/month names in current locale
my ($Thursday, $Thu, $June, $Jun);
unless (eval
    {
        require I18N::Langinfo;
        I18N::Langinfo->import qw(langinfo DAY_3 MON_12 DAY_5 ABDAY_5 MON_6 ABMON_6);
        ($Thursday, $Thu, $June, $Jun) = map ucfirst lc langinfo($_), (DAY_5(), ABDAY_5(), MON_6(), ABMON_6());
        1;
    })
{
    ($Thursday, $Thu, $June, $Jun) = qw(Thursday Thu June Jun);
}

SKIP:
{
    skip 'DateTime not available', 79  if $dt_notok;
    # June 5, 2003 at 1:58:09 pm
    my $dt = DateTime->new(year=>2003, month=>6, day=>5, hour=>13, minute=>58, second=>9, nanosecond=>987654321);
    my $du;
    my $dt2;

    # Individual format code tests (34)
    is time_format('yyyy',$dt),      '2003'      => '4-digit year';
    is time_format('yy',$dt),        '03'        => '2-digit year';
    is time_format('mm{on}',$dt),    '06'        => 'month: mm';
    is time_format('m{on}',$dt),     '6'         => 'month: m';
    is time_format('?m{on}',$dt),    ' 6'        => 'month: ?m';
    is time_format('Month',$dt),      $June      => 'month name';
    is time_format('MONTH',$dt),   uc $June      => 'uc month name';
    is time_format('month',$dt),   lc $June      => 'lc month name';
    is time_format('Mon',$dt),        $Jun       => 'abbr month name';
    is time_format('MON',$dt),     uc $Jun       => 'uc abbr month name';
    is time_format('mon',$dt),     lc $Jun       => 'lc abbr month name';
    is time_format('dd',$dt),        '05'        => '2-digit day';
    is time_format('d',$dt),         '5'         => '1-digit day';
    is time_format('?d',$dt),        ' 5'        => 'spaced day';
    is time_format('Weekday',$dt),    $Thursday  => 'weekday';
    is time_format('WEEKDAY',$dt), uc $Thursday  => 'uc weekday';
    is time_format('weekday',$dt), lc $Thursday  => 'lc weekday';
    is time_format('Day',$dt),        $Thu       => 'weekday abbr';
    is time_format('DAY',$dt),     uc $Thu       => 'uc weekday abbr';
    is time_format('day',$dt),     lc $Thu       => 'lc weekday abbr';
    is time_format('hh',$dt),        '13'        => '2-digit 24-hour';
    is time_format('h',$dt),         '13'        => '1-digit 24-hour';
    is time_format('?h',$dt),        '13'        => 'spaced 24-hour';
    is time_format('HH',$dt),        '01'        => '2-digit 12-hour';
    is time_format('H',$dt),         '1'         => '1-digit 12-hour';
    is time_format('?H',$dt),        ' 1'        => 'spaced 12-hour';
    is time_format('mm{in}',$dt),    '58'        => 'm minute: 1';
    is time_format('m{in}',$dt),     '58'        => 'm minute: 2';
    is time_format('?m{in}',$dt),    '58'        => 'm minute: 3';
    is time_format('ss',$dt),        '09'        => '2-digit second';
    is time_format('s',$dt),         '9'         => '1-digit second';
    is time_format('?s',$dt),        ' 9'        => 'spaced second';
    is time_format('mmm',$dt),       '987'       => 'millisecond';
    is time_format('uuuuuu',$dt),    '987654'    => 'microsecond';

    # am/pm tests (16)
    $du = DateTime::Duration->new(seconds => 9999);
    $dt2 = $dt->clone->subtract_duration($du);
    is time_format('am',$dt),        'pm'        => 'am';
    is time_format('AM',$dt),        'PM'        => 'AM';
    is time_format('pm',$dt),        'pm'        => 'pm';
    is time_format('PM',$dt),        'PM'        => 'PM';
    is time_format('a.m.',$dt),      'p.m.'      => 'a.m.';
    is time_format('A.M.',$dt),      'P.M.'      => 'A.M.';
    is time_format('p.m.',$dt),      'p.m.'      => 'p.m.';
    is time_format('P.M.',$dt),      'P.M.'      => 'P.M.';
    is time_format('am',$dt2),       'am'        => 'am 2';
    is time_format('AM',$dt2),       'AM'        => 'AM 2';
    is time_format('pm',$dt2),       'am'        => 'pm 2';
    is time_format('PM',$dt2),       'AM'        => 'PM 2';
    is time_format('a.m.',$dt2),     'a.m.'      => 'a.m. 2';
    is time_format('A.M.',$dt2),     'A.M.'      => 'A.M. 2';
    is time_format('p.m.',$dt2),     'a.m.'      => 'p.m. 2';
    is time_format('P.M.',$dt2),     'A.M.'      => 'P.M. 2';

    # ordinal suffix tests (8)
    is time_format('dth',$dt),        '5th'        => '5th';
    is time_format('dTH',$dt),        '5TH'        => '5TH';
    $du = DateTime::Duration->new(days => 4);
    $dt2 = $dt->clone->subtract_duration($du);
    is time_format('dth',$dt2),       '1st'        => '1st';
    $du = DateTime::Duration->new(days => 3);
    $dt2 = $dt->clone->subtract_duration($du);
    is time_format('dth',$dt2),       '2nd'        => '2nd';
    $du = DateTime::Duration->new(days => 2);
    $dt2 = $dt->clone->subtract_duration($du);
    is time_format('dth',$dt2),       '3rd'        => '3rd';
    is time_format('dTH',$dt2),       '3RD'        => '3RD';
    $du = DateTime::Duration->new(days => 6);
    $dt2 = $dt->clone->add_duration($du);
    is time_format('dth',$dt2),       '11th'       => '11th';
    $du = DateTime::Duration->new(days => 16);
    $dt2 = $dt->clone->add_duration($du);
    is time_format('dth',$dt2),        '21st'      => '21st';


    # Make sure 'm' guessing works reasonably well (18)
    is time_format('yyyymm',$dt),    '200306'    => 'm test: year';
    is time_format('yymm',$dt),      '0306'      => 'm test: year2';
    is time_format('mmdd',$dt),      '0605'      => 'm test: day';
    is time_format('yyyy/m',$dt),    '2003/6'    => 'm test: year/';
    is time_format('yy/m',$dt),      '03/6'      => 'm test: year2/';
    is time_format('m/d',$dt),       '6/5'       => 'm test: /day';
    is time_format('m/dd',$dt),      '6/05'      => 'm test: /Day';
    is time_format('?d/mm',$dt),     ' 5/06'     => 'm test: d/m';
    is time_format('?m/yyyy',$dt),   ' 6/2003'   => 'm test: m/y';
    is time_format('m/yy',$dt),      '6/03'      => 'm test: m/y2';
    is time_format('yyyy mon',$dt),  '2003 jun'  => 'm test: year mon';
    is time_format('hhmm',$dt),      '1358'      => 'm test: hour';
    is time_format('mmss',$dt),      '5809'      => 'm test: sec';
    is time_format('hh:mm',$dt),     '13:58'     => 'm test: hour:';
    is time_format('?m:ss',$dt),     '58:09'     => 'm test: :sec';
    is time_format('H:mm',$dt),      '1:58'      => 'm test: Hour:';
    is time_format('HH:mm',$dt),     '01:58'     => 'm test: hour12:';
    is time_format('?H:m',$dt),      ' 1:58'     => 'm test: Hour12:';

    # cases 'm' guessing can't handle (3)
    is time_format('mm',$dt),        'mm'        => '2-digit month/minute';
    is time_format('m',$dt),         'm'         => '1-digit month/minute';
    is time_format('?m',$dt),        '?m'        => 'spaced month/minute';
}
