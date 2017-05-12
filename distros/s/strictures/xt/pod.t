use Test::More;
use Test::Pod;
use Test::Pod::Coverage;
use strict;
use warnings FATAL => 'all';

pod_file_ok($_)
  for all_pod_files;
pod_coverage_ok($_, { coverage_class => 'Pod::Coverage::CountParents' })
  for all_modules;

done_testing;
