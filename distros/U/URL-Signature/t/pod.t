#!perl -T

use Test::More;

plan skip_all => 'set DEVELOPER_TESTS to enable this test (developer only!)'
  unless $ENV{DEVELOPER_TESTS};

eval "use Test::Pod 1.14";
plan skip_all => "Test::Pod 1.14 required for testing POD" if $@;


all_pod_files_ok();
