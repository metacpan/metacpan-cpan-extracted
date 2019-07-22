#!/perl

use strict;
use Test::More tests => 6;
use FindBin;
use lib $FindBin::Bin;
use TimeFormat_MC;


## ----------------------------------------------------------------------------------
## Test for availability of certain modules.
my ($dm_ok, $dmtz_ok) = tf_module_check('Date::Manip');


## ----------------------------------------------------------------------------------
## Load our module.
BEGIN { $Time::Format::NOXS = 1 }
BEGIN { use_ok 'Time::Format', qw(%manip) }


## ----------------------------------------------------------------------------------
## Begin tests.

my $t = 'first thursday in june 2003';

SKIP:
{
    skip 'Date::Manip is not available',           5  unless $dm_ok;
    skip 'Date::Manip cannot determine time zone', 5  unless $dmtz_ok;
    is $manip{'%Y',$t},      '2003'      => 'year';
    is $manip{'%d',$t},      '05'        => 'day of month';
    is $manip{'%D',$t},      '06/05/03'  => '%D';
    is $manip{'%e',$t},      ' 5'        => 'spaced day';
    is $manip{'%H',$t},      '00'        => 'hour';
}
