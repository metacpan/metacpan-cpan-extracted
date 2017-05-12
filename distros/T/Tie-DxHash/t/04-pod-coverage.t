use Test::More;

eval "use Test::Pod::Coverage 1.05";
plan skip_all => "Test::Pod::Coverage 1.05 required for testing POD coverage"
    if $@;

all_pod_coverage_ok( { also_private => [qr/^SCALAR$/x] } );
