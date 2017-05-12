#!/usr/bin/perl

use strict;
use warnings;

my $num = 1;
while(<>)
{
    chomp;
    if (/^plan (\d+)..(\d+)/)
    {
        print "plan $1..$2\n";
    }
    elsif (/^ok (\d+)\+(\d+)==(\d+)$/)
    {
        if ($1+$2 == $3)
        {
            print "ok $num\n";
        }
        else
        {
            print "not ok $num\n";
        }
        $num++;
    }
}

