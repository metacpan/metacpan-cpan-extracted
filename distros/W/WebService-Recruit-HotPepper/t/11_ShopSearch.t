# ----------------------------------------------------------------
    use strict;
    use Test::More;
    use utf8;
# ----------------------------------------------------------------
{
    my $key = $ENV{HOTPEPPER_API_KEY} if exists $ENV{HOTPEPPER_API_KEY};
    plan skip_all => 'set HOTPEPPER_API_KEY env to test this' unless $key;
    plan tests => 11;
    &test_main( $key );
}
# ----------------------------------------------------------------
sub test_main {
    my $key = shift;

    use_ok('WebService::Recruit::HotPepper');
    my $doko = WebService::Recruit::HotPepper->new();
    $doko->key( $key );

    my $param = {
        Keyword => '渋谷 居酒屋',
    };
    my $res = $doko->ShopSearch( %$param );
    ok ref $res;

    my $root = $res->root;
    ok ref $root;

    ok( $root->NumberOfResults, 'NumberOfResults' );
    ok( $root->DisplayPerPage, 'DisplayPerPage' );
    ok( $root->DisplayFrom, 'DisplayFrom' );
    ok( $root->APIVersion, 'APIVersion' );

    ok ref $root->Shop->[0];
    ok $root->Shop->[0]->ShopIdFront;
    ok $root->Shop->[0]->ShopName;
    eval {
        $root->Shop->[0]->ShopIdFront;
        $root->Shop->[0]->ShopName;
        $root->Shop->[0]->ShopNameKana;
        $root->Shop->[0]->ShopAddress;
        $root->Shop->[0]->Desc;
        $root->Shop->[0]->GenreName;
        $root->Shop->[0]->ShopUrl;
        $root->Shop->[0]->KtaiShopUrl;
    };
    is $@, '';
}
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
