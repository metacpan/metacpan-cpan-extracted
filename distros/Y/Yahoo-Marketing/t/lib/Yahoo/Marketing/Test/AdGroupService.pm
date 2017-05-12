package Yahoo::Marketing::Test::AdGroupService;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/ Yahoo::Marketing::Test::PostTest /;

use Test::More;
use Module::Build;

use Yahoo::Marketing::AdGroup;
use Yahoo::Marketing::AdGroupService;
use Yahoo::Marketing::AdGroupOptimizationGuidelines;

use Data::Dumper;

#use SOAP::Lite +trace => [qw/ debug method fault /];

sub SKIP_CLASS {
    my $self = shift;
    # 'not running post tests' is a true value
    return 'not running post tests' unless $self->run_post_tests;
    return;
}


sub test_add_ad_group : Test(3) {
    my ( $self ) = @_;

    my $result = $self->create_ad_group;

    ok( $result );

    like( $result->name, qr/^test ad group \d+$/, 'name looks right' );
    like( $result->ID, qr/^[\d]+$/, 'ID is numeric' );

    my $ysm_ws = Yahoo::Marketing::AdGroupService->new->parse_config( section => $self->section );
    $ysm_ws->deleteAdGroup( adGroupID => $result->ID );
};


sub test_add_ad_groups : Test(5) {
    my ( $self ) = @_;

    my @added_ad_groups = $self->create_ad_groups;

    ok( @added_ad_groups );

    like( $added_ad_groups[0]->name, qr/^test ad group \d+ 1$/, 'name looks right' );
    like( $added_ad_groups[0]->ID, qr/^[\d]+$/, 'ID is numeric' );

    like( $added_ad_groups[1]->name, qr/^test ad group \d+ 2$/, 'name looks right' );
    like( $added_ad_groups[1]->ID, qr/^[\d]+$/, 'ID is numeric' );

    my $ysm_ws = Yahoo::Marketing::AdGroupService->new->parse_config( section => $self->section );
    $ysm_ws->deleteAdGroups( adGroupIDs => [ map { $_->ID } @added_ad_groups ] );
};


sub test_delete_ad_group : Test(3) {
    my ( $self ) = @_;

    my $ad_group = $self->create_ad_group;

    my $ysm_ws = Yahoo::Marketing::AdGroupService->new->parse_config( section => $self->section );

    my $response = $ysm_ws->deleteAdGroup(
                       adGroupID => $ad_group->ID,
                   );
    is( $response->operationSucceeded, 'true' );

    my $fetched_ad_group = $ysm_ws->getAdGroup(
        adGroupID => $ad_group->ID,
    );

    ok( $fetched_ad_group );
    is( $fetched_ad_group->status, 'Deleted' );
};


sub test_delete_ad_groups : Test(5) {
    my ( $self ) = @_;

    my $ad_group1 = $self->create_ad_group;
    my $ad_group2 = $self->create_ad_group;

    my $ysm_ws = Yahoo::Marketing::AdGroupService->new->parse_config( section => $self->section );

    my @responses = $ysm_ws->deleteAdGroups(
                        adGroupIDs => [ $ad_group1->ID, $ad_group2->ID ],
                    );
    foreach my $response ( @responses ){
        is( $response->operationSucceeded, 'true' );
    }

    my @fetched_ad_groups = $ysm_ws->getAdGroups(
        adGroupIDs => [ $ad_group1->ID, $ad_group2->ID ],
    );

    ok( scalar @fetched_ad_groups );
    is( $fetched_ad_groups[0]->status, 'Deleted' );
    is( $fetched_ad_groups[1]->status, 'Deleted' );
};


