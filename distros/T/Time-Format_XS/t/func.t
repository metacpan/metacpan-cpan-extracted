#!/perl -I..

use strict;
use Test::More tests => 80;

BEGIN { use_ok 'Time::Format_XS' }

# "import" time_format function
*time_format = \&Time::Format_XS::time_format;

my $tl_notok;
BEGIN {$tl_notok = eval ('use Time::Local; 1')? 0 : 1}

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
    skip 'Time::Local not available', 79  if $tl_notok;
    my $t = timelocal(9, 58, 13, 5, 5, 103);    # June 5, 2003 at 1:58:09 pm
    $t .= '.987654321';

    # Individual format code tests (34)
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
    is time_format('mmm',$t),       '987'       => 'millisecond';
    is time_format('uuuuuu',$t),    '987654'    => 'microsecond';

    # am/pm tests (16)
    is time_format('am',$t),        'pm'        => 'am';
    is time_format('AM',$t),        'PM'        => 'AM';
    is time_format('pm',$t),        'pm'        => 'pm';
    is time_format('PM',$t),        'PM'        => 'PM';
    is time_format('a.m.',$t),      'p.m.'      => 'a.m.';
    is time_format('A.M.',$t),      'P.M.'      => 'A.M.';
    is time_format('p.m.',$t),      'p.m.'      => 'p.m.';
    is time_format('P.M.',$t),      'P.M.'      => 'P.M.';
    is time_format('am',$t-9999),   'am'        => 'am 2';
    is time_format('AM',$t-9999),   'AM'        => 'AM 2';
    is time_format('pm',$t-9999),   'am'        => 'pm 2';
    is time_format('PM',$t-9999),   'AM'        => 'PM 2';
    is time_format('a.m.',$t-9999), 'a.m.'      => 'a.m. 2';
    is time_format('A.M.',$t-9999), 'A.M.'      => 'A.M. 2';
    is time_format('p.m.',$t-9999), 'a.m.'      => 'p.m. 2';
    is time_format('P.M.',$t-9999), 'A.M.'      => 'P.M. 2';

    # ordinal suffix tests (8)
    is time_format('dth',$t),        '5th'        => '5th';
    is time_format('dTH',$t),        '5TH'        => '5TH';
    is time_format('dth',$t-4*86400),'1st'        => '1st';
    is time_format('dth',$t-3*86400),'2nd'        => '2nd';
    is time_format('dth',$t-2*86400),'3rd'        => '3rd';
    is time_format('dTH',$t-2*86400),'3RD'        => '3RD';
    is time_format('dth',$t+6*86400),'11th'       => '11th';
    is time_format('dth',$t+16*86400),'21st'      => '21st';


    # Make sure 'm' guessing works reasonably well (18)
    is time_format('yyyymm',$t),    '200306'    => 'm test: year';
    is time_format('yymm',$t),      '0306'      => 'm test: year2';
    is time_format('mmdd',$t),      '0605'      => 'm test: day';
    is time_format('yyyy/m',$t),    '2003/6'    => 'm test: year/';
    is time_format('yy/m',$t),      '03/6'      => 'm test: year2/';
    is time_format('m/d',$t),       '6/5'       => 'm test: /day';
    is time_format('m/dd',$t),      '6/05'      => 'm test: /Day';
    is time_format('?d/mm',$t),     ' 5/06'     => 'm test: d/m';
    is time_format('?m/yyyy',$t),   ' 6/2003'   => 'm test: m/y';
    is time_format('m/yy',$t),      '6/03'      => 'm test: m/y2';
    is time_format('yyyy mon',$t),  '2003 jun'  => 'm test: year mon';
    is time_format('hhmm',$t),      '1358'      => 'm test: hour';
    is time_format('mmss',$t),      '5809'      => 'm test: sec';
    is time_format('hh:mm',$t),     '13:58'     => 'm test: hour:';
    is time_format('?m:ss',$t),     '58:09'     => 'm test: :sec';
    is time_format('H:mm',$t),      '1:58'      => 'm test: Hour:';
    is time_format('HH:mm',$t),     '01:58'     => 'm test: hour12:';
    is time_format('?H:m',$t),      ' 1:58'     => 'm test: Hour12:';

    # cases 'm' guessing can't handle (3)
    is time_format('mm',$t),        'mm'        => '2-digit month/minute';
    is time_format('m',$t),         'm'         => '1-digit month/minute';
    is time_format('?m',$t),        '?m'        => 'spaced month/minute';
}
