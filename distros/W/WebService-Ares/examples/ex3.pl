#!/usr/bin/env perl

use strict;
use warnings;

use WebService::Ares;

# Object.
my $obj = WebService::Ares->new;

# Get commands.
my @commands = $obj->commands;

# Print commands.
print join "\n", @commands;
print "\n";

# Output:
# standard