sub test_get_ad_group : Test(4) {
    my ( $self ) = @_;

    my $ad_group = $self->common_test_data( 'test_ad_group' );

    my $ysm_ws = Yahoo::Marketing::AdGroupService->new->parse_config( section => $self->section );

    my $fetched_ad_group = $ysm_ws->getAdGroup( adGroupID => $ad_group->ID );

    ok( $fetched_ad_group );
    is( $fetched_ad_group->name,   $ad_group->name,   'name is right' );
    is( $fetched_ad_group->ID,     $ad_group->ID,     'ID is numeric' );
    is( $fetched_ad_group->status, $ad_group->status, 'status is right' );
};


sub test_get_ad_group_ad_count : Test(1) {
    my ( $self ) = @_;

    my $ad_group = $self->common_test_data( 'test_ad_group' );

    my $ysm_ws = Yahoo::Marketing::AdGroupService->new->parse_config( section => $self->section );

    my $ad_count = $ysm_ws->getAdGroupAdCount(
        adGroupID => $ad_group->ID,
        includeDeleted => 'false',
    );

    like( $ad_count, qr/^[\d]+$/, 'Ad Count is numberic' );
}


# may need to change - the doc is not ready on site.
sub test_get_ad_group_content_match_max_bid : Test(1) {
    my ( $self ) = @_;

    my $ad_group = $self->create_ad_group;

    my $ysm_ws = Yahoo::Marketing::AdGroupService->new->parse_config( section => $self->section );

    my $cm_max_bid = $ysm_ws->getAdGroupContentMatchMaxBid(
        adGroupID => $ad_group->ID,
    );

    is( $cm_max_bid, $ad_group->contentMatchMaxBid, 'Content Match Max Bid is right' );
};


sub test_get_ad_group_excluded_words_count : Test(1) {
    my ( $self ) = @_;

    # do we need to add some excluded words to the ad group first?
    my $ad_group = $self->common_test_data( 'test_ad_group' );

    my $ysm_ws = Yahoo::Marketing::AdGroupService->new->parse_config( section => $self->section );

    my $excluded_words_count = $ysm_ws->getAdGroupExcludedWordsCount(
        adGroupID => $ad_group->ID,
        includeDeleted => 'false',
    );

    like( $excluded_words_count, qr/^[\d]+$/, 'Excluded Words Count is numberic' );
};


sub test_get_ad_group_keyword_count : Test(1) {
    my ( $self ) = @_;

    # do we need to add some keywords to the ad group first?
    my $ad_group = $self->common_test_data( 'test_ad_group' );

    my $ysm_ws = Yahoo::Marketing::AdGroupService->new->parse_config( section => $self->section );

    my $keyword_count = $ysm_ws->getAdGroupKeywordCount(
        adGroupID => $ad_group->ID,
        includeDeleted => 'false',
    );

    like( $keyword_count, qr/^[\d]+$/, 'Keyword Count is numberic' );
};


sub test_get_ad_groups : Test(6) {
    my ( $self ) = @_;

    my $ysm_ws = Yahoo::Marketing::AdGroupService->new->parse_config( section => $self->section );

    my @ad_groups = ( $self->create_ad_group, $self->create_ad_group );

    ok( @ad_groups );

    my @fetched_ad_groups = $ysm_ws->getAdGroups(
        adGroupIDs => [ $ad_groups[0]->ID, $ad_groups[1]->ID ],
    );

    is( scalar @fetched_ad_groups, 2, 'got correct number of ad groups returned' )
        or return 'incorrect number of ad groups returned, skipping correct ad group verification';

    like( $fetched_ad_groups[0]->name, qr/^test ad group \d+$/, 'name looks right');
    like( $fetched_ad_groups[0]->ID, qr/^[\d]+$/, 'ID is numberic' );

    like( $fetched_ad_groups[1]->name, qr/^test ad group \d+$/, 'name looks right');
    like( $fetched_ad_groups[1]->ID, qr/^[\d]+$/, 'ID is numberic' );

    $ysm_ws->deleteAdGroups(
        adGroupIDs => [ $ad_groups[0]->ID, $ad_groups[1]->ID ],
    );
};


