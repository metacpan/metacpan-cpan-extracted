#!perl -wT
# Win32::GUI::Constants test suite
# $Id: 99_pod_coverage.t,v 1.2 2006/05/16 18:57:26 robertemay Exp $
#
# - check we have coverage of all defined functions/methods

use strict;
use warnings;

BEGIN { $| = 1 } # Autoflush

use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;
plan skip_all => "Pod Coverage tests for Win32::GUI::Constants done by core" if $ENV{W32G_CORE};
plan skip_all => 'set TEST_POD to enable this test' unless $ENV{TEST_POD};

plan tests => 2;

pod_coverage_ok(
	"Win32::GUI::Constants",
	"Win32::GUI::Constansts covered by POD");

pod_coverage_ok(
	"Win32::GUI::Constants::Tags",
	{ also_private => [ qr(^tag$) ], },
	"Win32::GUI::Constants::Tags covered by POD");

