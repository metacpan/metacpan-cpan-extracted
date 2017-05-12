use Test::More;

eval 'use Test::Pod::Coverage 1.04';

plan(skip_all => 'Test::Pod::Coverage 1.04 needed for POD coverage tests')
  if $@;

all_pod_coverage_ok();
