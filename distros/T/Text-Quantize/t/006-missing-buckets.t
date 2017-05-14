#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Text::Quantize;

my $output = quantize([26, 24, 51, 77, 21], {
    minimum => 0,
    maximum => 1024,
});

is_deeply($output, <<'OUT');
 value  ------------- Distribution ------------- count
     0 |                                         0
     1 |                                         0
     2 |                                         0
     4 |                                         0
     8 |                                         0
    16 |@@@@@@@@@@@@@@@@@@@@@@@@                 3
    32 |@@@@@@@@                                 1
    64 |@@@@@@@@                                 1
   128 |                                         0
   256 |                                         0
   512 |                                         0
  1024 |                                         0
OUT

$output = quantize([26, 24, 51, 77, 21], { maximum => 2048 });

is_deeply($output, <<'OUT');
 value  ------------- Distribution ------------- count
     8 |                                         0
    16 |@@@@@@@@@@@@@@@@@@@@@@@@                 3
    32 |@@@@@@@@                                 1
    64 |@@@@@@@@                                 1
   128 |                                         0
   256 |                                         0
   512 |                                         0
  1024 |                                         0
  2048 |                                         0
OUT

$output = quantize([26, 24, 51, 77, 21, 1051]);

is_deeply($output, <<'OUT');
 value  ------------- Distribution ------------- count
     8 |                                         0
    16 |@@@@@@@@@@@@@@@@@@@@                     3
    32 |@@@@@@                                   1
    64 |@@@@@@                                   1
   128 |                                         0
   256 |                                         0
   512 |                                         0
  1024 |@@@@@@                                   1
  2048 |                                         0
OUT

done_testing;

