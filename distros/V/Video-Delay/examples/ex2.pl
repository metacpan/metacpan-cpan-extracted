#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Video::Delay::Func;

# Object.
my $obj = Video::Delay::Func->new(
        'func' => '1000 * sin(t)',
        'incr' => 0.1,
);

# Print delay.
print $obj->delay."\n";
print $obj->delay."\n";
print $obj->delay."\n";

# Output:
# 99.8334166468282
# 198.669330795061
# 295.52020666134