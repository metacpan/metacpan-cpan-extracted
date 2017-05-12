#!perl
use strict;
use warnings;

use Test::More;

BEGIN {
    eval 'use Test::Pod 1.00;';
    plan skip_all => 'Test::Pod 1.00 required for this test' if $@;
}

all_pod_files_ok();

