use Test2::V0;
use Test2::Bundle::More;
use Test::Pod;

subtest 'pod parsing tests' => sub {
  all_pod_files_ok();
};

# even in todo some failures are not given amnesty.
# use Test::Pod::Coverage;
# todo 'Test POD Coverage (hint it is never expected to be 100%)' => sub {
#   all_pod_coverage_ok();
# };

done_testing;