sub test_get_ad_groups_by_campaign_id : Test(1) {
    my ( $self ) = @_;

    my $campaign = $self->common_test_data( 'test_campaign' );

    my $ysm_ws = Yahoo::Marketing::AdGroupService->new->parse_config( section => $self->section );

    my @fetched_ad_groups = $ysm_ws->getAdGroupsByCampaignID(
        campaignID   => $campaign->ID,
        includeDeleted => 'false',
        startElement => 0,
        numElements  => 1000,
    );

    ok( @fetched_ad_groups );

};


sub test_get_ad_groups_by_campaign_id_by_status : Test(2) {
    my ( $self ) = @_;

    my $campaign = $self->common_test_data( 'test_campaign' );

    my $ysm_ws = Yahoo::Marketing::AdGroupService->new->parse_config( section => $self->section );

    my @fetched_ad_groups = $ysm_ws->getAdGroupsByCampaignIDByStatus(
        campaignID    => $campaign->ID,
        adGroupStatus => 'On',
    );

    ok( @fetched_ad_groups );

    my $not_on_status_found = 0;
    foreach my $ad_group ( @fetched_ad_groups ) {
        $not_on_status_found++ if $ad_group->status ne 'On';
    }
    is( $not_on_status_found, 0 );
};


# may need to change - the doc on site is not ready
sub test_get_ad_group_sponsored_search_max_bid : Test(1) {
    my ( $self ) = @_;

    my $ad_group = $self->common_test_data( 'test_ad_group' );

    my $ysm_ws = Yahoo::Marketing::AdGroupService->new->parse_config( section => $self->section );

    my $ss_max_bid = $ysm_ws->getAdGroupSponsoredSearchMaxBid(
        adGroupID => $ad_group->ID,
    );

    is( $ss_max_bid, $ad_group->sponsoredSearchMaxBid, 'Sponsored Search Max Bid is right' );
};


sub test_get_and_set_optimization_guidelines_for_ad_group : Test(16) {
    my ( $self ) = @_;

    my $ad_group = $self->common_test_data( 'test_ad_group' );

    my $ysm_ws = Yahoo::Marketing::AdGroupService->new->parse_config( section => $self->section );

    my $adGroupOptimizationGuidelines = Yahoo::Marketing::AdGroupOptimizationGuidelines->new
                                            ->adGroupID( $ad_group->ID )
                                            ->averageConversionRate( '0.02' )
                                            ->averageRevenuePerConversion( '0.08' )
                                            ->contentMatchMaxBid( '0.98' )
                                            ->conversionImportance( 'Medium' )
                                            ->CPA( '1.18' )
                                            ->CPC( '0.98' )
                                            ->CPM( '2.38' )
                                            ->impressionImportance( 'High' )
                                            ->leadImportance( 'Low' )
                                            ->ROAS( 110.0 )
                                            ->sponsoredSearchMaxBid( '1.08' )
                                            ->sponsoredSearchMinPosition( '3' )
                                            ->sponsoredSearchMinPositionImportance( 'None' )
    ;

    my $response = $ysm_ws->setOptimizationGuidelinesForAdGroup(
                       optimizationGuidelines => $adGroupOptimizationGuidelines,
                   );

    my $updated_ad_group_optimization_guidelines = $response->adGroupOptimizationGuidelines;

    is( $response->operationSucceeded, 'true' );

    ok( $updated_ad_group_optimization_guidelines );
    is( $updated_ad_group_optimization_guidelines->adGroupID, $ad_group->ID );
    is( $updated_ad_group_optimization_guidelines->averageConversionRate, '0.02' );
    is( $updated_ad_group_optimization_guidelines->averageRevenuePerConversion, '0.08' );
    is( $updated_ad_group_optimization_guidelines->contentMatchMaxBid, '0.98' );
    is( $updated_ad_group_optimization_guidelines->conversionImportance, 'Medium' );
    is( $updated_ad_group_optimization_guidelines->CPA, '1.18' );
    is( $updated_ad_group_optimization_guidelines->CPC, '0.98' );
    is( $updated_ad_group_optimization_guidelines->CPM, '2.38' );
    is( $updated_ad_group_optimization_guidelines->impressionImportance, 'High' );
    is( $updated_ad_group_optimization_guidelines->leadImportance, 'Low' );
    is( $updated_ad_group_optimization_guidelines->ROAS, '110.0' );    
    is( $updated_ad_group_optimization_guidelines->sponsoredSearchMaxBid, '1.08' );
    is( $updated_ad_group_optimization_guidelines->sponsoredSearchMinPosition, '3' );
    is( $updated_ad_group_optimization_guidelines->sponsoredSearchMinPositionImportance, 'None' );
};


