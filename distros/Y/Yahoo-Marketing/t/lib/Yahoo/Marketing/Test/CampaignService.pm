package Yahoo::Marketing::Test::CampaignService;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/ Yahoo::Marketing::Test::PostTest /;

use Test::More;

use Yahoo::Marketing::Campaign;
use Yahoo::Marketing::CampaignService;
use Yahoo::Marketing::CampaignOptimizationGuidelines;

# use SOAP::Lite +trace => [qw/ debug method fault /];

sub SKIP_CLASS {
    my $self = shift;
    # 'not running post tests' is a true value
    return 'not running post tests' unless $self->run_post_tests;
    return;
}

sub startup_test_campaign_service : Test(startup) {
    my ( $self ) = @_;

    $self->common_test_data( 'test_campaign', $self->create_campaign ) unless defined $self->common_test_data( 'test_campaign' );
    $self->common_test_data( 'test_campaigns', [$self->create_campaigns] ) unless defined $self->common_test_data( 'test_campaigns' );
}


sub shutdown_test_campaign_service : Test(shutdown) {
    my ( $self ) = @_;

    $self->cleanup_campaign;
    $self->cleanup_campaigns;
}


sub test_get_campaign : Test(3) { 
    my ( $self ) = @_;

    my $ysm_ws = Yahoo::Marketing::CampaignService->new->parse_config( section => $self->section );

    my $campaign = $self->common_test_data( 'test_campaign' );

    my $fetched_campaign = $ysm_ws->getCampaign( campaignID => $campaign->ID );

    ok( $fetched_campaign );

    is( $fetched_campaign->name, $campaign->name, 'name is right' );
    is( $fetched_campaign->ID,   $campaign->ID,   'ID is right' );
}

sub test_update_campaign : Test(22) {
    my ( $self ) = @_;

    my $campaign = $self->common_test_data( 'test_campaign' );

    my $formatter = DateTime::Format::W3CDTF->new;
    my $start_datetime = DateTime->now;
    $start_datetime->set_time_zone( 'America/Chicago' );
    $start_datetime->add( days => 2 );

    my $end_datetime = DateTime->now;
    $end_datetime->set_time_zone( 'America/Chicago' );
    $end_datetime->add( years => 2 );

    my $ysm_ws = Yahoo::Marketing::CampaignService->new->parse_config( section => $self->section );
    my $update_campaign_response = $ysm_ws->updateCampaign( 
                                        campaign  => $campaign->name( "updated campaign $$" )
                                                              ->watchON( 'true' ) 
                                                              ->contentMatchON( 'true' ) 
                                                              ->advancedMatchON( 'true' ) 
                                                              ->sponsoredSearchON( 'true' ) 
                                                              ->startDate( $start_datetime )
                                                              ->endDate( $end_datetime ),
                                        updateAll => 'true',
                                    );

    ok( $update_campaign_response );
    is( $update_campaign_response->operationSucceeded, 'true' );
    my $updated_campaign = $update_campaign_response->campaign;
    ok( $updated_campaign);
    is( $updated_campaign->name,                    "updated campaign $$", 'name is right' );
    is( $updated_campaign->ID,                      $campaign->ID,         'ID is right' );
    is( $updated_campaign->watchON,                 'true',                'watch on is true' );
    is( $updated_campaign->contentMatchON,          'true',                'content match on is true' );
    is( $updated_campaign->advancedMatchON,         'true',                'advanced match on is true' );
    is( $updated_campaign->sponsoredSearchON,       'true',                'sponsored search  on is true' );
    is( DateTime->compare( $updated_campaign->startDate, $start_datetime ), 0,   'start date is right' );
    is( DateTime->compare( $updated_campaign->endDate,   $end_datetime ),   0,   'end date is right' );

    is( $ysm_ws->last_command_group, 'Marketing', 'last command group gets set correctly' );
    like( $ysm_ws->remaining_quota, qr/^\d+$/, 'remaining quota looks right' );

    $update_campaign_response = $ysm_ws->updateCampaign( campaign  => $updated_campaign->watchON( 'false' )
                                                                               ->contentMatchON( 'false' ) 
                                                                               ->advancedMatchON( 'false' ) 
                                                                               ->sponsoredSearchON( 'true' ),
                                                         updateAll => 'true',
                                 );
    is( $update_campaign_response->operationSucceeded, 'true' );
    $updated_campaign = $update_campaign_response->campaign;
    is( $updated_campaign->watchON,                 'false',          'watch on is false' );
    is( $updated_campaign->contentMatchON,          'false',          'content match on is false' );
    is( $updated_campaign->advancedMatchON,         'false',          'advanced match on is false' );
    is( $updated_campaign->sponsoredSearchON,       'true',          'sponsored search  on is false' );

    $start_datetime->subtract( years => 1 );

    $update_campaign_response = $ysm_ws->updateCampaign( campaign  => $updated_campaign->startDate( $start_datetime ), 
                                                         updateAll => 'true',
                                                       );
    is( $update_campaign_response->operationSucceeded, 'false' ); # cannot set startDate to past time.
    ok( $update_campaign_response->errors );

    $update_campaign_response = $ysm_ws->updateCampaign( campaign  => $updated_campaign->endDate( $start_datetime ),
                                                         updateAll => 'true',
                                                       );
    is( $update_campaign_response->operationSucceeded, 'false' ); # cannot set endDate before startDate.
    ok( $update_campaign_response->errors );
}


