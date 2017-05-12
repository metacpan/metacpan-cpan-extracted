package Yahoo::Marketing::APT::Test::RateCardService;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997)

use strict; use warnings;

use base qw/ Yahoo::Marketing::APT::Test::PostTest /;
use Test::More;
use utf8;

use Yahoo::Marketing::APT::RateCardService;
use Yahoo::Marketing::APT::TargetingDictionaryService;
use Yahoo::Marketing::APT::RateCard;
use Yahoo::Marketing::APT::DefaultBaseRate;
use Yahoo::Marketing::APT::BaseRate;
use Yahoo::Marketing::APT::RateAdjustment;
use Yahoo::Marketing::APT::TargetingAttributeDescriptorWithAny;

use DateTime::Format::W3CDTF;
use Data::Dumper;

# use SOAP::Lite +trace => [qw/ debug method fault /];


sub SKIP_CLASS {
    my $self = shift;
    # 'not running post tests' is a true value
    return 'not running post tests' unless $self->run_post_tests;
    return;
}

sub section {
    my ( $self ) = @_;
    return $self->SUPER::section().'_managed_publisher';
}

sub startup_test_site_service : Test(startup) {
    my ( $self ) = @_;

    $self->common_test_data( 'test_site', $self->create_site ) unless defined $self->common_test_data( 'test_site' );
}

sub shutdown_test_site_service : Test(shutdown) {
    my ( $self ) = @_;

    $self->cleanup_site;
}