sub test_get_status_for_ad_group : Test(1) {
    my ( $self ) = @_;

    my $ad_group = $self->common_test_data( 'test_ad_group' );

    my $ysm_ws = Yahoo::Marketing::AdGroupService->new->parse_config( section => $self->section );

    is( $ysm_ws->getStatusForAdGroup( adGroupID => $ad_group->ID ), $ad_group->status, 'Status is right');
};


# may need change - the doc on site is not ready
sub test_set_ad_group_content_match_max_bid : Test(2) {
    my ( $self ) = @_;

    my $ad_group = $self->common_test_data( 'test_ad_group' );

    my $ysm_ws = Yahoo::Marketing::AdGroupService->new->parse_config( section => $self->section );

    my $new_bid = 1.28;
    $ysm_ws->setAdGroupContentMatchMaxBid(
        adGroupID => $ad_group->ID,
        maxBid    => $new_bid,
    );
    is( $ysm_ws->getAdGroupContentMatchMaxBid( adGroupID => $ad_group->ID ), $new_bid, 'Can set ad group content match max bid');

    $ysm_ws->setAdGroupContentMatchMaxBid(
        adGroupID => $ad_group->ID,
        maxBid    => $ad_group->contentMatchMaxBid,
    );
    is( $ysm_ws->getAdGroupContentMatchMaxBid( adGroupID => $ad_group->ID ), $ad_group->contentMatchMaxBid, 'Can set ad group content match max bid');
};


# may need change - the doc on site is not ready
sub test_set_ad_group_sponsored_search_max_bid : Test(2) {
    my ( $self ) = @_;

    my $ad_group = $self->common_test_data( 'test_ad_group' );

    my $ysm_ws = Yahoo::Marketing::AdGroupService->new->parse_config( section => $self->section );

    my $new_bid = 2.38;
    $ysm_ws->setAdGroupSponsoredSearchMaxBid(
        adGroupID => $ad_group->ID,
        maxBid    => $new_bid,
    );
    is( $ysm_ws->getAdGroupSponsoredSearchMaxBid( adGroupID => $ad_group->ID ), $new_bid, 'Can set ad group sponsored search max bid');

    $ysm_ws->setAdGroupSponsoredSearchMaxBid(
        adGroupID => $ad_group->ID,
        maxBid    => $ad_group->sponsoredSearchMaxBid,
    );
    is( $ysm_ws->getAdGroupSponsoredSearchMaxBid( adGroupID => $ad_group->ID ), $ad_group->sponsoredSearchMaxBid, 'Can set ad group sponsored search max bid');
};


sub test_update_ad_group : Test(7) {
    my ( $self ) = @_;

    my $ad_group = $self->create_ad_group;

    my $ysm_ws = Yahoo::Marketing::AdGroupService->new->parse_config( section => $self->section );
    my $response = $ysm_ws->updateAdGroup( adGroup => $ad_group->name( "updated ad group $$" ) ,
                                           updateAll => 'True',
                                         );

    my $updated_ad_group = $response->adGroup;

    ok( $updated_ad_group );
    is( $updated_ad_group->name, "updated ad group $$", 'name is right' );
    is( $updated_ad_group->ID,   $ad_group->ID,         'ID is right' );

    is( $ysm_ws->last_command_group, 'Marketing', 'last command group gets set correctly' );
    like( $ysm_ws->remaining_quota, qr/^\d+$/, 'remaining quota looks right' );

    ok( ! $response->errors );
    is( $response->operationSucceeded, 'true', 'operation succeeded' );

    $ysm_ws->deleteAdGroup( adGroupID => $ad_group->ID );
};


