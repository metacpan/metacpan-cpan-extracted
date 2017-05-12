# ----------------------------------------------------------------
    use strict;
    use Test::More;
# ----------------------------------------------------------------
{
    my $key = $ENV{JALAN_API_KEY} if exists $ENV{JALAN_API_KEY};
    plan skip_all => 'set JALAN_API_KEY env to test this' unless $key;
    plan tests => 33;
    &test_main( $key );
}
# ----------------------------------------------------------------
sub test_main {
    my $key = shift;

    use_ok('WebService::Recruit::Jalan');
    my $jalan = WebService::Recruit::Jalan->new();
    $jalan->key( $key );

    my $param = {
        pref    =>  '160000',
        l_area  =>  '162600',
        s_area  =>  '162612',
        h_type  =>  '1',
        start   =>  '1',
        count   =>  '1',
    };
    my $res = $jalan->HotelSearchLite( %$param );
    ok( ref $res, 'HotelSearchLite' );
#   warn $res->xml;

    my $root = $res->root;
    ok( ref $root, 'root' );

    ok( $root->NumberOfResults,     'NumberOfResults' );
    ok( $root->DisplayPerPage,      'DisplayPerPage' );
    ok( $root->DisplayFrom,         'DisplayFrom' );
    ok( $root->APIVersion,          'APIVersion' );
    ok( $root->Hotel,               'Hotel' );
    ok( $root->Hotel->[0]->HotelID,         'HotelID' );
    ok( $root->Hotel->[0]->HotelName,       'HotelName' );
    ok( $root->Hotel->[0]->PostCode,        'PostCode' );
    ok( $root->Hotel->[0]->HotelAddress,    'HotelAddress' );
    ok( $root->Hotel->[0]->Area,            'Area' );
    ok( $root->Hotel->[0]->Area->Region,    'Region' );
    ok( $root->Hotel->[0]->Area->Prefecture, 'Prefecture' );
    ok( $root->Hotel->[0]->Area->LargeArea, 'LargeArea' );
    ok( $root->Hotel->[0]->Area->SmallArea, 'SmallArea' );
    ok( $root->Hotel->[0]->HotelType,       'HotelType' );
    ok( $root->Hotel->[0]->HotelDetailURL,  'HotelDetailURL' );
    ok( $root->Hotel->[0]->HotelCatchCopy,  'HotelCatchCopy' );
    ok( $root->Hotel->[0]->HotelCaption,    'HotelCaption' );
    ok( $root->Hotel->[0]->PictureURL,      'PictureURL' );
    ok( $root->Hotel->[0]->PictureCaption,  'PictureCaption' );
    ok( $root->Hotel->[0]->AccessInformation,               'AccessInformation' );
    ok( $root->Hotel->[0]->AccessInformation->[0]->name,    'name' );
    ok( $root->Hotel->[0]->CheckInTime,     'CheckInTime' );
    ok( $root->Hotel->[0]->CheckOutTime,    'CheckOutTime' );
    ok( $root->Hotel->[0]->X,               'X' );
    ok( $root->Hotel->[0]->Y,               'Y' );
    ok( $root->Hotel->[0]->LastUpdate,      'LastUpdate' );
    ok( $root->Hotel->[0]->LastUpdate->day,     'day' );
    ok( $root->Hotel->[0]->LastUpdate->month,   'month' );
    ok( $root->Hotel->[0]->LastUpdate->year,    'year' );
}
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
