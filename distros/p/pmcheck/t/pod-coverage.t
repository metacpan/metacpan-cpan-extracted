#!/usr/bin/env perl

use strict;
use utf8;
use warnings;

use Test::More;

########################################
# Tests

## no critic (ProhibitStringyEval)
plan skip_all => 'Test::Pod::Coverage 1.04 required for testing POD coverage'
    if !eval 'use Test::Pod::Coverage 1.04; 1';

all_pod_coverage_ok();
