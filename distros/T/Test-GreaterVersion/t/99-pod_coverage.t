use Test::More;

my $module='Test::GreaterVersion';

eval "use Test::Pod::Coverage 1.00";
if ($@) {
    plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD" ;
} else {
    plan tests => 1;
}
pod_coverage_ok($module, "$module is covered");


