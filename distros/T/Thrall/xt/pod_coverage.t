#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Test::Pod::Coverage 1.04 tests => 1;

pod_coverage_ok('Thrall');
