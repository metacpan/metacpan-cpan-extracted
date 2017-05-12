#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
eval "use Test::Synopsis";
plan skip_all => "Test::Synopsis required for testing" if $@;
all_synopsis_ok();