sub test_update_campaign_can_handle_dates_for_user : Test(12) {
    my ( $self ) = @_;

    my $campaign = $self->common_test_data( 'test_campaign' );

    my $datetime = DateTime->now;
    $datetime->set_time_zone( 'America/Chicago' );

    my $ysm_ws = Yahoo::Marketing::CampaignService->new->parse_config( section => $self->section );
    my $update_campaign_response = $ysm_ws->updateCampaign( 
                                        campaign  => $campaign->name( "updated campaign datetime $$" )
                                                              ->watchON( 'true' ) 
                                                              ->contentMatchON( 'true' ) 
                                                              ->advancedMatchON( 'true' ) 
                                                              ->sponsoredSearchON( 'true' ) 
                                                              ->startDate( $datetime ),
                                        updateAll => 'true',
                                    );

    ok( $update_campaign_response );
    is( $update_campaign_response->operationSucceeded, 'true',                       'update call was succesful' );
    my $updated_campaign = $update_campaign_response->campaign;
    ok( $updated_campaign);
    is( $updated_campaign->name,                     "updated campaign datetime $$", 'name is right' );
    is( $updated_campaign->ID,                       $campaign->ID,                  'ID is right' );
    is( $updated_campaign->watchON,                  'true',                         'watch on is true' );
    is( $updated_campaign->contentMatchON,           'true',                         'content match on is true' );
    is( $updated_campaign->advancedMatchON,          'true',                         'advanced match on is true' );
    is( $updated_campaign->sponsoredSearchON,        'true',                         'sponsored search  on is true' );

    # time zone will be set to Americal/Los_Angeles when it's returned
    $datetime->set_time_zone( 'America/Los_Angeles' );
    is( "@{[ $updated_campaign->startDate ]}",       "$datetime",                    'start date is right and stringified OK' );
    ok( $updated_campaign->lastUpdateTimestamp->UNIVERSAL::isa('DateTime'),          'lastUpdateTimestamp is a DateTime object' );
    is( DateTime->compare_ignore_floating( $updated_campaign->startDate,
                                           $datetime 
                                         ),              
        0, 
        'start date is right' 
    );
            
}

sub test_can_add_campaign : Test(4) {
    my ( $self ) = @_;

    my $campaign = $self->create_campaign;

    ok( $campaign );

    like( $campaign->name, qr/^test campaign \d+$/, 'name looks right' );
    like( $campaign->ID, qr/^[\d]+$/, 'ID is numeric' );

    my $ysm_ws = Yahoo::Marketing::CampaignService->new->parse_config( section => $self->section );

    ok( $ysm_ws->deleteCampaign(
                     campaignID => $campaign->ID,
                 ),
        'can delete campaign'
    );
}


