#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Dumpvalue;
use Text::DSV;

# Object.
my $dsv = Text::DSV->new;

# Parse data.
my @datas = $dsv->parse(<<'END');
1:2:3
# Comment

4:5:6
END

# Dump data.
my $dump = Dumpvalue->new;
$dump->dumpValues(\@datas);

# Output like this:
# 0  ARRAY(0x8fcb6c8)
#    0  ARRAY(0x8fd31a0)
#       0  1
#       1  2
#       2  3
#    1  ARRAY(0x8fd3170)
#       0  4
#       1  5
#       2  6