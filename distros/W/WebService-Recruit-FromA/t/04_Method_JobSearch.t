#
# Test case for WebService::Recruit::FromA::JobSearch
#

use strict;
use Test::More;

{
    my $errs = [];
    foreach my $key ('WEBSERVICE_RECRUIT_FROMA_KEY') {
        next if exists $ENV{$key};
        push(@$errs, $key);
    }
    plan skip_all => sprintf('set %s env to test this', join(", ", @$errs))
        if @$errs;
}
plan tests => 78;

use_ok('WebService::Recruit::FromA::JobSearch');

my $service = new WebService::Recruit::FromA::JobSearch();

ok( ref $service, 'new WebService::Recruit::FromA::JobSearch()' );


# Test[0]
{
    my $params = {
        'api_key' => $ENV{'WEBSERVICE_RECRUIT_FROMA_KEY'},
        'ksjcd' => '04',
        'shrt_indx_cd' => '1001',
    };
    my $res = new WebService::Recruit::FromA::JobSearch();
    $res->add_param(%$params);
    eval { $res->request(); };
    ok( ! $@, 'Test[0]: die' );
    ok( ! $res->is_error, 'Test[0]: is_error' );
    my $data = $res->root;
    ok( ref $data, 'Test[0]: root' );
    can_ok( $data, 'Code' );
    ok( eval { $data->Code }, 'Test[0]: Code' );
    can_ok( $data, 'TotalOfferAvailable' );
    ok( eval { $data->TotalOfferAvailable }, 'Test[0]: TotalOfferAvailable' );
    can_ok( $data, 'TotalOfferReturned' );
    ok( eval { $data->TotalOfferReturned }, 'Test[0]: TotalOfferReturned' );
    can_ok( $data, 'PageNumber' );
    ok( eval { $data->PageNumber }, 'Test[0]: PageNumber' );
    can_ok( $data, 'EditionName' );
    ok( eval { $data->EditionName }, 'Test[0]: EditionName' );
    can_ok( $data, 'Offer' );
    ok( eval { $data->Offer }, 'Test[0]: Offer' );
    ok( eval { ref $data->Offer } eq 'ARRAY', 'Test[0]: Offer' );
    can_ok( $data->Offer->[0], 'Catch' );
    ok( eval { $data->Offer->[0]->Catch }, 'Test[0]: Catch' );
    can_ok( $data->Offer->[0], 'OfferId' );
    ok( eval { $data->Offer->[0]->OfferId }, 'Test[0]: OfferId' );
    can_ok( $data->Offer->[0], 'OfferStartDate' );
    ok( eval { $data->Offer->[0]->OfferStartDate }, 'Test[0]: OfferStartDate' );
    can_ok( $data->Offer->[0], 'OfferEndDate' );
    ok( eval { $data->Offer->[0]->OfferEndDate }, 'Test[0]: OfferEndDate' );
    can_ok( $data->Offer->[0], 'Prefecture' );
    ok( eval { $data->Offer->[0]->Prefecture }, 'Test[0]: Prefecture' );
    can_ok( $data->Offer->[0], 'City' );
    ok( eval { $data->Offer->[0]->City }, 'Test[0]: City' );
    can_ok( $data->Offer->[0], 'VisualIndices' );
    ok( eval { $data->Offer->[0]->VisualIndices }, 'Test[0]: VisualIndices' );
    can_ok( $data->Offer->[0], 'TimeIndices' );
    ok( eval { $data->Offer->[0]->TimeIndices }, 'Test[0]: TimeIndices' );
    can_ok( $data->Offer->[0], 'MinimumWorkDays' );
    ok( eval { $data->Offer->[0]->MinimumWorkDays }, 'Test[0]: MinimumWorkDays' );
    can_ok( $data->Offer->[0], 'ShortIndex' );
    ok( eval { $data->Offer->[0]->ShortIndex }, 'Test[0]: ShortIndex' );
    can_ok( $data->Offer->[0], 'CorporateName' );
    ok( eval { $data->Offer->[0]->CorporateName }, 'Test[0]: CorporateName' );
    can_ok( $data->Offer->[0], 'TransPortation' );
    ok( eval { $data->Offer->[0]->TransPortation }, 'Test[0]: TransPortation' );
    can_ok( $data->Offer->[0], 'JobTypeDetail' );
    ok( eval { $data->Offer->[0]->JobTypeDetail }, 'Test[0]: JobTypeDetail' );
    can_ok( $data->Offer->[0], 'PayText' );
    ok( eval { $data->Offer->[0]->PayText }, 'Test[0]: PayText' );
    can_ok( $data->Offer->[0], 'OfferConditionList' );
    ok( eval { $data->Offer->[0]->OfferConditionList }, 'Test[0]: OfferConditionList' );
    can_ok( $data->Offer->[0], 'GeoPointList' );
    ok( eval { $data->Offer->[0]->GeoPointList }, 'Test[0]: GeoPointList' );
    can_ok( $data->Offer->[0]->VisualIndices, 'VisualIndex' );
    ok( eval { $data->Offer->[0]->VisualIndices->VisualIndex }, 'Test[0]: VisualIndex' );
    ok( eval { ref $data->Offer->[0]->VisualIndices->VisualIndex } eq 'ARRAY', 'Test[0]: VisualIndex' );
    can_ok( $data->Offer->[0]->TimeIndices, 'TimeIndex' );
    ok( eval { $data->Offer->[0]->TimeIndices->TimeIndex }, 'Test[0]: TimeIndex' );
    ok( eval { ref $data->Offer->[0]->TimeIndices->TimeIndex } eq 'ARRAY', 'Test[0]: TimeIndex' );
    can_ok( $data->Offer->[0]->OfferConditionList, 'OfferCondition' );
    ok( eval { $data->Offer->[0]->OfferConditionList->OfferCondition }, 'Test[0]: OfferCondition' );
    ok( eval { ref $data->Offer->[0]->OfferConditionList->OfferCondition } eq 'ARRAY', 'Test[0]: OfferCondition' );
    can_ok( $data->Offer->[0]->GeoPointList, 'GeoPoint' );
    ok( eval { $data->Offer->[0]->GeoPointList->GeoPoint }, 'Test[0]: GeoPoint' );
    ok( eval { ref $data->Offer->[0]->GeoPointList->GeoPoint } eq 'ARRAY', 'Test[0]: GeoPoint' );
    can_ok( $data->Offer->[0]->VisualIndices->VisualIndex->[0], 'VisualSize' );
    ok( eval { $data->Offer->[0]->VisualIndices->VisualIndex->[0]->VisualSize }, 'Test[0]: VisualSize' );
    can_ok( $data->Offer->[0]->VisualIndices->VisualIndex->[0], 'VisualName' );
    ok( eval { $data->Offer->[0]->VisualIndices->VisualIndex->[0]->VisualName }, 'Test[0]: VisualName' );
    can_ok( $data->Offer->[0]->VisualIndices->VisualIndex->[0], 'VisualImageUrl' );
    ok( eval { $data->Offer->[0]->VisualIndices->VisualIndex->[0]->VisualImageUrl }, 'Test[0]: VisualImageUrl' );
    can_ok( $data->Offer->[0]->OfferConditionList->OfferCondition->[0], 'TypeOfEmployment' );
    ok( eval { $data->Offer->[0]->OfferConditionList->OfferCondition->[0]->TypeOfEmployment }, 'Test[0]: TypeOfEmployment' );
}

# Test[1]
{
    my $params = {
        'api_key' => $ENV{'WEBSERVICE_RECRUIT_FROMA_KEY'},
        'edition_cd' => '1',
        'hours_ctgry_cd' => '04',
        'ksjcd' => '07',
        's_area_cd' => '103002',
    };
    my $res = new WebService::Recruit::FromA::JobSearch();
    $res->add_param(%$params);
    eval { $res->request(); };
    ok( ! $@, 'Test[1]: die' );
    ok( ! $res->is_error, 'Test[1]: is_error' );
    my $data = $res->root;
    ok( ref $data, 'Test[1]: root' );
    can_ok( $data, 'Code' );
    ok( eval { $data->Code }, 'Test[1]: Code' );
    can_ok( $data, 'Message' );
    ok( eval { $data->Message }, 'Test[1]: Message' );
}

# Test[2]
{
    my $params = {
    };
    my $res = new WebService::Recruit::FromA::JobSearch();
    $res->add_param(%$params);
    eval { $res->request(); };
    ok( $@, 'Test[2]: die' );
}


1;
