#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;

use_ok('fp::lambda');

cmp_ok(first(pair(\&one)->(\&two)), '==', \&one, "first pair 1 2 == 1");
cmp_ok(first(pair(\&one)->(\&two)), '!=', \&two, "first pair 1 2 != 2");

cmp_ok(second(pair(\&one)->(\&two)), '!=', \&one, "second pair 1 2 != 1");
cmp_ok(second(pair(\&one)->(\&two)), '==', \&two, "second pair 1 2 == 2");
