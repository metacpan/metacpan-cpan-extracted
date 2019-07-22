#!/perl

use strict;
use Test::More tests => 12;
use FindBin;
use lib $FindBin::Bin;
use TimeFormat_MC;

## ----------------------------------------------------------------------------------
## Test for availability of certain modules.
my ($dm_ok, $dmtz_ok) = tf_module_check('Date::Manip');


## ----------------------------------------------------------------------------------
## Load our module.
BEGIN { $Time::Format::NOXS = 1 }
BEGIN { use_ok 'Time::Format', qw(time_format %time) }


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

SKIP:
{
    skip 'Date::Manip is not available',           11  unless $dm_ok;
    skip 'Date::Manip cannot determine time zone', 11  unless $dmtz_ok;

    require Date::Manip;
    my $t = Date::Manip::ParseDate('June 5, 2003 at 1:58:09 pm');

    # time_format tests (5)
    is time_format('yyyymmdd', $t),  '20030605'    => 'mm month';
    is time_format('hhmmss',   $t),  '135809'      => 'mm minute';
    is time_format('MONTH',    $t),  uc $June      => 'uc month name';
    is time_format('weekday',  $t),  lc $Thursday  => 'lc weekday';
    is time_format('\QToday is\E yyyy/mm/dd hh:mm:ss',  $t),  'Today is 2003/06/05 13:58:09'  => 'Full timestamp';

    is $time{'yyyymmdd', $t},  '20030605'    => 'month: mm';
    is $time{'hhmmss',   $t},  '135809'      => 'mm minute';
    is $time{'MONTH',    $t},  uc $June      => 'uc month name';
    is $time{'weekday',  $t},  lc $Thursday  => 'lc weekday';
    is  $time{'\QToday is\E yyyy/mm/dd hh:mm:ss',  $t},  'Today is 2003/06/05 13:58:09'  => 'Full timestamp';
    is "$time{'\QToday is\E yyyy/mm/dd hh:mm:ss',  $t}", 'Today is 2003/06/05 13:58:09'  => 'Full timestamp';
}
