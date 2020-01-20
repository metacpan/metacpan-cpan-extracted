#!/usr/bin/env perl

use strict;
use warnings;

use Video::Delay::Array;

# Object.
my $obj = Video::Delay::Array->new(
        'array' => [1000, 2000],
        'loop' => 1,
);

# Print delay.
print $obj->delay."\n";
print $obj->delay."\n";
print $obj->delay."\n";

# Output:
# 1000
# 2000
# 1000