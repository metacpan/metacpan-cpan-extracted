#!/usr/bin/perl

use strict;
use Test::More;

eval "use Test::Pod::Coverage";

plan skip_all => "Test::Pod::Coverage required" if $@;

plan tests => 1;

pod_coverage_ok("Text::Truncate");

