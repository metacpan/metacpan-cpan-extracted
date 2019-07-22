#!/perl

use strict;
use Test::More tests => 6;
use FindBin;
use lib $FindBin::Bin;
use TimeFormat_MC;

## ----------------------------------------------------------------------------------
## Test for availability of certain modules.
my $posix_ok = tf_module_check('POSIX');
my $tl_ok;
BEGIN { $tl_ok = eval ('use Time::Local; 1') }


## ----------------------------------------------------------------------------------
## Load our module.
BEGIN { $Time::Format::NOXS = 1 }
BEGIN { use_ok 'Time::Format', qw(%strftime) }


## ----------------------------------------------------------------------------------
## Begin tests.

my $t = 0;
if ($tl_ok)
{
    $t = timelocal(9, 58, 13, 5, 5, 103); # June 5, 2003 at 1:58:09 pm
    $t .= '.987654321';
}

if ($posix_ok)
{
    SKIP:
    {
        skip 'Time::Local is not available', 5  unless $tl_ok;

        # Be sure to use ONLY ansi standard strftime codes here,
        # otherwise the tests will fail on somebody's system somewhere.
        is $strftime{'%d',$t},      '05'        => 'day of month';
        is $strftime{'%m',$t},      '06'        => 'Month number';
        is $strftime{'%M',$t},      '58'        => 'minute';
        is $strftime{'%H',$t},      '13'        => 'hour';
        is $strftime{'%Y',$t},      '2003'      => 'year';
    }
}
else
{
        is $strftime{'%d',$t},      'NO_POSIX'  => 'day of month (dummy)';
        is $strftime{'%m',$t},      'NO_POSIX'  => 'Month number (dummy)';
        is $strftime{'%M',$t},      'NO_POSIX'  => 'minute (dummy)';
        is $strftime{'%H',$t},      'NO_POSIX'  => 'hour (dummy)';
        is $strftime{'%Y',$t},      'NO_POSIX'  => 'year (dummy)';
}