sub test_can_get_campaign_ad_group_count : Test(6) {
    my ( $self ) = @_;

    my $campaign = $self->common_test_data( 'test_campaign' );

    my $ysm_ws = Yahoo::Marketing::CampaignService->new->parse_config( section => $self->section );

    my $count = $ysm_ws->getCampaignAdGroupCount(
                             campaignID     => $campaign->ID,
                             includeDeleted => 'false',
                         );
    is( $count, '0', 'AdGroup count is right' );

    my $ad_group = Yahoo::Marketing::AdGroup->new
                                            ->campaignID( $campaign->ID )
                                            ->name( 'test ad group '.$$ )
                                            ->status( 'On' )
                                            ->contentMatchON( 'true' )
                                            ->contentMatchMaxBid( '0.18' )
                                            ->sponsoredSearchON( 'true' )
                                            ->sponsoredSearchMaxBid( '0.28' )
                                            ->adAutoOptimizationON( 'false' )
                   ;
    my $ad_group_service = Yahoo::Marketing::AdGroupService->new->parse_config( section => $self->section );
    my $add_ad_group_response = $ad_group_service->addAdGroup( adGroup => $ad_group );
    ok( not $add_ad_group_response->errors );

    $count = $ysm_ws->getCampaignAdGroupCount(
                             campaignID     => $campaign->ID,
                             includeDeleted => 'false',
                         );
    is( $count, '1', 'AdGroup count is right' );

    ok( $ad_group_service->deleteAdGroup( adGroupID => $add_ad_group_response->adGroup->ID ) );

    $count = $ysm_ws->getCampaignAdGroupCount(
                             campaignID     => $campaign->ID,
                             includeDeleted => 'false',
                         );
    is( $count, '0', 'AdGroup count is right' );

    $count = $ysm_ws->getCampaignAdGroupCount(
                             campaignID     => $campaign->ID,
                             includeDeleted => 'true',
                         );
    is( $count, '1', 'AdGroup count is right' );
}

sub test_can_get_campaigns_by_account_id : Test(1) {
    my ( $self ) = @_;

    my $ysm_ws = Yahoo::Marketing::CampaignService->new->parse_config( section => $self->section );

    my @campaigns = $ysm_ws->getCampaignsByAccountID(
        accountID      => $ysm_ws->account,
        includeDeleted => 'false',
    );

    ok( scalar @campaigns );
}


sub test_can_update_campaigns : Test(13) {
    my ( $self ) = @_;

    my $ysm_ws = Yahoo::Marketing::CampaignService->new->parse_config( section => $self->section );

    my @campaigns = @{ $self->common_test_data( 'test_campaigns' ) };

    ok( @campaigns );

    my @response = $ysm_ws->updateCampaigns( campaigns => [ $campaigns[0]->name( "updated campaign $$ 1" ),
                                                            $campaigns[1]->name( "updated campaign $$ 2" ),
                                                          ],
                                             updateAll => 'true',
                                           );

    ok( @response );
    ok( not $response[0]->errors );
    ok( not $response[1]->errors );

    for my $index ( 0..1 ) { 
        my $fetched_campaign = $ysm_ws->getCampaign( campaignID => $campaigns[ $index ]->ID );

        my $campaign_name_index = $index + 1;

        ok( $fetched_campaign );
        is( $fetched_campaign->ID,   $campaigns[ $index ]->ID,   'ID is right' );   # heck, better be, we just got it by id
        is( $fetched_campaign->name, "updated campaign $$ $campaign_name_index", 'name is right' );
    }

    # check the third one [2]! to make sure it wasn't changed
    my $fetched_campaign = $ysm_ws->getCampaign( campaignID => $campaigns[2]->ID );

    ok( $fetched_campaign );
    is( $fetched_campaign->name, $campaigns[2]->name, 'name is right' );
    is( $fetched_campaign->ID,   $campaigns[2]->ID,   'ID is right' );

}


sub test_can_get_campaigns : Test(4) {
    my ( $self ) = @_;

    my $ysm_ws = Yahoo::Marketing::CampaignService->new->parse_config( section => $self->section );

    my @campaigns = @{ $self->common_test_data( 'test_campaigns' ) };

    ok( @campaigns );

    my @fetched_campaigns = $ysm_ws->getCampaigns( campaignIDs => [ $campaigns[0]->ID,
                                                                    $campaigns[1]->ID,
                                                                  ]
                                     );

    is( scalar @fetched_campaigns, 2, 'got correct number of campaigns returned' );

    like( $fetched_campaigns[0]->name, qr/^test campaign \d+ 1$/, 'name looks right' );
    like( $fetched_campaigns[0]->ID, qr/^[\d]+$/, 'ID is numeric' );

}


