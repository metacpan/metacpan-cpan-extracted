#!/perl -I..

use strict;
use Test::More tests => 5;

# XS TEST: Only need to test the %time and time_format parts.

## ----------------------------------------------------------------------------------
## Test for availability of certain modules.
my $tl_ok;
BEGIN {$tl_ok = eval ('use Time::Local; 1')}


## ----------------------------------------------------------------------------------
## Load our module.
BEGIN { use_ok 'Time::Format', qw(time_format time_strftime time_manip) }


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
    skip 'Time::Local not available', 4  unless $tl_ok;
    skip 'XS version not available',  4  unless defined $Time::Format_XS::VERSION;
    my $t = timelocal(9, 58, 13, 5, 5, 103);    # June 5, 2003 at 1:58:09 pm
    $t .= '.987654321';

    # time_format tests (4)
    is time_format('yyyymmdd',$t),  '20030605'  => 'month: mm';
    is time_format('hhmmss',$t),    '135809'    => 'm minute: 1';
    is time_format('MONTH',$t),    uc $June      => 'uc month name';
    is time_format('weekday',$t),  lc $Thursday  => 'lc weekday';
}