sub test_can_operate_rate_card : Test(32) {
     my $self = shift;

     my $ysm_ws = Yahoo::Marketing::APT::RateCardService->new->parse_config( section => $self->section );

     my $formatter = DateTime::Format::W3CDTF->new;
     my $datetime = DateTime->now;
     $datetime->set_time_zone( 'America/Chicago' );
     $datetime->add( days => 1 );

     my $start_datetime = $formatter->format_datetime( $datetime );

     my $rate_card =  Yahoo::Marketing::APT::RateCard->new
                                                     ->currency( 'USD' )
                                                     ->siteID( $self->common_test_data( 'test_site' )->ID )
                                                     ->startDate( $start_datetime )
                                                         ;
     # test addRateCard
     my $response = $ysm_ws->addRateCard( rateCard => $rate_card );
     ok( $response, 'can call addRateCard' );
     is( $response->operationSucceeded, 'true', 'add rate card successfully' );

     $rate_card = $response->rateCard;

     my $default_base_rate = Yahoo::Marketing::APT::DefaultBaseRate->new
                                                                   ->floorCPM( '5' )
                                                                   ->rateCardID( $rate_card->ID )
                                                                       ;
     # test addDefaultBaseRate
     $response = $ysm_ws->addDefaultBaseRate( defaultBaseRate => $default_base_rate );
     ok( $response, 'can call addDefaultBaseRate' );
     is( $response->operationSucceeded, 'true', 'add default base rate successfully' );
     $default_base_rate = $response->defaultBaseRate;

     # test getDefaultBaseRate
     $default_base_rate = $ysm_ws->getDefaultBaseRate( defaultBaseRateID => $default_base_rate->ID );
     ok( $default_base_rate, 'can call getDefaultBaseRate' );
     is( $default_base_rate->rateCardID, $rate_card->ID, 'rate card id matches' );

     $default_base_rate->floorCPM( '6' );
     # test updateDefaultBaseRate
     $response = $ysm_ws->updateDefaultBaseRate( defaultBaseRate => $default_base_rate );
     ok( $response, 'can call updateDefaultBaseRate' );
     is( $response->operationSucceeded, 'true', 'update default base rate successfully' );
     $default_base_rate = $response->defaultBaseRate;
     is( $default_base_rate->floorCPM, '6.0', 'floor CPM matches');

     my $targeting_ws = Yahoo::Marketing::APT::TargetingDictionaryService->new->parse_config( section => $self->section );
     my @targeting_attributes = $targeting_ws->getTargetingAttributes(
         targetingAttributeType => 'Gender',
         startElement           => 0,
         numElements            => 1000,
     );
     my $targeting_attr_desc = Yahoo::Marketing::APT::TargetingAttributeDescriptorWithAny->new
                                                                                         ->targetingAttributeID( $targeting_attributes[0]->ID )
                                                                                         ->targetingAttributeType( 'Gender' )
                                                                                             ;
     my $base_rate = Yahoo::Marketing::APT::BaseRate->new
                                                    ->floorCPM( '5' )
                                                    ->rateCardID( $rate_card->ID )
                                                    ->targetingAttributeDescriptorsWithAny( [$targeting_attr_desc] )
                                                        ;
     # test addBaseRate
     $response = $ysm_ws->addBaseRate( baseRate => $base_rate );
     ok( $response, 'can call addBaseRate' );
     is( $response->operationSucceeded, 'true', 'add base rate successfully' );
     $base_rate = $response->baseRate;

     # test getBaseRate
     $base_rate = $ysm_ws->getBaseRate( baseRateID => $base_rate->ID );
     ok( $base_rate, 'can call getBaseRate' );
     is( $base_rate->rateCardID, $rate_card->ID, 'rate card id matches' );

     $base_rate->floorCPM( '6' );
     # test updateBaseRate
     $response = $ysm_ws->updateBaseRate( baseRate => $base_rate );
     ok( $response, 'can call updateBaseRate' );
     is( $response->operationSucceeded, 'true', 'update base rate successfully' );
     $base_rate = $response->baseRate;
     is( $base_rate->floorCPM, '6.0', 'floor CPM matches');


     @targeting_attributes = $targeting_ws->getTargetingAttributes(
         targetingAttributeType => 'Income',
         startElement           => 0,
         numElements            => 1000,
     );
     $targeting_attr_desc = Yahoo::Marketing::APT::TargetingAttributeDescriptorWithAny->new
                                                                                      ->targetingAttributeID( $targeting_attributes[1]->ID )
                                                                                      ->targetingAttributeType( 'Income' )
                                                                                          ;
     my $rate_adj = Yahoo::Marketing::APT::RateAdjustment->new
                                                         ->percentageMarkup( 50 )
                                                         ->rateCardID( $rate_card->ID )
                                                         ->targetingAttributeDescriptorsWithAny( [$targeting_attr_desc] )
                                                             ;

     # test addRateAdjustment
     $response = $ysm_ws->addRateAdjustment( rateAdjustment => $rate_adj );
     ok( $response, 'can call addRateAdjustment' );
     is( $response->operationSucceeded, 'true', 'add rate adjustment successfully' );
     $rate_adj = $response->rateAdjustment;

     # test getRateAdjustment
     $rate_adj = $ysm_ws->getRateAdjustment( rateAdjustmentID => $rate_adj->ID );
     ok( $rate_adj, 'can call getRateAdjustment' );
     is( $rate_adj->rateCardID, $rate_card->ID, 'rate card id matches' );

     $rate_adj->floorCPM( undef );
     $rate_adj->percentageMarkup( 40 );
     $targeting_attr_desc->targetingAttributeID( $targeting_attributes[2]->ID );
     $rate_adj->targetingAttributeDescriptorsWithAny( [$targeting_attr_desc] );
     # test updateRateAdjustment
     $response = $ysm_ws->updateRateAdjustment( rateAdjustment => $rate_adj );
     ok( $response, 'can call updateRateAdjustment' );
     is( $response->operationSucceeded, 'true', 'update rate adjustment successfully' );
     $rate_adj = $response->rateAdjustment;
     is( $rate_adj->percentageMarkup, 40, 'percentage markup matches' );

     # test updateRateCard
     $response = $ysm_ws->updateRateCard( rateCard => $rate_card );
     ok( $response, 'can call updateRateCard' );
     is( $response->operationSucceeded, 'true', 'update rate card successfully' );
     $rate_card = $response->rateCard;

     # test getRateCard
     $rate_card = $ysm_ws->getRateCard( rateCardID => $rate_card->ID );
     ok( $rate_card, 'can call getRateCard' );

     # test activateRateCard
     $response = $ysm_ws->activateRateCard( rateCardID => $rate_card->ID );
     ok( $response, 'can call activateRateCard' );
     is( $response->operationSucceeded, 'true', 'activate rate card successfully' );
     $rate_card = $response->rateCard;

     # test copyRateCard
     if ( $rate_card->status eq 'Pending' ) {
         ok(1, 'skip copyRateCard');
         ok(1, 'skip copyRateCard');
     } else {
         $response = $ysm_ws->copyRateCard( rateCardID => $rate_card->ID );
         ok( $response, 'can call copyRateCard' );
         is( $response->operationSucceeded, 'true', 'copy rate card successfully' );
         my $new_rate_card = $response->rateCard;
         $ysm_ws->deleteRateCard( rateCardID => $new_rate_card->ID );
     }

     # test deleteRateCard
     $response = $ysm_ws->deleteRateCard( rateCardID => $rate_card->ID );
     ok( $response, 'can call deleteRateCard' );
     is( $response->operationSucceeded, 'true', 'delete rate card successfully' );
}