sub test_can_update_status_for_campaigns : Test(4) {
    my ( $self ) = @_;

    my @campaigns = @{ $self->common_test_data( 'test_campaigns' ) };

    my $ysm_ws = Yahoo::Marketing::CampaignService->new->parse_config( section => $self->section );

    $ysm_ws->updateStatusForCampaigns(
                 campaignIDs => [ $campaigns[0]->ID, $campaigns[1]->ID ],
                 status      => 'Off',
             );

    is( $ysm_ws->getCampaign( campaignID => $campaigns[0]->ID )->status, 'Off' );
    is( $ysm_ws->getCampaign( campaignID => $campaigns[1]->ID )->status, 'Off' );

    $ysm_ws->updateStatusForCampaigns(
                 campaignIDs => [ $campaigns[0]->ID, $campaigns[1]->ID ],
                 status      => 'On',
             );

    is( $ysm_ws->getCampaign( campaignID => $campaigns[0]->ID )->status, 'On' );
    is( $ysm_ws->getCampaign( campaignID => $campaigns[1]->ID )->status, 'On' );
}


sub test_can_get_status_for_campaign : Test(1) {
    my ( $self ) = @_;

    my $campaign = $self->common_test_data( 'test_campaign' );

    my $ysm_ws = Yahoo::Marketing::CampaignService->new->parse_config( section => $self->section );

    my $status = $ysm_ws->getStatusForCampaign( campaignID => $campaign->ID, );

    ok( $status, 'Can get campaign status');
}

sub test_can_get_campaign_keyword_count : Test(1) {
    my ( $self ) = @_;

    my $campaign = $self->common_test_data( 'test_campaign' );

    my $ysm_ws = Yahoo::Marketing::CampaignService->new->parse_config( section => $self->section );

    my $count = $ysm_ws->getCampaignKeywordCount(
        campaignID     => $campaign->ID,
        includeDeleted => 'false',
    );

    like( $count, qr/^[\d]+$/, 'Campaign Keyword Count is numeric' );
}


sub test_can_delete_campaign : Test(2) {
    my ( $self ) = @_;

    my $campaign = $self->create_campaign;

    my $ysm_ws = Yahoo::Marketing::CampaignService->new->parse_config( section => $self->section );

    my $response = $ysm_ws->deleteCampaign(
                       campaignID => $campaign->ID,
                   );

    is( $response->operationSucceeded, 'true' );

    my $fetched_campaign = $ysm_ws->getCampaign( campaignID => $campaign->ID, );

    is( $fetched_campaign->status, 'Deleted', 'campaign has Deleted status' );
}


sub test_can_get_min_mid_for_campaign_optimization_guidelines : Test(1) {
    my ( $self ) = @_;

    # getMinBidForCampaignOptimizationGuidelines

    my $campaign = $self->common_test_data( 'test_campaign' );

    my $ysm_ws = Yahoo::Marketing::CampaignService->new->parse_config( section => $self->section );

    my $response = $ysm_ws->getMinBidForCampaignOptimizationGuidelines( campaignID => $campaign->ID );

    like( $response, qr/^\d+(\.)*(\d)*$/, 'bid is numeric' );

    diag( $response );

}

