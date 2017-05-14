#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Text::Quantize;

my $output = quantize([26, 24, 51, 77, 21]);
is_deeply($output, <<'OUT');
 value  ------------- Distribution ------------- count
     8 |                                         0
    16 |@@@@@@@@@@@@@@@@@@@@@@@@                 3
    32 |@@@@@@@@                                 1
    64 |@@@@@@@@                                 1
   128 |                                         0
OUT

done_testing;

