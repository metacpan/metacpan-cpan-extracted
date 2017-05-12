use Test::Most;
eval "use Test::Pod::Coverage";
plan skip_all => "Test::Pod::Coverage required for testing POD coverage" if $@;
pod_coverage_ok('Test::WWW::Selenium::More');
done_testing;