sub test_update_ad_groups : Test(11) {
    my ( $self ) = @_;

    my $ysm_ws = Yahoo::Marketing::AdGroupService->new->parse_config( section => $self->section );

    my @ad_groups = $self->create_ad_groups;

    ok( @ad_groups );

    my $response = $ysm_ws->updateAdGroups( adGroups => [ $ad_groups[0]->name( "updated ad group $$ 1" ),
                                                          $ad_groups[1]->name( "updated ad group $$ 2" ),
                                                        ],
                                            updateAll => 'True',
                                          );

    ok( $response );

    sleep 2;

    for my $index ( 0..1 ) { 
        my $fetched_ad_group = $ysm_ws->getAdGroup( adGroupID => $ad_groups[ $index ]->ID );

        my $ad_group_name_index = $index + 1;

        ok( $fetched_ad_group );
        is( $fetched_ad_group->ID,   $ad_groups[ $index ]->ID,   'ID is right' );
        is( $fetched_ad_group->name, "updated ad group $$ $ad_group_name_index", 'name is right' );
    }

    my $fetched_ad_group = $ysm_ws->getAdGroup( adGroupID => $ad_groups[2]->ID );

    ok( $fetched_ad_group );
    is( $fetched_ad_group->name, $ad_groups[2]->name, 'name is right' );
    is( $fetched_ad_group->ID,   $ad_groups[2]->ID,   'ID is right' );

    $ysm_ws->deleteAdGroups(
        adGroupIDs => [ map { $_->ID } @ad_groups ],
    );
};


sub test_update_status_for_ad_group : Test(2) {
    my ( $self ) = @_;

    my $ad_group = $self->common_test_data( 'test_ad_group' );

    my $ysm_ws = Yahoo::Marketing::AdGroupService->new->parse_config( section => $self->section );
    $ysm_ws->updateStatusForAdGroup(
        adGroupID  => $ad_group->ID,
        status     => 'Off',
    );
    is( $ysm_ws->getAdGroup( adGroupID => $ad_group->ID )->status, 'Off' );

    $ysm_ws->updateStatusForAdGroup(
        adGroupID  => $ad_group->ID,
        status     => 'On',
    );
    is( $ysm_ws->getAdGroup( adGroupID => $ad_group->ID )->status, 'On' );
};


sub test_update_status_for_ad_groups : Test(4) {
    my ( $self ) = @_;

    my @ad_groups = @{ $self->common_test_data( 'test_ad_groups' ) };

    my $ysm_ws = Yahoo::Marketing::AdGroupService->new->parse_config( section => $self->section );

    $ysm_ws->updateStatusForAdGroups(
        adGroupIDs => [ $ad_groups[0]->ID, $ad_groups[1]->ID ],
        status     => 'Off',
    );

    is( $ysm_ws->getAdGroup( adGroupID => $ad_groups[0]->ID )->status, 'Off' );
    is( $ysm_ws->getAdGroup( adGroupID => $ad_groups[1]->ID )->status, 'Off' );

    $ysm_ws->updateStatusForAdGroups(
        adGroupIDs => [ $ad_groups[0]->ID, $ad_groups[1]->ID ],
        status      => 'On',
    );
    is( $ysm_ws->getAdGroup( adGroupID => $ad_groups[0]->ID )->status, 'On' );
    is( $ysm_ws->getAdGroup( adGroupID => $ad_groups[1]->ID )->status, 'On' );
};

