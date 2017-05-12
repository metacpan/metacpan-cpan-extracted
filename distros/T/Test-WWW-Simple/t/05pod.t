use Test::More;
use Test::WWW::Simple;
plan skip_all => "Test::Pod::Coverage required for testing POD coverage"
   unless eval "use Test::Pod::Coverage";
all_pod_coverage_ok();
