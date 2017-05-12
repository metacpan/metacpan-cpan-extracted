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
        ServiceAreaCD => 'SA11',
    };
    my $res = $doko->GourmetSearch( %$param );
    ok( ref $res, 'GourmetSearch' );

    my $root = $res->root;
    ok( ref $root, 'root' );

    ok( $root->NumberOfResults, 'NumberOfResults' );
    ok( $root->DisplayPerPage, 'DisplayPerPage' );
    ok( $root->DisplayFrom, 'DisplayFrom' );
    ok( $root->APIVersion, 'APIVersion' );

    ok( ref $root->Shop->[0],            'shop' );
    ok $root->Shop->[0]->ShopIdFront;
    ok $root->Shop->[0]->ShopName;
    eval {
        $root->Shop->[0]->ShopIdFront;
        $root->Shop->[0]->ShopNameKana;
        $root->Shop->[0]->ShopName;
        $root->Shop->[0]->ShopAddress;
        $root->Shop->[0]->StationName;
        $root->Shop->[0]->KtaiCoupon;
        $root->Shop->[0]->LargeServiceAreaCD;
        $root->Shop->[0]->LargeServiceAreaName;
        $root->Shop->[0]->ServiceAreaCD;
        $root->Shop->[0]->ServiceAreaName;
        $root->Shop->[0]->LargeAreaCD;
        $root->Shop->[0]->LargeAreaName;
        $root->Shop->[0]->MiddleAreaCD;
        $root->Shop->[0]->MiddleAreaName;
        $root->Shop->[0]->SmallAreaCD;
        $root->Shop->[0]->SmallAreaName;
        $root->Shop->[0]->Latitude;
        $root->Shop->[0]->Longitude;
        $root->Shop->[0]->GenreCD;
        $root->Shop->[0]->GenreName;
        $root->Shop->[0]->FoodCD;
        $root->Shop->[0]->FoodName;
        $root->Shop->[0]->GenreCatch;
        $root->Shop->[0]->ShopCatch;
        $root->Shop->[0]->BudgetCD;
        $root->Shop->[0]->BudgetDesc;
        $root->Shop->[0]->BudgetAverage;
        $root->Shop->[0]->Capacity;
        $root->Shop->[0]->Access;
        $root->Shop->[0]->KtaiAccess;
        $root->Shop->[0]->ShopUrl;
        $root->Shop->[0]->KtaiShopUrl;
        $root->Shop->[0]->KtaiQRUrl;
        $root->Shop->[0]->PictureUrl->PcLargeImg;
        $root->Shop->[0]->PictureUrl->PcMiddleImg;
        $root->Shop->[0]->PictureUrl->PcSmallImg;
        $root->Shop->[0]->PictureUrl->MbLargeImg;
        $root->Shop->[0]->PictureUrl->MbSmallImg;
        $root->Shop->[0]->Open;
        $root->Shop->[0]->Close;
        $root->Shop->[0]->PartyCapacity;
        $root->Shop->[0]->Wedding;
        $root->Shop->[0]->Course;
        $root->Shop->[0]->FreeDrink;
        $root->Shop->[0]->FreeFood;
        $root->Shop->[0]->PrivateRoom;
        $root->Shop->[0]->Horigotatsu;
        $root->Shop->[0]->Tatami;
        $root->Shop->[0]->Card;
        $root->Shop->[0]->NonSmoking;
        $root->Shop->[0]->Charter;
        $root->Shop->[0]->Ktai;
        $root->Shop->[0]->Parking;
        $root->Shop->[0]->BarrierFree;
        $root->Shop->[0]->Sommelier;
        $root->Shop->[0]->OpenAir;
        $root->Shop->[0]->Show;
        $root->Shop->[0]->Equipment;
        $root->Shop->[0]->Karaoke;
        $root->Shop->[0]->Band;
        $root->Shop->[0]->Tv;
        $root->Shop->[0]->English;
        $root->Shop->[0]->Pet;
        $root->Shop->[0]->Child;
    };
    is $@, '';
}
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
