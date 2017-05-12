#!perl -T

use Test::More;

plan skip_all => "Test::Pod - AUTHOR_TEST not set"
  unless $ENV{AUTHOR_TEST};

eval "use Test::Pod 1.14";
plan skip_all => "Test::Pod 1.14 required for testing POD" if $@;

all_pod_files_ok();
