#!/perl

# Test the %time tied hash

use strict;
use Test::More tests => 102;
use FindBin;
use lib $FindBin::Bin;
use TimeFormat_Minute;

## ----------------------------------------------------------------------------------
## Test for availability of certain modules.
my $tl_ok;
BEGIN {$tl_ok = eval ('use Time::Local; 1')}


## ----------------------------------------------------------------------------------
## Load our module.
BEGIN { $Time::Format::NOXS = 1 }
BEGIN { use_ok 'Time::Format', qw(%time) }

## ----------------------------------------------------------------------------------
## Get day/month names in current locale; fallback to English (sorry!).
my ($Weekday, $Day, $Month, $Mon);
my $lc_supported = 1;
$lc_supported = 0  if $^O eq 'openbsd';
if (!$lc_supported  ||  !eval
    {
        require I18N::Langinfo;
        I18N::Langinfo->import(qw(langinfo DAY_5 ABDAY_5 MON_6 ABMON_6));
        ($Weekday, $Day, $Month, $Mon) = map langinfo($_), (DAY_5(), ABDAY_5(), MON_6(), ABMON_6());
        1;
    })
{
    diag 'Cannot determine locale; falling back to English.';
    ($Weekday, $Day, $Month, $Mon) = qw(Thursday Thu June Jun);
}


## ----------------------------------------------------------------------------------
## Begin tests.

SKIP:
{
    skip 'Time::Local not available', 77  unless $tl_ok;
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
}

# Current-time tests (%time with no second argument).
tf_minute_sync;
my ($sec, $min, $hr, $day, $mon, $yr) = localtime;
$yr += 1900;
++$mon;
my $h12 = ($hr % 12) || '12';
my $y2 = $yr % 100;

# Individual components (10)
is $time{'yyyy'},      sprintf('%04d', $yr)   => '4-digit year (cur)';
is $time{'yy'},        sprintf('%02d', $y2)   => '2-digit year (cur)';
is $time{'mm{on}'},    sprintf('%02d', $mon)  => 'month: mm (cur)';
is $time{'m{on}'},     sprintf('%1d', $mon)   => 'month: mm (cur)';
is $time{'dd'},        sprintf('%02d', $day)  => '2-digit day (cur)';
is $time{'d'},         sprintf('%1d', $day)   => '1/2-digit day (cur)';
is $time{'hh'},        sprintf('%02d', $hr)   => '2-digit 24-hour (cur)';
is $time{'h'},         sprintf('%1d', $hr)    => '1/2-digit 24-hour (cur)';
is $time{'mm{in}'},    sprintf('%02d', $min)  => 'minute: mm (cur)';
is $time{'m{in}'},     sprintf('%1d', $min)   => 'minute: m (cur)';

# Month disambiguation tests (10)
is $time{'yyyymm'},    sprintf('%04d%02d', $yr, $mon)    => 'm test: year (cur)';
is $time{'yymm'},      sprintf('%02d%02d', $y2, $mon)    => 'm test: year2 (cur)';
is $time{'mmdd'},      sprintf('%02d%02d', $mon, $day)   => 'm test: day (cur)';
is $time{'yyyy/m'},    sprintf('%04d/%1d', $yr, $mon)    => 'm test: year/ (cur)';
is $time{'yy/m'},      sprintf('%02d/%1d', $y2, $mon)    => 'm test: year2/ (cur)';
is $time{'m/d'},       sprintf('%1d/%1d', $mon, $day)    => 'm test: /day (cur)';
is $time{'m/dd'},      sprintf('%1d/%02d', $mon, $day)   => 'm test: /Day (cur)';
is $time{'?d/mm'},     sprintf('%2d/%02d', $day, $mon)   => 'm test: d/m (cur)';
is $time{'?m/yyyy'},   sprintf('%2d/%04d', $mon, $yr)    => 'm test: m/y (cur)';
is $time{'m/yy'},      sprintf('%1d/%02d', $mon, $y2)    => 'm test: m/y2 (cur)';

# Minute disambiguation tests (5)
is $time{'hhmm'},      sprintf('%02d%02d', $hr, $min)    => 'm test: hour (cur)';
is $time{'hh:mm'},     sprintf('%02d:%02d', $hr, $min)   => 'm test: hour: (cur)';
is $time{'H:mm'},      sprintf('%1d:%02d', $h12, $min)   => 'm test: Hour: (cur)';
is $time{'HH:mm'},     sprintf('%02d:%02d', $h12, $min)  => 'm test: hour12: (cur)';
is $time{'?H:m'},      sprintf('%2d:%1d', $h12, $min)    => 'm test: Hour12: (cur)';

