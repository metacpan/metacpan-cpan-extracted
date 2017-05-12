package Yahoo::Marketing::Test::TargetingService;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997)

use strict; use warnings;

use base qw/ Test::Class Yahoo::Marketing::Test::PostTest /;
use Test::More;

use Yahoo::Marketing::TargetingPremium;
use Yahoo::Marketing::TargetingAttribute;
use Yahoo::Marketing::GeoTarget;
use Yahoo::Marketing::GeoLocation;
use Yahoo::Marketing::TargetingPremium;
use Yahoo::Marketing::DayPartingTargeting;
use Yahoo::Marketing::DayPartingTarget;
use Yahoo::Marketing::DayPart;
use Yahoo::Marketing::TargetingType;
use Yahoo::Marketing::TargetingConverterService;
use Yahoo::Marketing::TargetingService;
use Data::Dumper;

# use SOAP::Lite +trace => [qw/ debug method fault /];

sub SKIP_CLASS {
    my $self = shift;
    # 'not running post tests' is a true value
    return 'not running post tests' unless $self->run_post_tests;
    return;
}

sub startup_test_targeting_service : Test(startup) {
    my ( $self ) = @_;

    $self->common_test_data( 'test_campaign', $self->create_campaign ) unless defined $self->common_test_data( 'test_campaign' );
    $self->common_test_data( 'test_ad_group', $self->create_ad_group ) unless defined $self->common_test_data( 'test_ad_group' );

}

sub shutdown_test_targeting_service : Test(shutdown) {
    my ( $self ) = @_;

    $self->cleanup_ad_group;
    $self->cleanup_campaign;
}


