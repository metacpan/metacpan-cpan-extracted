use strict;
use Test::More;
eval "use Test::Pod::Coverage 1.00";
if ( $@ ) {
    plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage";
} else {
    my @modules = grep { $_ ne "WebService::Etsy::Methods" } all_modules();
    plan tests => scalar @modules;
    for ( @modules ) {
        pod_coverage_ok( $_, { also_private => [ qr/^stringify$/, qr/^array$/ ] } );
    }
}

