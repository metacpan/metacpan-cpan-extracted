#!/usr/env perl -w

# $Id: uptime.pl 22 2010-09-23 23:04:07Z stro $

use strict;
use warnings;
use Win32::Uptime;
use integer;

my $uptime = Win32::Uptime::uptime();
my $d   = $uptime / 86400000; # days
$uptime = $uptime % 86400000;
my $h   = $uptime / 3600000; # hours
$uptime = $uptime % 3600000;
my $m   = $uptime / 60000; # minutes
$uptime = $uptime % 60000;
my $s   = $uptime / 1000; # seconds

print 'Your system has been up for: ',
      $d, ' day(s), ',
      $h, ' hour(s), ',
      $m, ' minute(s), ',
      $s, " second(s)\n";
