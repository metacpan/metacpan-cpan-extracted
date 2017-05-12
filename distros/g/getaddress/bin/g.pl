#!/usr/bin/perl

use strict;
use warnings;

use Test::More; 
BEGIN { use_ok('getaddress') };

use Encode qw(from_to);

my $datafile = './data/QQWry.Dat';

my $str = &ipwhere('221.203.140.26', $datafile);
from_to($str, "GBK", "UTF8");
print $str, "\n";
done_testing();
