#!/usr/bin/env perl

use v5.12;
use strict;
use warnings;

use FindBin qw/$Bin/;
use lib '$Bin/../lib';

use Util::H2O::More qw/d2o ddd/;

my $hash = d2o -autoundef, {
  thirteen => 13,
  foo      => {
    nine => 9,
  },
};

if (not $hash->twelve) {
  say "'twelve' is not set or doesn't exist"; 
}

if (not $hash->foo->eight) {
  say "'foo->eight' is not set or doesn't exist"; 
}

$hash->foo->eight(8);
