#!/perl

use strict;
use Test::More tests => 8;
use FindBin;
use lib $FindBin::Bin;
use TimeFormat_Minute;

# XS TEST: Only need to test the %time and time_format parts.

## ----------------------------------------------------------------------------------
## Test for availability of Time::Local
my $tl_ok;
BEGIN {$tl_ok = eval ('use Time::Local; 1')}


sub isx (&@)
{
    my ($got_block, $expected, $test_name) = @_;
    my $got;

    if (eval {$got = $got_block->(); 1})
    {
        is $got, $expected, $test_name;
    }
    else
    {
        my $ex = $@;
        my ($pkg, $fname, $line) = caller;
        diag "Failed test '$test_name";
        diag "at $fname line $line";
        diag "Exception: $ex";
        fail $test_name;
    }
}


## ----------------------------------------------------------------------------------
## Load our module.
BEGIN { use_ok 'Time::Format', qw(%time time_format) }


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
    skip 'Time::Local not available', 7  unless $tl_ok;
    skip 'XS version not available',  7  unless defined $Time::Format_XS::VERSION;
    my $t = timelocal(9, 58, 13, 5, 5, 103);    # June 5, 2003 at 1:58:09 pm
    $t .= '.987654321';

    # time_format tests (7)
    is time_format('yyyymmdd',$t),  '20030605'  => 'month: mm';
    is time_format('hhmmss',$t),    '135809'    => 'm minute: 1';
    is time_format('MONTH',$t),    uc $June      => 'uc month name';
    is time_format('weekday',$t),  lc $Thursday  => 'lc weekday';

    tf_minute_sync;             # avoid race condition
    isx { time_format('yyyymmdd') }          $time{yyyymmdd}  => 'time_format equals %time (ymd)';
    isx { time_format('hh:mm') }             $time{'hh:mm'}   => 'time_format equals %time (hm)';
    isx { time_format('yyyy-mm-dd hh:mm') }  tf_cur_minute()  => 'ymd+hm';
}
