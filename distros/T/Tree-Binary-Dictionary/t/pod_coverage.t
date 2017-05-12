use Test::More;
eval "use Test::Pod::Coverage tests=>1";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@;
pod_coverage_ok(
               "Tree::Binary::Dictionary",
           );

