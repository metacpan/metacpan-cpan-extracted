#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Video::Delay::Const;

# Object.
my $obj = Video::Delay::Const->new(
        'const' => 1000,
);

# Print delay.
print $obj->delay."\n";
print $obj->delay."\n";
print $obj->delay."\n";

# Output:
# 1000
# 1000
# 1000