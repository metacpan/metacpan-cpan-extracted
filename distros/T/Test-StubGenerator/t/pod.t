#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

plan skip_all => 'Author test.  Set $ENV{ TEST_AUTHOR } to enable this test.' unless $ENV{ TEST_AUTHOR };

eval "use Test::Pod 1.14";
plan skip_all => 'Test::Pod 1.14 required' if $@;

my @poddirs = qw/lib/;

all_pod_files_ok( all_pod_files( @poddirs ) );
