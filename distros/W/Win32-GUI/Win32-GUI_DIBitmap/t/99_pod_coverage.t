#!perl -wT
# Win32::GUI::DIBitmap test suite.
# $Id: 99_pod_coverage.t,v 1.1 2006/06/11 16:34:48 robertemay Exp $

# Check the POD covers all method calls

use strict;
use warnings;

use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;
plan skip_all => "Pod Coverage tests for Win32::GUI::DIBitmap done by core" if $ENV{W32G_CORE};
plan skip_all => 'set TEST_POD to enable this test' unless $ENV{TEST_POD};
all_pod_coverage_ok( { also_private => [ qr/^constant$/ ] } );
