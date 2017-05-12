use strict;
use warnings;
use Test::More;

plan skip_all => 'RELEASE_TESTING is required' unless $ENV{RELEASE_TESTING};

eval 'use Test::Pod 1.45';
plan skip_all => 'Test::Pod 1.45 required for testing POD' if $@;

all_pod_files_ok();
