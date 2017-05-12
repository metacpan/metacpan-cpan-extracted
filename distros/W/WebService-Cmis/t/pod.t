#!perl -T

use strict;
use warnings;

use Test::More;
use Test::Pod;

# Ensure a recent version of Test::Pod
my $min_tp = 1.22;

all_pod_files_ok();
