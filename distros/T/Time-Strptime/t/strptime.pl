#!perl
use strict;
use warnings;
use Time::Strptime qw/strptime/;
print join " ", strptime(@ARGV);
