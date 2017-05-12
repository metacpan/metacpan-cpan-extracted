#!perl -wT
# Win32::GUI::Constants test suite
# $Id: 98_pod.t,v 1.2 2006/05/16 18:57:26 robertemay Exp $
#
# - check POD syntax

use strict;
use warnings;

BEGIN { $| = 1 } # Autoflush

use Test::More;
eval "use Test::Pod 1.14";
plan skip_all => "Test::Pod 1.14 required for testing POD" if $@;
plan skip_all => "Pod tests for Win32::GUI::Constants done by core" if $ENV{W32G_CORE};
plan skip_all => 'set TEST_POD to enable this test' unless $ENV{TEST_POD};
all_pod_files_ok();
