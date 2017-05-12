#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Text::DSV;

# Object.
my $dsv = Text::DSV->new;

# Serialize.
print $dsv->serialize(
[1, 2, 3],
[4, 5, 6],
);

# Output:
# 1:2:3
# 4:5:6