#!perl -wT
# Win32::GUI::DropFiles test suite.
# $Id: 99_pod_coverage.t,v 1.1 2006/04/25 21:39:53 robertemay Exp $

# Check the POD covers all method calls

use strict;
use warnings;

use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;
plan skip_all => 'set TEST_POD to enable this test' unless $ENV{TEST_POD};

plan tests => 1;

TODO: {
    local $TODO = "Tests for Win32::GUI POD coverage not yet written";
    fail("Win32::GUI POD Coverage tests");
}

# all_pod_coverage_ok is not even close to what we need!
# all_pod_coverage_ok();