sub test_can_set_and_get_optimization_guidelines_for_campaign : Test(5) {
    my ( $self ) = @_;

    my $campaign = $self->common_test_data( 'test_campaign' );

    my $ysm_ws = Yahoo::Marketing::CampaignService->new->parse_config( section => $self->section );

    my $campaignOptimizationGuidelines = Yahoo::Marketing::CampaignOptimizationGuidelines->new
                                             ->campaignID( $campaign->ID )
                                             ->conversionMetric( 'Revenue' )
                                             ->conversionImportance( 'High' )
                                             ->ROAS( 100.0 )                        # ROAS (return on ad spend) is required when conversionMetric is 'Revenue'.  % value
                                             ->averageConversionRate( 0.04 )        # also required as above reason
                                             ->averageRevenuePerConversion( 0.03 )  # also required as above reason
                                             ->CPC( 0.1 )
                                             ->CPM( 0.1 )
                                             ->impressionImportance( 'Low' )
                                             ->leadImportance( 'Low' )
                                             ->taggedForConversion( 'true' )
                                             ->taggedForRevenue( 'false' )
                                             ->maxBid( 1.00 )
                                             ->bidLimitHeadroom( 10.0 )             #  % value
                                             ->monthlySpendRate( 100.00 )
    ;

    $ysm_ws->setCampaignOptimizationON(
                 campaignID             => $campaign->ID,
                 campaignOptimizationON => 'true',
             );

    my $response = $ysm_ws->setOptimizationGuidelinesForCampaign(
                       optimizationGuidelines => $campaignOptimizationGuidelines,
                   );

    is( $response->operationSucceeded, 'true' );

    my $updated_campaign_optimization_guidelines = $response->campaignOptimizationGuidelines;

    is( $updated_campaign_optimization_guidelines->conversionMetric, 'Revenue' );
    is( $updated_campaign_optimization_guidelines->maxBid, '1.0' );
    is( $updated_campaign_optimization_guidelines->impressionImportance, 'Low' );
    is( $updated_campaign_optimization_guidelines->bidLimitHeadroom, '10.0' );
}

sub test_can_get_campaigns_by_account_id_by_campaign_status : Test(1) {
    my ( $self ) = @_;

    my $ysm_ws = Yahoo::Marketing::CampaignService->new->parse_config( section => $self->section );

    my @campaigns = $ysm_ws->getCampaignsByAccountIDByCampaignStatus(
                                 accountID => $ysm_ws->account,
                                 status    => 'On',
                             );

    ok(scalar @campaigns);
}


sub test_can_add_campaigns : Test(8) {
    my ( $self ) = @_;

    my @added_campaigns = $self->create_campaigns;

    my $ysm_ws = Yahoo::Marketing::CampaignService->new->parse_config( section => $self->section );

    ok( scalar @added_campaigns );

    like( $added_campaigns[0]->name, qr/^test campaign \d+ 1$/, 'name looks right' );
    like( $added_campaigns[0]->ID, qr/^[\d]+$/, 'ID is numeric' );

    like( $added_campaigns[1]->name, qr/^test campaign \d+ 2$/, 'name looks right' );
    like( $added_campaigns[1]->ID, qr/^[\d]+$/, 'ID is numeric' );

    like( $added_campaigns[2]->name, qr/^test campaign \d+ 3$/, 'name looks right' );
    like( $added_campaigns[2]->ID, qr/^[\d]+$/, 'ID is numeric' );

    ok( $ysm_ws->deleteCampaigns( campaignIDs => [ map { $_->ID } @added_campaigns ] ) );
}

sub test_add_campaigns_doesnt_add_if_one_is_bad : Test(3) {
    my ( $self ) = @_;

    my $formatter = DateTime::Format::W3CDTF->new;
    my $datetime = DateTime->now;
    $datetime->set_time_zone( 'America/Chicago' );

    my $start_datetime = $formatter->format_datetime( $datetime );

    $datetime->add( years => 1 );
    my $end_datetime   = $formatter->format_datetime( $datetime );

    my $ysm_ws = Yahoo::Marketing::CampaignService->new->parse_config( section => $self->section );

    my $campaign1 = Yahoo::Marketing::Campaign->new
                                              ->startDate( $start_datetime )
                                              ->endDate(   $end_datetime )
                                              ->name( 'test good campaign '.$$.' 1' )
                                              ->status( 'On' )
                                              ->accountID( $ysm_ws->account )
                    ;
    my $campaign2 = Yahoo::Marketing::Campaign->new   # no start date
                                              ->endDate(   $end_datetime )
                                              ->name( 'test bad campaign '.$$.' 2' )
                                              ->status( 'On' )
                                              ->accountID( $ysm_ws->account )
                    ;
    my $campaign3 = Yahoo::Marketing::Campaign->new
                                              ->startDate( $start_datetime )
                                              ->endDate(   $end_datetime )
                                              ->name( 'test good campaign '.$$.' 3' )
                                              ->status( 'On' )
                                              ->accountID( $ysm_ws->account )
                    ;

    eval { $ysm_ws->addCampaigns( campaigns => [ $campaign1, $campaign2, $campaign3 ] ); };

    like( $@, qr/A required field .*is missing or empty/, 'add campaigns fails as expected' );
    my @campaigns = $ysm_ws->getCampaignsByAccountID(
        accountID      => $ysm_ws->account,
        includeDeleted => 'false',
    );

    ok( ( not grep { /^test bad/ } map { $_->name } @campaigns ), 'bad campaign was not added' );
    ok( ( not grep { /^test good/ } map { $_->name } @campaigns ), 'good campaigns were not added either' );

}

