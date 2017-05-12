# ----------------------------------------------------------------
    use strict;
    use Test::More;
# ----------------------------------------------------------------
{
    my $key = $ENV{JALAN_API_KEY} if exists $ENV{JALAN_API_KEY};
    plan skip_all => 'set JALAN_API_KEY env to test this' unless $key;
    plan tests => 49;
    &test_main( $key );
}
# ----------------------------------------------------------------
sub test_main {
    my $key = shift;

    use_ok('WebService::Recruit::Jalan');
    my $jalan = WebService::Recruit::Jalan->new();
    $jalan->key( $key );

    my @time = localtime( time() + 3600 * 24 * 30 );
    my $year = $time[5] + 1900;
    my $mon  = $time[4] + 1;
    my $day  = $time[3];
    my $date = sprintf( "%04d%02d%02d", $year, $mon, $day );

    my $param = {
        s_area      =>  '137412',
        stay_date   =>  $date,
        stay_count  =>  '3',
        adult_num   =>  '2',
        count       =>  '1',
    };
    my $res = $jalan->StockSearch( %$param );
    ok( ref $res, 'StockSearch' );
#   warn $res->xml;

    my $root = $res->root;
    ok( ref $root, 'root' );
    ok( $root->NumberOfResults,     'NumberOfResults' );
    ok( $root->DisplayPerPage,      'DisplayPerPage' );
    ok( $root->DisplayFrom,         'DisplayFrom' );
    ok( $root->APIVersion,          'APIVersion' );
    ok( $root->Plan,                'Plan' );
    ok( $root->Plan->[0]->PlanName,             'PlanName' );
    ok( $root->Plan->[0]->RoomName,             'RoomName' );
    ok( $root->Plan->[0]->PlanDetailURL,        'PlanDetailURL' );
    ok( $root->Plan->[0]->Facilities,                   'Facilities' );
    ok( $root->Plan->[0]->Facilities->Facility->[0],    'Facility' );
    ok( $root->Plan->[0]->PlanCheckIn,          'PlanCheckIn' );
    ok( $root->Plan->[0]->PlanCheckOut,         'PlanCheckOut' );
    ok( $root->Plan->[0]->PlanPictureURL,       'PlanPictureURL' );
    ok( $root->Plan->[0]->PlanPictureCaption,   'PlanPictureCaption' );
    ok( $root->Plan->[0]->Meal,             'Meal' );
    ok( $root->Plan->[0]->RateType,         'RateType' );
    ok( $root->Plan->[0]->SampleRate,       'SampleRate' );
    ok( $root->Plan->[0]->Stay,             'Stay' );
    ok( $root->Plan->[0]->Stay->[0]->PlanDetailURL,     'PlanDetailURL' );
    ok( $root->Plan->[0]->Stay->[0]->Date,              'Date' );
    ok( $root->Plan->[0]->Stay->[0]->Date->[0]->date,       'date' );
    ok( $root->Plan->[0]->Stay->[0]->Date->[0]->month,  'month' );
    ok( $root->Plan->[0]->Stay->[0]->Date->[0]->year,   'year' );
    ok( $root->Plan->[0]->Stay->[0]->Date->[0]->Rate,   'Rate' );
    ok( $root->Plan->[0]->Stay->[0]->Date->[0]->Stock,  'Stock' );
    ok( $root->Plan->[0]->Hotel,                    'Hotel' );
    ok( $root->Plan->[0]->Hotel->HotelID,           'HotelID' );
    ok( $root->Plan->[0]->Hotel->HotelName,         'HotelName' );
    ok( $root->Plan->[0]->Hotel->PostCode,          'PostCode' );
    ok( $root->Plan->[0]->Hotel->HotelAddress,      'HotelAddress' );
    ok( $root->Plan->[0]->Hotel->Area,              'Area' );
    ok( $root->Plan->[0]->Hotel->Area->Region,      'Region' );
    ok( $root->Plan->[0]->Hotel->Area->Prefecture,  'Prefecture' );
    ok( $root->Plan->[0]->Hotel->Area->LargeArea,   'LargeArea' );
    ok( $root->Plan->[0]->Hotel->Area->SmallArea,   'SmallArea' );
    ok( $root->Plan->[0]->Hotel->HotelType,         'HotelType' );
    ok( $root->Plan->[0]->Hotel->HotelDetailURL,    'HotelDetailURL' );
    ok( $root->Plan->[0]->Hotel->HotelCatchCopy,    'HotelCatchCopy' );
    ok( $root->Plan->[0]->Hotel->HotelCaption,      'HotelCaption' );
    ok( $root->Plan->[0]->Hotel->PictureURL,        'PictureURL' );
    ok( $root->Plan->[0]->Hotel->PictureCaption,    'PictureCaption' );
    ok( $root->Plan->[0]->Hotel->X,                 'X' );
    ok( $root->Plan->[0]->Hotel->Y,                 'Y' );
    ok( $root->Plan->[0]->Hotel->HotelNameKana,     'HotelNameKana' );
    ok( $root->Plan->[0]->Hotel->NumberOfRatings,   'NumberOfRatings' );
    ok( $root->Plan->[0]->Hotel->Rating,            'Rating' );
}
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
