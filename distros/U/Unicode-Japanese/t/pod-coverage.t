#! perl -w

use Test::More;
eval "use Test::Pod::Coverage 1.04";
if ($@) {
    plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage";
}
else {
    plan tests => 1;
}

my $trustme = { trustme => ['^(?:load_xs)$'] };
pod_coverage_ok('Unicode::Japanese', $trustme);
