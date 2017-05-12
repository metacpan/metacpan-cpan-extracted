# ----------------------------------------------------------------
    use strict;
    use Test::More;
# ----------------------------------------------------------------
{
    my $key = $ENV{JALAN_API_KEY} if exists $ENV{JALAN_API_KEY};
    plan skip_all => 'set JALAN_API_KEY env to test this' unless $key;
    plan tests => 60;
    &test_main( $key );
}
# ----------------------------------------------------------------
sub test_main {
    my $key = shift;

    use_ok('WebService::Recruit::Jalan');
    my $jalan = WebService::Recruit::Jalan->new();
    $jalan->key( $key );

    my $param = {
        s_area      =>  '162612',
        count       =>  '1',
        xml_ptn     =>  '2',
    };
    my $res = $jalan->HotelSearchAdvance( %$param );
    ok( ref $res, 'HotelSearchAdvance' );
#   warn $res->xml;

    my $root = $res->root;
    ok( ref $root, 'root' );

    ok( $root->NumberOfResults,             'NumberOfResults' );
    ok( $root->DisplayPerPage,              'DisplayPerPage' );
    ok( $root->DisplayFrom,                 'DisplayFrom' );
    ok( $root->APIVersion,                  'APIVersion' );
    ok( $root->Hotel,                       'Hotel' );
    ok( $root->Hotel->[0]->HotelID,         'HotelID' );
    ok( $root->Hotel->[0]->HotelName,       'HotelName' );
    ok( $root->Hotel->[0]->PostCode,        'PostCode' );
    ok( $root->Hotel->[0]->HotelAddress,    'HotelAddress' );
    ok( $root->Hotel->[0]->Area,            'Area' );
    ok( $root->Hotel->[0]->Area->Region,        'Region' );
    ok( $root->Hotel->[0]->Area->Prefecture,    'Prefecture' );
    ok( $root->Hotel->[0]->Area->LargeArea,     'LargeArea' );
    ok( $root->Hotel->[0]->Area->SmallArea,     'SmallArea' );
    ok( $root->Hotel->[0]->HotelType,           'HotelType' );
    ok( $root->Hotel->[0]->HotelDetailURL,      'HotelDetailURL' );
    ok( $root->Hotel->[0]->HotelCatchCopy,      'HotelCatchCopy' );
    ok( $root->Hotel->[0]->HotelCaption,        'HotelCaption' );
    ok( $root->Hotel->[0]->PictureURL->[0],     'PictureURL' );
    ok( $root->Hotel->[0]->PictureCaption->[0],             'PictureURL' );
    ok( $root->Hotel->[0]->AccessInformation,               'AccessInformation' );
    ok( $root->Hotel->[0]->AccessInformation->[0]->name,    'name' );
    ok( $root->Hotel->[0]->CheckInTime,             'CheckInTime' );
    ok( $root->Hotel->[0]->CheckOutTime,            'CheckOutTime' );
    ok( $root->Hotel->[0]->X,                       'X' );
    ok( $root->Hotel->[0]->Y,                       'Y' );
    ok( $root->Hotel->[0]->SampleRateFrom,          'SampleRateFrom' );
    ok( $root->Hotel->[0]->LastUpdate,              'LastUpdate' );
    ok( $root->Hotel->[0]->LastUpdate->day,         'day' );
    ok( $root->Hotel->[0]->LastUpdate->month,       'month' );
    ok( $root->Hotel->[0]->LastUpdate->year,        'year' );
#   ok( $root->Hotel->[0]->OnsenName,               'OnsenName' );      # could be empty
    ok( $root->Hotel->[0]->HotelNameKana,           'HotelNameKana' );
    ok( $root->Hotel->[0]->CreditCard,              'CreditCard' );
    ok( $root->Hotel->[0]->CreditCard->AMEX,        'AMEX' );
    ok( $root->Hotel->[0]->CreditCard->DC,          'DC' );
    ok( $root->Hotel->[0]->CreditCard->DINNERS,     'DINNERS' );
    ok( $root->Hotel->[0]->CreditCard->ETC,         'ETC' );
    ok( $root->Hotel->[0]->CreditCard->JCB,         'JCB' );
    ok( $root->Hotel->[0]->CreditCard->MASTER,      'MASTER' );
    ok( $root->Hotel->[0]->CreditCard->MILLION,     'MILLION' );
    ok( $root->Hotel->[0]->CreditCard->NICOS,       'NICOS' );
    ok( $root->Hotel->[0]->CreditCard->SAISON,      'SAISON' );
    ok( $root->Hotel->[0]->CreditCard->UC,          'UC' );
    ok( $root->Hotel->[0]->CreditCard->UFJ,         'UFJ' );
    ok( $root->Hotel->[0]->CreditCard->VISA,        'VISA' );
    ok( $root->Hotel->[0]->NumberOfRatings,         'NumberOfRatings' );
    ok( $root->Hotel->[0]->Rating,                  'Rating' );
    ok( $root->Hotel->[0]->Plan,                    'Plan' );
    ok( $root->Hotel->[0]->Plan->[0]->PlanName,                 'PlanName' );
    ok( $root->Hotel->[0]->Plan->[0]->RoomType->[0],            'RoomType' );
    ok( $root->Hotel->[0]->Plan->[0]->RoomName,                 'RoomName' );
    ok( $root->Hotel->[0]->Plan->[0]->PlanCheckIn,              'PlanCheckIn' );
    ok( $root->Hotel->[0]->Plan->[0]->PlanCheckOut,             'PlanCheckOut' );
    ok( $root->Hotel->[0]->Plan->[0]->PlanPictureURL,           'PlanPictureURL' );
    ok( $root->Hotel->[0]->Plan->[0]->PlanPictureCaption,       'PlanPictureCaption' );
    ok( $root->Hotel->[0]->Plan->[0]->Meal,                     'Meal' );
    ok( $root->Hotel->[0]->Plan->[0]->PlanSampleRateFrom,       'PlanSampleRateFrom' );
}
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
