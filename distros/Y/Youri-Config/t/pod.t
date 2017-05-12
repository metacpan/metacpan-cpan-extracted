#!/usr/bin/perl
# $Id: pod.t 1582 2007-03-22 13:45:11Z guillomovitch $

use strict;
use warnings;
use Test::More;

eval "use Test::Pod 1.14";
plan(skip_all => 'Test::Pod >= 1.14 required, skipping') if $@;

all_pod_files_ok();