sub test_move_ad_group : Test(7) {
    my ( $self ) = @_;

    my $campaign = $self->create_campaign;
    ok( $campaign );
    my $ad_group_name = 'test ad group '.($$ + $Yahoo::Marketing::Test::PostTest::ad_group_count++).' 4';
    my $ad_group = Yahoo::Marketing::AdGroup->new
                                            ->campaignID( $campaign->ID )
                                            ->name( $ad_group_name )
                                            ->status( 'On' )
                                            ->contentMatchON( 'true' )
                                            ->contentMatchMaxBid( '0.18' )
                                            ->sponsoredSearchON( 'true' )
                                            ->sponsoredSearchMaxBid( '0.28' )
                                            ->adAutoOptimizationON( 'false' )
                   ;
    my $ad_group_service = Yahoo::Marketing::AdGroupService->new->parse_config( section => $self->section );
    my $added_ad_group = $ad_group_service->addAdGroup( adGroup => $ad_group )->adGroup;
    ok( $added_ad_group );

    my $campaign_service = Yahoo::Marketing::CampaignService->new->parse_config( section => $self->section );
    ok( $campaign_service->deleteCampaign( campaignID => $campaign->ID ) );

    $ad_group_service->moveAdGroup(
        adGroupID             => $added_ad_group->ID,
        destinationCampaignID => $self->common_test_data( 'test_campaign' )->ID,
        newAdGroupName        => "$ad_group_name new",
    );

    my $moved_ad_group = $ad_group_service->getAdGroup( adGroupID => $added_ad_group->ID );
    ok( $moved_ad_group );
    is( $moved_ad_group->campaignID, $self->common_test_data( 'test_campaign' )->ID, 'campaignID is right' );
    is( $moved_ad_group->name, "$ad_group_name new", 'name is right' );
    ok( $ad_group_service->deleteAdGroup( adGroupID => $added_ad_group->ID ) );
}

sub test_get_sponsored_search_min_bid_for_ad_group : Test(2) {
    my ( $self ) = @_;

    my $ad_group = $self->common_test_data( 'test_ad_group' );

    my $ysm_ws = Yahoo::Marketing::AdGroupService->new->parse_config( section => $self->section );

    my $min_bid = $ysm_ws->getSponsoredSearchMinBidForAdGroup( adGroupID => $ad_group->ID );

    ok( $min_bid );
    like( $min_bid, qr/^[\d\.]+$/, 'looks like some body\'s money');
}

sub test_get_sponsored_search_min_bid_for_ad_groups : Test(2) {
    my ( $self ) = @_;

    my $ad_groups = $self->common_test_data( 'test_ad_groups' );

    my $ysm_ws = Yahoo::Marketing::AdGroupService->new->parse_config( section => $self->section );

    my $min_bid = $ysm_ws->getSponsoredSearchMinBidForAdGroups( adGroupIDs => [ map { $_->ID } @$ad_groups ] );
   
    # we only get one value back 
    ok( $min_bid );
    like( $min_bid, qr/^[\d\.]+$/, 'looks like some body\'s money');
}

sub startup_test_ad_group_service : Test(startup) {
    my ( $self ) = @_;

    $self->common_test_data( 'test_campaign', $self->create_campaign ) unless defined $self->common_test_data( 'test_campaign' );
    $self->common_test_data( 'test_ad_group', $self->create_ad_group ) unless defined $self->common_test_data( 'test_ad_group' );
    $self->common_test_data( 'test_ad_groups', [$self->create_ad_groups] ) unless defined $self->common_test_data( 'test_ad_groups' );
};


sub shutdown_test_ad_group_service : Test(shutdown) {
    my ( $self ) = @_;

    $self->cleanup_ad_group;
    $self->cleanup_ad_groups;
    $self->cleanup_campaign;
};

1;


__END__

# getContentMatchMinBidForAdGroupOptimizationGuidelines
# getSponsoredSearchMinBidForAdGroup
# getSponsoredSearchMinBidForAdGroupOptimizationGuidelines
# getSponsoredSearchMinBidForAdGroups


