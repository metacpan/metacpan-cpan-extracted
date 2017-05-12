#!perl -T
use strict;
use Test::More;
eval "use Test::Pod 1.14";
plan skip_all => "Test::Pod 1.14 required for testing POD" if $@;
plan skip_all => "No POD files to test" unless Test::Pod::all_pod_files();
all_pod_files_ok();
