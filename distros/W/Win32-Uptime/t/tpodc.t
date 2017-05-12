#!/usr/bin/env perl -w

# $Id: tpodc.t 22 2010-09-23 23:04:07Z stro $

use strict;
use warnings;

eval 'use Test::More';
if ($@) {
  eval 'use Test; plan tests => 1;';
  skip('Test::More is required for testing POD coverage',);
} else {
  require Test::More;
  eval 'use Test::Pod::Coverage 1.00';
  plan (skip_all => 'Test::Pod::Coverage is required for testing POD coverage') if $@;
  all_pod_coverage_ok();
}