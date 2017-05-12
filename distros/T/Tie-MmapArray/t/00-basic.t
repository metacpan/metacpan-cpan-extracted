#!/usr/bin/perl

use strict;
use Test;
use lib qw(blib/lib blib/arch ../blib/lib ../blib/arch);

BEGIN { plan tests => 2 };

# Test that the module loads OK

use Tie::MmapArray;
ok(1);

my @array;
eval { tie @array, 'Tie::MmapArray', undef, undef; };
ok ($@ =~ /must be a string/);

