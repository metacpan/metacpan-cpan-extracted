#!/usr/bin/env perl
use strict;
use warnings;

use Text::Dice;

die "Usage: $0 \$string1 \$string2" unless 2 == @ARGV;

printf "%.2f\n", coefficient @ARGV;
