#!/usr/bin/perl

# $Id: 02_pod_coverage.t 19 2006-09-20 06:03:06Z  $

use Test::More;

eval "use Test::Pod::Coverage 1.00";

plan skip_all =>
    "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@;

all_pod_coverage_ok({ also_private => [ qr/^[A-Z_]+$/, 'set_type' ] });

exit;
