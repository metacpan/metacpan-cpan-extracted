#!/usr/bin/perl
# $Id: 02_pod_coverage.t 2 2008-10-20 09:56:47Z rjray $

use Test::More;

our @MODULES = qw(Test::Formats Test::Formats::XML);

eval "use Test::Pod::Coverage 1.00";

plan skip_all =>
    "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@;
plan tests => scalar(@MODULES);

pod_coverage_ok($_) for (@MODULES);

exit;
