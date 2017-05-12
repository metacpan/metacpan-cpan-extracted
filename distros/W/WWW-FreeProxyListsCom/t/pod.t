#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

# Ensure a recent version of Test::Pod
my $min_tp = 1.22;
eval { require Test::Pod; Test::Pod->import };
plan skip_all => "Test::Pod required for testing POD" if $@;

all_pod_files_ok();

