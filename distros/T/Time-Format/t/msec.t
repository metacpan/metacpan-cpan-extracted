#!/perl -I..

# Replicate the bug where microseconds and  milliseconds show up as negative numbers.

use strict;
use Test::More tests => 41;

BEGIN { $Time::Format::NOXS = 1 }
BEGIN { use_ok 'Time::Format', qw(:all) }
my $hr_ok;
BEGIN { $hr_ok = eval('use Time::HiRes qw(usleep); 1')? 1 : 0 }

#SKIP:
{
#    skip 'Time::HiRes not available', 40 if $hr_notok;

    my @vals;
    for (1..20)
    {
        push @vals, "$_: $time{'yyyy/mm/dd hh:mm:ss.mmm'}    -- milli";
        push @vals, "$_: $time{'yyyy/mm/dd hh:mm:ss.uuuuuu'} -- micro";

        if ($hr_ok)
        {
            usleep(180_000);  # 180 ms
        }
        else
        {
            sleep 2;
        }
    }

    my $count = 0;
    foreach my $str (@vals)
    {
        ++$count;
        ok $str !~ /\d\.-\d/, "Bug test $count ($str)";
    }
}
