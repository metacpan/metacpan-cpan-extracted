use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;

plan 'no_plan';
my $trustme = { trustme => [qr/^(?:new|parse)$/] };
pod_coverage_ok('URI::Template::Restrict', $trustme);
pod_coverage_ok('URI::Template::Restrict::Expansion', $trustme);