sub test_targeting_service_on_campaign : Test(22) {
    my ( $self ) = @_;

    my $campaign_id = $self->common_test_data( 'test_campaign' )->ID;
    my $ysm_ws = Yahoo::Marketing::TargetingService->new->parse_config( section => $self->section );

    my $targeting_converter_ws = Yahoo::Marketing::TargetingConverterService->new->parse_config( section => $self->section );
    my $descriptor = $targeting_converter_ws->getTargetingAttributeDescriptorByGender(
        gender => 'Female',
    );

    # test setTargetableLevelAsCampaign
    my $response = $ysm_ws->setTargetableLevelAsCampaign(
        campaignID => $campaign_id,
    );

    # test getTargetableLevelForCampaign
    my $level = $ysm_ws->getTargetableLevelForCampaign(
        campaignID => $campaign_id,
    );
    ok( $level, 'can call getTargetableLevelForCampaign' );
    is( $level, 'Campaign', 'level matches' );

    # test addTargetingAttributesForCampaign
    my $targeting_attr = Yahoo::Marketing::TargetingAttribute->new->premium(Yahoo::Marketing::TargetingPremium->new->type('Percentage')->value(18))->targetingAttributeDescriptor($descriptor);
    $response = $ysm_ws->addTargetingAttributesForCampaign(
        campaignID => $campaign_id,
        targetingAttributes => [ $targeting_attr ],
    );

    ok( $response, 'can call addTargetingAttributesForCampaign' );
    is( $response->operationSucceeded, 'true', 'operation succeeded' );

    # test getTargetingAttributesForCampaign
    my @attributes = $ysm_ws->getTargetingAttributesForCampaign(
        campaignID => $campaign_id,
    );
    ok( @attributes, 'can call getTargetingAttributesForCampaign' );
    ok( $attributes[0]->premium->value == 18, 'premium value matches' );
    is( $attributes[0]->premium->type, 'Percentage', 'premium percentage matches' );
    is( $attributes[0]->targetingAttributeDescriptor->targetingType->value, 'Gender', 'targeting attribute value matches' );

    # test getTargetingProfileForCampaign
    my $profile = $ysm_ws->getTargetingProfileForCampaign(
        campaignID => $campaign_id,
    );
    ok( $profile, 'can call getTargetingProfileForCampaign' );
    is( $profile->demographicTargeting->genderTargets->[0]->gender, 'Female', 'profile demo targeting gender matches' );
    ok( $profile->demographicTargeting->genderTargets->[0]->premium->value == 18, 'profile demo targeting premium matches' );

    # test updateTargetingProfileForCampaign
    $profile->geoTargets( [Yahoo::Marketing::GeoTarget->new->geoLocation(Yahoo::Marketing::GeoLocation->new->woeid(2347563))->premium(Yahoo::Marketing::TargetingPremium->new->type('Percentage')->value(8))] ); # demo: California
    $profile->dayPartingTargeting( Yahoo::Marketing::DayPartingTargeting->new->dayPartingTargets( [Yahoo::Marketing::DayPartingTarget->new->dayPart(Yahoo::Marketing::DayPart->new->dayOfTheWeek('Monday')->endHourOfDay(17)->startHourOfDay(10))] )->userTimeZone('true') ); # day parting: Monday 10:00-17:00

    $response = $ysm_ws->updateTargetingProfileForCampaign(
        campaignID => $campaign_id,
        targetingProfile => $profile,
        updateAll => 'false',
    );
    ok( $response, 'can call updateTargetingProfileForCampaign' );
    is( $response->operationSucceeded, 'true', 'operation succeeded' );

    # test deleteTargetingAttributesForCampaign
    $response = $ysm_ws->deleteTargetingAttributesForCampaign(
        campaignID => $campaign_id,
        targetingAttributes => [ $targeting_attr ],
    );
    ok( $response, 'can call deleteTargetingAttributesForCampaign' );
    is( $response->operationSucceeded, 'true', 'operation succeeded' );

    $profile = $ysm_ws->getTargetingProfileForCampaign(
        campaignID => $campaign_id,
    );
    ok( !$profile->demographicTargeting->genderTargets, 'verified demo targeting removed' );

    # test deleteTargetingByTypesForCampaign
    $response = $ysm_ws->deleteTargetingByTypesForCampaign(
        campaignID => $campaign_id,
        targetingTypes => [Yahoo::Marketing::TargetingType->new->value('DayParting')],
    );
    ok( $response, 'can call deleteTargetingByTypesForCampaign' );
    is( $response->operationSucceeded, 'true', 'operation succeeded' );

    $profile = $ysm_ws->getTargetingProfileForCampaign(
        campaignID => $campaign_id,
    );
    ok( !$profile->dayPartingTargeting, 'verified day parting targeting removed' );

    # test deleteTargetingForCampaign
    $response = $ysm_ws->deleteTargetingForCampaign(
        campaignID => $campaign_id,
    );
    ok( $response, 'can call deleteTargetingForCampaign' );
    is( $response->operationSucceeded, 'true', 'operation succeeded' );

    $profile = $ysm_ws->getTargetingProfileForCampaign(
        campaignID => $campaign_id,
    );
    ok( !$profile, 'verified all targeting removed' );

}