sub test_can_update_status_for_campaign : Test(4) {
    my ( $self ) = @_;

    my $campaign = $self->common_test_data( 'test_campaign' );

    my $ysm_ws = Yahoo::Marketing::CampaignService->new->parse_config( section => $self->section );
    $ysm_ws->updateStatusForCampaign(
                 campaignID => $campaign->ID,
                 status     => 'Off',
             );

    my $fetched_campaign = $ysm_ws->getCampaign( campaignID => $campaign->ID );

    ok( $fetched_campaign );

    is( $fetched_campaign->status, 'Off' );


    $ysm_ws->updateStatusForCampaign(
                 campaignID => $campaign->ID,
                 status     => 'On',
             );

    $fetched_campaign = $ysm_ws->getCampaign( campaignID => $campaign->ID );

    ok( $fetched_campaign );
    is( $fetched_campaign->status, 'On' );
}

sub test_can_delete_campaigns : Test(4) {
    my ( $self ) = @_;

    my $campaign1 = $self->create_campaign;
    my $campaign2 = $self->create_campaign;

    my $ysm_ws = Yahoo::Marketing::CampaignService->new->parse_config( section => $self->section );

    my @responses = $ysm_ws->deleteCampaigns(
                        campaignIDs => [ $campaign1->ID, $campaign2->ID ],
                    );

    foreach my $response ( @responses ){
        is( $response->operationSucceeded, 'true' );
    }

    my @fetched_campaigns = $ysm_ws->getCampaigns(
                                         campaignIDs => [ $campaign1->ID, $campaign2->ID ],
                                     );

    is( $fetched_campaigns[0]->status, 'Deleted', 'first campaign has Deleted status' );
    is( $fetched_campaigns[1]->status, 'Deleted', 'second campaign has Deleted status' );
}



sub test_update_campaigns_response_with_multiple_errors_dies_correctly : Test(2) {
    my ( $self ) = @_;

    my $ysm_ws = Yahoo::Marketing::CampaignService->new->parse_config( section => $self->section );

    my @campaigns = @{ $self->common_test_data( 'test_campaigns' ) };

    eval { $ysm_ws->updateCampaigns( campaigns => [ $campaigns[0]->name( "updated campaign $$ 1" ),
                                                    $campaigns[1]->status( 'foo' ),
                                                    $campaigns[2]->status( 'bar' ),
                                                  ],
                                     updateAll => 'true',
                                   );
         };

    my $die_message = $@;

    ok( $die_message, 'we died' );        
    like( $die_message, qr/Message: Enumeration value .*is not recognized/,'die message looks right' );

    # be nice, put the statuses back
    $campaigns[$_]->status( 'On' ) for ( 1..2 );
}

sub test_campaign_service_can_be_immortal : Test(5) {
    my ( $self ) = @_;

    my $ysm_ws = Yahoo::Marketing::CampaignService->new
                                                  ->parse_config( section => $self->section )
                                                  ->immortal(1)  # don't die 
    ;

    my @campaigns = @{ $self->common_test_data( 'test_campaigns' ) };

    my $result = $ysm_ws->updateCampaigns( campaigns => [ $campaigns[0]->name( "updated campaign $$ 1" ),
                                                          $campaigns[1]->status( 'foo' ),
                                                          $campaigns[2]->status( 'bar' ),
                                                        ],
                                           updateAll => 'true',
                                         );

    ok( not $result );
    ok( $ysm_ws->fault );
    is( ref $ysm_ws->fault, 'Yahoo::Marketing::ApiFault'  );
    is( $ysm_ws->fault->code, 'E1019' );
    like( $ysm_ws->fault->message, qr/Enumeration value .*is not recognized/,'error message looks right' );


    # be nice, put the statuses back
    $campaigns[$_]->status( 'On' ) for ( 1..2 );
}


1;

