use strict;
use Test::More;
use Test::Pod;

plan skip_all => 'set TEST_POD to enable this test (developer only!)'
        unless $ENV{TEST_POD};

all_pod_files_ok();
