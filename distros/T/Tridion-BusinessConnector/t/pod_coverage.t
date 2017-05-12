use Test::More;
eval "use Test::Pod::Coverage tests=>1";
plan skip_all => "Test::Pod::Coverage required for testing POD" if $@;
pod_coverage_ok( "Tridion::BusinessConnector", "Tridion::BusinessConnector is covered" );