sub test_targeting_service_on_ad_group : Test(22) {
    my ( $self ) = @_;

    my $campaign_id = $self->common_test_data( 'test_campaign' )->ID;
    my $ad_group_id = $self->common_test_data( 'test_ad_group' )->ID;
    my $ysm_ws = Yahoo::Marketing::TargetingService->new->parse_config( section => $self->section );

    my $targeting_converter_ws = Yahoo::Marketing::TargetingConverterService->new->parse_config( section => $self->section );
    my $descriptor = $targeting_converter_ws->getTargetingAttributeDescriptorByGender(
        gender => 'Female',
    );

    # test setTargetableLevelAsAdGroup
    my $response = $ysm_ws->setTargetableLevelAsAdGroup(
        campaignID => $campaign_id,
        moveExistingTargets => 'false',
    );

    # test getTargetableLevelForCampaign
    my $level = $ysm_ws->getTargetableLevelForCampaign(
        campaignID => $campaign_id,
    );
    ok( $level, 'can call getTargetableLevelForCampaign' );
    is( $level, 'AdGroup', 'level matches' );

    # test addTargetingAttributesForAdGroup
    my $targeting_attr = Yahoo::Marketing::TargetingAttribute->new->premium(Yahoo::Marketing::TargetingPremium->new->type('Percentage')->value(18))->targetingAttributeDescriptor($descriptor);
    $response = $ysm_ws->addTargetingAttributesForAdGroup(
        adGroupID => $ad_group_id,
        targetingAttributes => [ $targeting_attr ],
    );

    ok( $response, 'can call addTargetingAttributesForAdGroup' );
    is( $response->operationSucceeded, 'true', 'operation succeeded' );

    # test getTargetingAttributesForAdGroup
    my @attributes = $ysm_ws->getTargetingAttributesForAdGroup(
        adGroupID => $ad_group_id,
    );
    ok( @attributes, 'can call getTargetingAttributesForAdGroup' );
    ok( $attributes[0]->premium->value == 18, 'premium value matches' );
    is( $attributes[0]->premium->type, 'Percentage', 'premium percentage matches' );
    is( $attributes[0]->targetingAttributeDescriptor->targetingType->value, 'Gender', 'targeting attribute value matches' );

    # test getTargetingProfileForAdGroup
    my $profile = $ysm_ws->getTargetingProfileForAdGroup(
        adGroupID => $ad_group_id,
    );
    ok( $profile, 'can call getTargetingProfileForAdGroup' );
    is( $profile->demographicTargeting->genderTargets->[0]->gender, 'Female', 'profile demo targeting gender matches' );
    ok( $profile->demographicTargeting->genderTargets->[0]->premium->value == 18, 'profile demo targeting premium matches' );

    # test updateTargetingProfileForAdGroup
    $profile->geoTargets( [Yahoo::Marketing::GeoTarget->new->geoLocation(Yahoo::Marketing::GeoLocation->new->woeid(2347563))->premium(Yahoo::Marketing::TargetingPremium->new->type('Percentage')->value(8))] ); # demo: California
    $profile->dayPartingTargeting( Yahoo::Marketing::DayPartingTargeting->new->dayPartingTargets( [Yahoo::Marketing::DayPartingTarget->new->dayPart(Yahoo::Marketing::DayPart->new->dayOfTheWeek('Monday')->endHourOfDay(17)->startHourOfDay(10))] )->userTimeZone('true') ); # day parting: Monday 10:00-17:00

    $response = $ysm_ws->updateTargetingProfileForAdGroup(
        adGroupID => $ad_group_id,
        targetingProfile => $profile,
        updateAll => 'false',
    );
    ok( $response, 'can call updateTargetingProfileForAdGroup' );
    is( $response->operationSucceeded, 'true', 'operation succeeded' );

    # test deleteTargetingAttributesForAdGroup
    $response = $ysm_ws->deleteTargetingAttributesForAdGroup(
        adGroupID => $ad_group_id,
        targetingAttributes => [ $targeting_attr ],
    );
    ok( $response, 'can call deleteTargetingAttributesForAdGroup' );
    is( $response->operationSucceeded, 'true', 'operation succeeded' );

    $profile = $ysm_ws->getTargetingProfileForAdGroup(
        adGroupID => $ad_group_id,
    );
    ok( !$profile->demographicTargeting->genderTargets, 'verified demo targeting removed' );

    # test deleteTargetingByTypesForAdGroup
    $response = $ysm_ws->deleteTargetingByTypesForAdGroup(
        adGroupID => $ad_group_id,
        targetingTypes => [Yahoo::Marketing::TargetingType->new->value('DayParting')],
    );
    ok( $response, 'can call deleteTargetingByTypesForAdGroup' );
    is( $response->operationSucceeded, 'true', 'operation succeeded' );

    $profile = $ysm_ws->getTargetingProfileForAdGroup(
        adGroupID => $ad_group_id,
    );
    ok( !$profile->dayPartingTargeting, 'verified day parting targeting removed' );

    # test deleteTargetingForAdGroup
    $response = $ysm_ws->deleteTargetingForAdGroup(
        adGroupID => $ad_group_id,
    );
    ok( $response, 'can call deleteTargetingForAdGroup' );
    is( $response->operationSucceeded, 'true', 'operation succeeded' );

    $profile = $ysm_ws->getTargetingProfileForAdGroup(
        adGroupID => $ad_group_id,
    );
    ok( !$profile, 'verified all targeting removed' );

}




1;

