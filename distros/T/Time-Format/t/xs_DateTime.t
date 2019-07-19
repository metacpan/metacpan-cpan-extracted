#!/perl -I..

# Test the use of DateTime objects as input for the XS time_format function and %time tied hash.

use strict;
use Test::More tests => 12;
use FindBin;
use lib $FindBin::Bin;
use TimeFormat_MC;


## ----------------------------------------------------------------------------------
## Test for availability of certain modules.
my $dt_ok = tf_module_check('DateTime');


## ----------------------------------------------------------------------------------
## Load our module.
BEGIN { use_ok 'Time::Format', qw(time_format %time) }


## ----------------------------------------------------------------------------------
## Get day/month names in current locale; fallback to English (sorry!).
my ($Thursday, $Thu, $June, $Jun);
unless (eval
    {
        require I18N::Langinfo;
        I18N::Langinfo->import(qw(langinfo DAY_3 MON_12 DAY_5 ABDAY_5 MON_6 ABMON_6));
        ($Thursday, $Thu, $June, $Jun) = map ucfirst lc langinfo($_), (DAY_5(), ABDAY_5(), MON_6(), ABMON_6());
        1;
    })
{
    ($Thursday, $Thu, $June, $Jun) = qw(Thursday Thu June Jun);
}


## ----------------------------------------------------------------------------------
## Begin tests.

SKIP:
{
    skip 'DateTime not available',    11  unless $dt_ok;
    skip 'XS version not available',  11  unless defined $Time::Format_XS::VERSION;
    # June 5, 2003 at 1:58:09 pm
    my $t = DateTime->new (year => 2003, month => 6, day => 5, hour => 13, minute => 58, second => 9, nanosecond => 987_654_321);

    # time_format tests (5)
    is time_format('yyyymmdd', $t),  '20030605'    => 'mm month';
    is time_format('hhmmss',   $t),  '135809'      => 'mm minute';
    is time_format('MONTH',    $t),  uc $June      => 'uc month name';
    is time_format('weekday',  $t),  lc $Thursday  => 'lc weekday';
    is time_format('\QToday is\E yyyy/mm/dd hh:mm:ss.uuuuuu',  $t),  'Today is 2003/06/05 13:58:09.987654'  => 'Full timestamp';

    is  $time{'yyyymmdd', $t},  '20030605'    => 'month: mm';
    is  $time{'hhmmss',   $t},  '135809'      => 'mm minute';
    is  $time{'MONTH',    $t},  uc $June      => 'uc month name';
    is  $time{'weekday',  $t},  lc $Thursday  => 'lc weekday';
    is  $time{'\QToday is\E yyyy/mm/dd hh:mm:ss.uuuuuu',  $t},  'Today is 2003/06/05 13:58:09.000000'  => 'Full timestamp';
    is "$time{'\QToday is\E yyyy/mm/dd hh:mm:ss.uuuuuu',  $t}", 'Today is 2003/06/05 13:58:09.000000'  => 'Full timestamp';
}
