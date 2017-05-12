#!/usr/bin/perl

# $Id: 97-pod.t 7575 2006-02-23 00:19:02Z vfelix $

use strict;
use Test::More;
use FindBin qw($Bin);
eval "use Test::Pod 1.20";
plan skip_all => "Test::Pod 1.20 required for testing POD $@" if $@;

my @poddirs = ( "$Bin/../lib" );
all_pod_files_ok( all_pod_files( @poddirs ) );
