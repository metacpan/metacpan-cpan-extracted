#!/usr/bin/env perl

use strict;
use warnings;

use lib qw(lib ../lib);
use Test::GetVolatileData;


my $num = get_data('http://zoffix.com/CPAN/WWW-Purolator-TrackingInfo.txt');

print "Got tracking number $num\n";


