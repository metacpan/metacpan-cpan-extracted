#! perl -I. -w
use t::Test::abeltje;

SKIP: {
    skip("This perl is not >= 5.12.0", 3) if $] < 5.012;
    require_ok( 'V' );

    my $version = V::get_version('PkgWithVersion');

    is($version, 0.42, "Got version: $version");

    my $version2 = V::get_version('PkgWithVersion2');

    is($version2, "v1.42.00", "Got version: $version2");
}

abeltje_done_testing();
