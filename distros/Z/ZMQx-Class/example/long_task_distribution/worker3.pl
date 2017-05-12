#!/usr/bin/env perl
use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/lib";
use LongTaskDistribution::Worker;

LongTaskDistribution::Worker->new(
    address  => 'tcp://localhost:10005',
    priority => 3,
)->start;
