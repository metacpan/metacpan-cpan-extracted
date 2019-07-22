#!/perl

# Test examples in the docs, so we know we're not misleading anyone.

use strict;
use Test::More tests => 26;
use FindBin;
use lib $FindBin::Bin;
use TimeFormat_MC;

## ----------------------------------------------------------------------------------
## Test for availability of certain modules.
my $tl_ok;
BEGIN { $tl_ok = eval('use Time::Local; 1') }
my ($dm_ok, $dmtz_ok) = tf_module_check('Date::Manip');
my $posix_ok = tf_module_check('POSIX');


## ----------------------------------------------------------------------------------
## Load our module.
BEGIN { $Time::Format::NOXS = 1 }
BEGIN { use_ok 'Time::Format', qw(:all) }


## ----------------------------------------------------------------------------------
## Begin tests.

# Were all variables imported? (3)
is ref tied %time,     'Time::Format'   =>  '%time imported';
is ref tied %strftime, 'Time::Format'   =>  '%strftime imported';
is ref tied %manip,    'Time::Format'   =>  '%manip imported';

# Get day/month names in current locale
my ($Tuesday, $December, $Thursday, $Thu, $June, $Jun);
unless (eval
    {
        require I18N::Langinfo;
        I18N::Langinfo->import(qw(langinfo DAY_3 MON_12 DAY_5 ABDAY_5 MON_6 ABMON_6));
        ($Tuesday, $December, $Thursday, $Thu, $June, $Jun) = map langinfo($_), (DAY_3(), MON_12(), DAY_5(), ABDAY_5(), MON_6(), ABMON_6());
        1;
    })
{
    ($Tuesday, $December, $Thursday, $Thu, $June, $Jun) = qw(Tuesday December Thursday Thu June Jun);
}

my $t = 0;
if ($tl_ok)
{
    $t = timelocal(9, 58, 13, 5, 5, 103);    # June 5, 2003 at 1:58:09 pm
    $t .= '.987654321';
}

SKIP:
{
    skip 'Time::Local not available', 18  unless $tl_ok;

    # Synopsis tests (5)
    is "Today is $time{'yyyy/mm/dd',$t}", 'Today is 2003/06/05'   => 'Today';
    is "Yesterday was $time{'yyyy/mm/dd', $t-24*60*60}", 'Yesterday was 2003/06/04'  => 'Yesterday';
    is "The time is $time{'hh:mm:ss',$t}", 'The time is 13:58:09'    => 'time';
    is "Another time is $time{'H:mm am', $t}", 'Another time is 1:58 pm'             => 'Another time';
    is "Timestamp: $time{'yyyymmdd.hhmmss.mmm',$t}", 'Timestamp: 20030605.135809.987'   => 'Timestamp';

    SKIP:
    {
        skip 'Date::Manip is not available',           1  unless $dm_ok;
        skip 'Date::Manip cannot determine time zone', 1  unless $dmtz_ok;

        is qq[$time{'yyyymmdd',$manip{'%s',"epoch $t"}}],       '20030605'      => 'Example 15';
    }

    # Examples section (12)
    is $time{'Weekday Month d, yyyy',$t},   "$Thursday $June 5, 2003"       => 'Example 1';
    is $time{'Day Mon d, yyyy',$t},         "$Thu $Jun 5, 2003"             => 'Example 2';
    is $time{'dd/mm/yyyy',$t},              "05/06/2003"                    => 'Example 3';
    is $time{'yymmdd',$t},                  "030605"                        => 'Example 4';
    is $time{'dth of Month',$t},            "5th of $June"                  => 'Example 5';

    is $time{'H:mm:ss am',$t},              "1:58:09 pm"                    => 'Example 6';
    is $time{'hh:mm:ss.uuuuuu',$t},         "13:58:09.987654"               => 'Example 7';

    is $time{'yyyy/mm{on}/dd hh:mm{in}:ss.mmm',$t},   '2003/06/05 13:58:09.987'     => 'Example 8';
    is $time{'yyyy/mm/dd hh:mm:ss.mmm',$t},           '2003/06/05 13:58:09.987'     => 'Example 9';

    is $time{"It's H:mm.",$t},              "It'9 1:58."                    => 'Example 10';
    is $time{"It'\\s H:mm.",$t},            "It's 1:58."                    => 'Example 11';

    is $strftime{'%A %B %d, %Y',$t},        "$Thursday $June 05, 2003"      => 'Example 12';
}

# POSIX synopsis tests (2)
if ($posix_ok)
{
    SKIP:
    {
        skip 'Time::Local not available', 2  unless $tl_ok;
        is "POSIXish: $strftime{'%A, %B %d, %Y', 0,0,0,12,11,95,2}", "POSIXish: $Tuesday, $December 12, 1995"   => 'POSIX 1';
        is "POSIXish: $strftime{'%A, %B %d, %Y', int $t}",           "POSIXish: $Thursday, $June 05, 2003"      => 'POSIX 2';
    }
}
else
{
        is "POSIXish: $strftime{'%A, %B %d, %Y', 0,0,0,12,11,95,2}", "POSIXish: NO_POSIX"   => 'POSIX 1 (dummy)';
        is "POSIXish: $strftime{'%A, %B %d, %Y', int $t}",           "POSIXish: NO_POSIX"   => 'POSIX 2 (dummy)';
}

# manip tests (3)
if ($dm_ok  &&  $dmtz_ok)
{
    SKIP:
    {
        skip 'Time::Local not available', 2  unless $tl_ok;
        is $manip{'%m/%d/%Y',"epoch $t"},                       '06/05/2003'    => 'Example 13';
        is $manip{'%m/%d/%Y','first monday in November 2000'},  '11/06/2000'    => 'Example 14';
    }
}
else
{
        is $manip{'%m/%d/%Y',"epoch $t"},                       'NO_DATEMANIP'    => 'Example 13 (dummy)';
        is $manip{'%m/%d/%Y','first monday in November 2000'},  'NO_DATEMANIP'    => 'Example 14 (dummy)';
}
