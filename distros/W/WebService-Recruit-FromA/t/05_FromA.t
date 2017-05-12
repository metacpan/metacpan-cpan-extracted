#
# Test case for WebService::Recruit::FromA
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

use_ok('WebService::Recruit::FromA');

my $obj = WebService::Recruit::FromA->new();

ok(ref $obj, 'new WebService::Recruit::FromA()');


# jobSearch / Test[0]
{
    my $params = {
        'api_key' => $ENV{'WEBSERVICE_RECRUIT_FROMA_KEY'},
        'ksjcd' => '04',
        'shrt_indx_cd' => '1001',
    };
    my $res = eval { $obj->jobSearch(%$params); };
    ok( ! $@, 'jobSearch / Test[0]: die' );
    ok( ! $res->is_error, 'jobSearch / Test[0]: is_error' );
    my $data = $res->root;
    ok( ref $data, 'jobSearch / Test[0]: root' );
    can_ok( $data, 'Code' );
    if ( $data->can('Code') ) {
        ok( $data->Code, 'jobSearch / Test[0]: Code' );
    }
    can_ok( $data, 'TotalOfferAvailable' );
    if ( $data->can('TotalOfferAvailable') ) {
        ok( $data->TotalOfferAvailable, 'jobSearch / Test[0]: TotalOfferAvailable' );
    }
    can_ok( $data, 'TotalOfferReturned' );
    if ( $data->can('TotalOfferReturned') ) {
        ok( $data->TotalOfferReturned, 'jobSearch / Test[0]: TotalOfferReturned' );
    }
    can_ok( $data, 'PageNumber' );
    if ( $data->can('PageNumber') ) {
        ok( $data->PageNumber, 'jobSearch / Test[0]: PageNumber' );
    }
    can_ok( $data, 'EditionName' );
    if ( $data->can('EditionName') ) {
        ok( $data->EditionName, 'jobSearch / Test[0]: EditionName' );
    }
    can_ok( $data, 'Offer' );
    if ( $data->can('Offer') ) {
        ok( $data->Offer, 'jobSearch / Test[0]: Offer' );
        ok( ref $data->Offer eq 'ARRAY', 'jobSearch / Test[0]: Offer' );
    }
    can_ok( $data->Offer->[0], 'Catch' );
    if ( $data->Offer->[0]->can('Catch') ) {
        ok( $data->Offer->[0]->Catch, 'jobSearch / Test[0]: Catch' );
    }
    can_ok( $data->Offer->[0], 'OfferId' );
    if ( $data->Offer->[0]->can('OfferId') ) {
        ok( $data->Offer->[0]->OfferId, 'jobSearch / Test[0]: OfferId' );
    }
    can_ok( $data->Offer->[0], 'OfferStartDate' );
    if ( $data->Offer->[0]->can('OfferStartDate') ) {
        ok( $data->Offer->[0]->OfferStartDate, 'jobSearch / Test[0]: OfferStartDate' );
    }
    can_ok( $data->Offer->[0], 'OfferEndDate' );
    if ( $data->Offer->[0]->can('OfferEndDate') ) {
        ok( $data->Offer->[0]->OfferEndDate, 'jobSearch / Test[0]: OfferEndDate' );
    }
    can_ok( $data->Offer->[0], 'Prefecture' );
    if ( $data->Offer->[0]->can('Prefecture') ) {
        ok( $data->Offer->[0]->Prefecture, 'jobSearch / Test[0]: Prefecture' );
    }
    can_ok( $data->Offer->[0], 'City' );
    if ( $data->Offer->[0]->can('City') ) {
        ok( $data->Offer->[0]->City, 'jobSearch / Test[0]: City' );
    }
    can_ok( $data->Offer->[0], 'VisualIndices' );
    if ( $data->Offer->[0]->can('VisualIndices') ) {
        ok( $data->Offer->[0]->VisualIndices, 'jobSearch / Test[0]: VisualIndices' );
    }
    can_ok( $data->Offer->[0], 'TimeIndices' );
    if ( $data->Offer->[0]->can('TimeIndices') ) {
        ok( $data->Offer->[0]->TimeIndices, 'jobSearch / Test[0]: TimeIndices' );
    }
    can_ok( $data->Offer->[0], 'MinimumWorkDays' );
    if ( $data->Offer->[0]->can('MinimumWorkDays') ) {
        ok( $data->Offer->[0]->MinimumWorkDays, 'jobSearch / Test[0]: MinimumWorkDays' );
    }
    can_ok( $data->Offer->[0], 'ShortIndex' );
    if ( $data->Offer->[0]->can('ShortIndex') ) {
        ok( $data->Offer->[0]->ShortIndex, 'jobSearch / Test[0]: ShortIndex' );
    }
    can_ok( $data->Offer->[0], 'CorporateName' );
    if ( $data->Offer->[0]->can('CorporateName') ) {
        ok( $data->Offer->[0]->CorporateName, 'jobSearch / Test[0]: CorporateName' );
    }
    can_ok( $data->Offer->[0], 'TransPortation' );
    if ( $data->Offer->[0]->can('TransPortation') ) {
        ok( $data->Offer->[0]->TransPortation, 'jobSearch / Test[0]: TransPortation' );
    }
    can_ok( $data->Offer->[0], 'JobTypeDetail' );
    if ( $data->Offer->[0]->can('JobTypeDetail') ) {
        ok( $data->Offer->[0]->JobTypeDetail, 'jobSearch / Test[0]: JobTypeDetail' );
    }
    can_ok( $data->Offer->[0], 'PayText' );
    if ( $data->Offer->[0]->can('PayText') ) {
        ok( $data->Offer->[0]->PayText, 'jobSearch / Test[0]: PayText' );
    }
    can_ok( $data->Offer->[0], 'OfferConditionList' );
    if ( $data->Offer->[0]->can('OfferConditionList') ) {
        ok( $data->Offer->[0]->OfferConditionList, 'jobSearch / Test[0]: OfferConditionList' );
    }
    can_ok( $data->Offer->[0], 'GeoPointList' );
    if ( $data->Offer->[0]->can('GeoPointList') ) {
        ok( $data->Offer->[0]->GeoPointList, 'jobSearch / Test[0]: GeoPointList' );
    }
    can_ok( $data->Offer->[0]->VisualIndices, 'VisualIndex' );
    if ( $data->Offer->[0]->VisualIndices->can('VisualIndex') ) {
        ok( $data->Offer->[0]->VisualIndices->VisualIndex, 'jobSearch / Test[0]: VisualIndex' );
        ok( ref $data->Offer->[0]->VisualIndices->VisualIndex eq 'ARRAY', 'jobSearch / Test[0]: VisualIndex' );
    }
    can_ok( $data->Offer->[0]->TimeIndices, 'TimeIndex' );
    if ( $data->Offer->[0]->TimeIndices->can('TimeIndex') ) {
        ok( $data->Offer->[0]->TimeIndices->TimeIndex, 'jobSearch / Test[0]: TimeIndex' );
        ok( ref $data->Offer->[0]->TimeIndices->TimeIndex eq 'ARRAY', 'jobSearch / Test[0]: TimeIndex' );
    }
    can_ok( $data->Offer->[0]->OfferConditionList, 'OfferCondition' );
    if ( $data->Offer->[0]->OfferConditionList->can('OfferCondition') ) {
        ok( $data->Offer->[0]->OfferConditionList->OfferCondition, 'jobSearch / Test[0]: OfferCondition' );
        ok( ref $data->Offer->[0]->OfferConditionList->OfferCondition eq 'ARRAY', 'jobSearch / Test[0]: OfferCondition' );
    }
    can_ok( $data->Offer->[0]->GeoPointList, 'GeoPoint' );
    if ( $data->Offer->[0]->GeoPointList->can('GeoPoint') ) {
        ok( $data->Offer->[0]->GeoPointList->GeoPoint, 'jobSearch / Test[0]: GeoPoint' );
        ok( ref $data->Offer->[0]->GeoPointList->GeoPoint eq 'ARRAY', 'jobSearch / Test[0]: GeoPoint' );
    }
    can_ok( $data->Offer->[0]->VisualIndices->VisualIndex->[0], 'VisualSize' );
    if ( $data->Offer->[0]->VisualIndices->VisualIndex->[0]->can('VisualSize') ) {
        ok( $data->Offer->[0]->VisualIndices->VisualIndex->[0]->VisualSize, 'jobSearch / Test[0]: VisualSize' );
    }
    can_ok( $data->Offer->[0]->VisualIndices->VisualIndex->[0], 'VisualName' );
    if ( $data->Offer->[0]->VisualIndices->VisualIndex->[0]->can('VisualName') ) {
        ok( $data->Offer->[0]->VisualIndices->VisualIndex->[0]->VisualName, 'jobSearch / Test[0]: VisualName' );
    }
    can_ok( $data->Offer->[0]->VisualIndices->VisualIndex->[0], 'VisualImageUrl' );
    if ( $data->Offer->[0]->VisualIndices->VisualIndex->[0]->can('VisualImageUrl') ) {
        ok( $data->Offer->[0]->VisualIndices->VisualIndex->[0]->VisualImageUrl, 'jobSearch / Test[0]: VisualImageUrl' );
    }
    can_ok( $data->Offer->[0]->OfferConditionList->OfferCondition->[0], 'TypeOfEmployment' );
    if ( $data->Offer->[0]->OfferConditionList->OfferCondition->[0]->can('TypeOfEmployment') ) {
        ok( $data->Offer->[0]->OfferConditionList->OfferCondition->[0]->TypeOfEmployment, 'jobSearch / Test[0]: TypeOfEmployment' );
    }
}

# jobSearch / Test[1]
{
    my $params = {
        'api_key' => $ENV{'WEBSERVICE_RECRUIT_FROMA_KEY'},
        'edition_cd' => '1',
        'hours_ctgry_cd' => '04',
        'ksjcd' => '07',
        's_area_cd' => '103002',
    };
    my $res = eval { $obj->jobSearch(%$params); };
    ok( ! $@, 'jobSearch / Test[1]: die' );
    ok( ! $res->is_error, 'jobSearch / Test[1]: is_error' );
    my $data = $res->root;
    ok( ref $data, 'jobSearch / Test[1]: root' );
    can_ok( $data, 'Code' );
    if ( $data->can('Code') ) {
        ok( $data->Code, 'jobSearch / Test[1]: Code' );
    }
    can_ok( $data, 'Message' );
    if ( $data->can('Message') ) {
        ok( $data->Message, 'jobSearch / Test[1]: Message' );
    }
}

# jobSearch / Test[2]
{
    my $params = {
    };
    my $res = eval { $obj->jobSearch(%$params); };
    ok( $@, 'jobSearch / Test[2]: die' );
}



1;