sub test_can_operate_rate_cards : Test(38) {
     my $self = shift;

     my $ysm_ws = Yahoo::Marketing::APT::RateCardService->new->parse_config( section => $self->section );

     my $formatter = DateTime::Format::W3CDTF->new;
     my $datetime = DateTime->now;
     $datetime->set_time_zone( 'America/Chicago' );
     $datetime->add( days => 1 );

     my $start_datetime = $formatter->format_datetime( $datetime );

     my $rate_card =  Yahoo::Marketing::APT::RateCard->new
                                                     ->currency( 'USD' )
                                                     ->siteID( $self->common_test_data( 'test_site' )->ID )
                                                     ->startDate( $start_datetime )
                                                         ;
     # test addRateCards
     my @responses = $ysm_ws->addRateCards( rateCards => [$rate_card] );
     ok( @responses, 'can call addRateCards' );
     is( $responses[0]->operationSucceeded, 'true', 'add rate cards successfully' );

     $rate_card = $responses[0]->rateCard;

     my $default_base_rate = Yahoo::Marketing::APT::DefaultBaseRate->new
                                                                   ->floorCPM( '5' )
                                                                   ->rateCardID( $rate_card->ID )
                                                                       ;
     # test addDefaultBaseRates
     @responses = $ysm_ws->addDefaultBaseRates( defaultBaseRates => [$default_base_rate] );
     ok( @responses, 'can call addDefaultBaseRates' );
     is( $responses[0]->operationSucceeded, 'true', 'add default base rates successfully' );
     $default_base_rate = $responses[0]->defaultBaseRate;

     # test getDefaultBaseRates
     my @default_base_rates = $ysm_ws->getDefaultBaseRates( defaultBaseRateIDs => [$default_base_rate->ID] );
     ok( @default_base_rates, 'can call getDefaultBaseRates' );
     is( $default_base_rates[0]->rateCardID, $rate_card->ID, 'rate card id matches' );

     # getDefaultBaseRateByRateCardID
     @default_base_rates = $ysm_ws->getDefaultBaseRateByRateCardID( rateCardID => $rate_card->ID );
     ok( @default_base_rates, 'can call getDefaultBaseRateByRateCardID' );
     my $find = 0;
     foreach ( @default_base_rates ) {
         ++$find and last if $_->ID eq $default_base_rate->ID;
     }
     is( $find, 1, 'can get default base rates by rate card id' );


     $default_base_rate->floorCPM( '6' );
     # test updateDefaultBaseRates
     @responses = $ysm_ws->updateDefaultBaseRates( defaultBaseRates => [$default_base_rate] );
     ok( @responses, 'can call updateDefaultBaseRates' );
     is( $responses[0]->operationSucceeded, 'true', 'update default base rates successfully' );
     $default_base_rate = $responses[0]->defaultBaseRate;
     is( $default_base_rate->floorCPM, '6.0', 'floor CPM matches');

     my $targeting_ws = Yahoo::Marketing::APT::TargetingDictionaryService->new->parse_config( section => $self->section );
     my @targeting_attributes = $targeting_ws->getTargetingAttributes(
         targetingAttributeType => 'Gender',
         startElement           => 0,
         numElements            => 1000,
     );
     my $targeting_attr_desc = Yahoo::Marketing::APT::TargetingAttributeDescriptorWithAny->new
                                                                                         ->targetingAttributeID( $targeting_attributes[0]->ID )
                                                                                         ->targetingAttributeType( 'Gender' )
                                                                                             ;
     my $base_rate = Yahoo::Marketing::APT::BaseRate->new
                                                    ->floorCPM( '5' )
                                                    ->rateCardID( $rate_card->ID )
                                                    ->targetingAttributeDescriptorsWithAny( [$targeting_attr_desc] )
                                                        ;
     # test addBaseRates
     @responses = $ysm_ws->addBaseRates( baseRates => [$base_rate] );
     ok( @responses, 'can call addBaseRates' );
     is( $responses[0]->operationSucceeded, 'true', 'add base rates successfully' );
     $base_rate = $responses[0]->baseRate;

     # test getBaseRates
     my @base_rates = $ysm_ws->getBaseRates( baseRateIDs => [$base_rate->ID] );
     ok( @base_rates, 'can call getBaseRates' );
     is( $base_rates[0]->rateCardID, $rate_card->ID, 'rate card id matches' );

     # test getBaseRatesByRateCardID
     @base_rates = $ysm_ws->getBaseRatesByRateCardID( rateCardID => $rate_card->ID );
     ok( @base_rates, 'can call getBaseRatesByRateCardID' );
     $find = 0;
     foreach ( @base_rates ) {
         ++$find and last if $_->ID eq $base_rate->ID;
     }
     is( $find, 1, 'can get base rates by rate card id' );

     $base_rate->floorCPM( '6' );
     # test updateBaseRates
     @responses = $ysm_ws->updateBaseRates( baseRates => [$base_rate] );
     ok( @responses, 'can call updateBaseRates' );
     is( $responses[0]->operationSucceeded, 'true', 'update base rates successfully' );
     $base_rate = $responses[0]->baseRate;
     is( $base_rate->floorCPM, '6.0', 'floor CPM matches');


     @targeting_attributes = $targeting_ws->getTargetingAttributes(
         targetingAttributeType => 'Income',
         startElement           => 0,
         numElements            => 1000,
     );
     $targeting_attr_desc = Yahoo::Marketing::APT::TargetingAttributeDescriptorWithAny->new
                                                                                      ->targetingAttributeID( $targeting_attributes[1]->ID )
                                                                                      ->targetingAttributeType( 'Income' )
                                                                                          ;
     my $rate_adj = Yahoo::Marketing::APT::RateAdjustment->new
                                                         ->percentageMarkup( 50 )
                                                         ->rateCardID( $rate_card->ID )
                                                         ->targetingAttributeDescriptorsWithAny( [$targeting_attr_desc] )
                                                             ;

     # test addRateAdjustments
     @responses = $ysm_ws->addRateAdjustments( rateAdjustments => [$rate_adj] );
     ok( @responses, 'can call addRateAdjustments' );
     is( $responses[0]->operationSucceeded, 'true', 'add rate adjustments successfully' );
     $rate_adj = $responses[0]->rateAdjustment;

     # test getRateAdjustments
     my @rate_adjs = $ysm_ws->getRateAdjustments( rateAdjustmentIDs => [$rate_adj->ID] );
     ok( @rate_adjs, 'can call getRateAdjustments' );
     is( $rate_adjs[0]->rateCardID, $rate_card->ID, 'rate card id matches' );

     # test getRateAdjustmentsByRateCardID
     @rate_adjs = $ysm_ws->getRateAdjustmentsByRateCardID( rateCardID => $rate_card->ID );
     ok( @rate_adjs, 'can call getRateAdjustmentsByRateCardID');
     $find = 0;
     foreach ( @rate_adjs ) {
         ++$find and last if $_->ID eq $rate_adj->ID;
     }
     is( $find, 1, 'can get rates adjustments by rate card id' );

     $rate_adj->floorCPM( undef );
     $rate_adj->percentageMarkup( 40 );
     $targeting_attr_desc->targetingAttributeID( $targeting_attributes[2]->ID );
     $rate_adj->targetingAttributeDescriptorsWithAny( [$targeting_attr_desc] );
     # test updateRateAdjustments
     @responses = $ysm_ws->updateRateAdjustments( rateAdjustments => [$rate_adj] );
     ok( @responses, 'can call updateRateAdjustments' );
     is( $responses[0]->operationSucceeded, 'true', 'update rate adjustments successfully' );
     $rate_adj = $responses[0]->rateAdjustment;
     is( $rate_adj->percentageMarkup, 40, 'percentage markup matches');

     # test updateRateCards
     @responses = $ysm_ws->updateRateCards( rateCards => [$rate_card] );
     ok( @responses, 'can call updateRateCards' );
     is( $responses[0]->operationSucceeded, 'true', 'update rate cards successfully' );
     $rate_card = $responses[0]->rateCard;

     # test getRateCards
     my @rate_cards = $ysm_ws->getRateCards( rateCardIDs => [$rate_card->ID] );
     ok( @rate_cards, 'can call getRateCards' );

     # test getRateCardsBySiteID
     @rate_cards = $ysm_ws->getRateCardsBySiteID( siteID => $self->common_test_data( 'test_site' )->ID );
     ok( @rate_cards, 'can call getRateCardsBySiteID' );
     $find = 0;
     foreach ( @rate_cards ) {
         ++$find and last if $_->ID eq $rate_card->ID;
     }
     is( $find, 1, 'can get rate cards by site id' );


     # test activateRateCards
     @responses = $ysm_ws->activateRateCards( rateCardIDs => [$rate_card->ID] );
     ok( @responses, 'can call activateRateCards' );
     is( $responses[0]->operationSucceeded, 'true', 'activate rate cards successfully' );
     $rate_card = $responses[0]->rateCard;

     # test deleteRateCards
     @responses = $ysm_ws->deleteRateCards( rateCardIDs => [$rate_card->ID] );
     ok( @responses, 'can call deleteRateCards' );
     is( $responses[0]->operationSucceeded, 'true', 'delete rate cards successfully' );

 }



1;

