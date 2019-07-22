#!/perl

use strict;
use Test::More tests => 18;
use FindBin;
use lib $FindBin::Bin;
use TimeFormat_MC;


## ----------------------------------------------------------------------------------
## Test for availability of certain modules.
my $tl_ok;
BEGIN { $tl_ok = eval ('use Time::Local; 1') }
my $posix_ok = tf_module_check('POSIX');
my ($dm_ok, $dmtz_ok) = tf_module_check('Date::Manip');


## ----------------------------------------------------------------------------------
## Load our module.
BEGIN { $Time::Format::NOXS = 1 }
BEGIN { use_ok 'Time::Format', qw(%time time_format time_strftime time_manip) }


## ----------------------------------------------------------------------------------
## Get day/month names in current locale; fallback to English (sorry!).
my ($Thursday, $Thu, $June, $Jun);
my $lc_supported = 1;
$lc_supported = 0  if $^O eq 'openbsd';
if (!$lc_supported  ||  !eval
    {
        require I18N::Langinfo;
        I18N::Langinfo->import(qw(langinfo DAY_3 MON_12 DAY_5 ABDAY_5 MON_6 ABMON_6));
        ($Thursday, $Thu, $June, $Jun) = map ucfirst lc langinfo($_), (DAY_5(), ABDAY_5(), MON_6(), ABMON_6());
        1;
    })
{
    diag 'Cannot determine locale; falling back to English.';
    ($Thursday, $Thu, $June, $Jun) = qw(Thursday Thu June Jun);
}


## ----------------------------------------------------------------------------------
## Begin tests.

my $t = 0;
if ($tl_ok)
{
    $t = timelocal(9, 58, 13, 5, 5, 103); # June 5, 2003 at 1:58:09 pm
    $t .= '.987654321';
}

SKIP:
{
    skip 'Time::Local not available', 5  unless $tl_ok;

    # time_format tests (5)
    is time_format('yyyymmdd',$t),  '20030605'       => 'month: mm';
    is time_format('hhmmss',$t),    '135809'         => 'm minute: 1';
    is time_format('MONTH',$t),     uc $June         => 'uc month name';
    is time_format('weekday',$t),   lc $Thursday     => 'lc weekday';
    is time_format('yyyymmdd'),     $time{yyyymmdd}  => 'time_format equals %time';
}


# time_strftime tests (6)
if ($posix_ok)
{
    SKIP:
    {
        skip 'Time::Local not available', 6  unless $tl_ok;

        # Be sure to use ONLY ansi standard strftime codes here,
        # otherwise the tests will fail on somebody's system somewhere.
        is time_strftime('%d',$t),  '05'             => 'day of month';
        is time_strftime('%m',$t),  '06'             => 'Month number';
        is time_strftime('%M',$t),  '58'             => 'minute';
        is time_strftime('%H',$t),  '13'             => 'hour';
        is time_strftime('%Y',$t),  '2003'           => 'year';
        is time_strftime('%M'),     $time{'mm{in}'}  => 'time_strftime equals %time';
    }
}
else
{
        is time_strftime('%d',$t),  'NO_POSIX'       => 'day of month (dummy)';
        is time_strftime('%m',$t),  'NO_POSIX'       => 'Month number (dummy)';
        is time_strftime('%M',$t),  'NO_POSIX'       => 'minute (dummy)';
        is time_strftime('%H',$t),  'NO_POSIX'       => 'hour (dummy)';
        is time_strftime('%Y',$t),  'NO_POSIX'       => 'year (dummy)';
        is time_strftime('%M'),     'NO_POSIX'       => 'time_strftime equals %time (dummy)';
}


# time_manip tests (6)
my $m = 'first thursday in june 2003';
if ($dm_ok  &&  $dmtz_ok)
{
    SKIP:
    {
        skip 'Time::Local not available', 6  unless $tl_ok;

        is time_manip('%Y',$m),  '2003'          => 'year';
        is time_manip('%d',$m),  '05'            => 'day of month';
        is time_manip('%D',$m),  '06/05/03'      => '%D';
        is time_manip('%e',$m),  ' 5'            => 'spaced day';
        is time_manip('%H',$m),  '00'            => 'hour';
        is time_manip('%H'),     $time{'hh'}     => 'time_manip equals %time';
    }
}
else
{
        is time_manip('%Y',$m),  'NO_DATEMANIP'  => 'year (dummy)';
        is time_manip('%d',$m),  'NO_DATEMANIP'  => 'day of month (dummy)';
        is time_manip('%D',$m),  'NO_DATEMANIP'  => '%D (dummy)';
        is time_manip('%e',$m),  'NO_DATEMANIP'  => 'spaced day (dummy)';
        is time_manip('%H',$m),  'NO_DATEMANIP'  => 'hour (dummy)';
        is time_manip('%H'),     'NO_DATEMANIP'  => 'time_manip equals %time (dummy)';
}
