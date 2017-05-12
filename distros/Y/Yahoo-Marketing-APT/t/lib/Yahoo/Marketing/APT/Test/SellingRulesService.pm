package Yahoo::Marketing::APT::Test::SellingRulesService;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997)

use strict; use warnings;

use base qw/ Yahoo::Marketing::APT::Test::PostTest /;
use Test::More;
use utf8;

use Yahoo::Marketing::APT::AccountService;
use Yahoo::Marketing::APT::SellingRulesService;
use Yahoo::Marketing::APT::TargetingRule;
use Yahoo::Marketing::APT::SellingRule;
use Yahoo::Marketing::APT::BookingLimit;
use Yahoo::Marketing::APT::InventoryOptIn;
use Yahoo::Marketing::APT::TargetingAttributeDescriptor;

use Data::Dumper;

# use SOAP::Lite +trace => [qw/ debug method fault /];


sub SKIP_CLASS {
    my $self = shift;
    # 'not running post tests' is a true value
    return 'not running post tests' unless $self->run_post_tests;
    return;
}


sub test_operate_selling_rule_service : Test(34) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::APT::AccountService->new->parse_config(section => $self->section );
    my $publisher = ($ysm_ws->getManagedPublishersByAccountID( startElement => 0, numElements => 1 ))[0];

    $ysm_ws = Yahoo::Marketing::APT::SellingRulesService->new->parse_config( section => $self->section );

    # test addSellingRule
    my $targeting_rule = Yahoo::Marketing::APT::TargetingRule->new
                                                             ->targetingAttributesAllowedInOrders([ Yahoo::Marketing::APT::TargetingAttributeDescriptor->new->targetingAttributeID(2006501)->targetingAttributeType('Gender') ])
                                                                 ;
    my $selling_rule = Yahoo::Marketing::APT::SellingRule->new->name('test selling rule')->targetingRule( $targeting_rule );
    my $response = $ysm_ws->addSellingRule( sellingRule => $selling_rule );
    ok( $response );
    is( $response->operationSucceeded, 'true' );
    $selling_rule = $response->sellingRule;

    # test updateSellingRule
    $targeting_rule = Yahoo::Marketing::APT::TargetingRule->new
                                                          ->targetingAttributesAllowedInOrders([ Yahoo::Marketing::APT::TargetingAttributeDescriptor->new ->targetingAttributeID(2007001)->targetingAttributeType('Gender') ])
                                                                 ;
    $selling_rule->targetingRule($targeting_rule);
    $response = $ysm_ws->updateSellingRule( sellingRule => $selling_rule );
    ok( $response );
    is( $response->operationSucceeded, 'true' );
    $selling_rule = $response->sellingRule;

    # test getSellingRule
    my $retrieved_selling_rule = $ysm_ws->getSellingRule( sellingRuleID => $selling_rule->ID );
    ok( $retrieved_selling_rule );
    is( $retrieved_selling_rule->ID, $selling_rule->ID );

    # test deleteSellingRule
    $response = $ysm_ws->deleteSellingRule( sellingRuleID => $selling_rule->ID );
    ok( $response );
    is( $response->operationSucceeded, 'true' );

    # test addBookingLimitToPreferredSellingRule
    my $booking_limit = Yahoo::Marketing::APT::BookingLimit->new
                                                           ->bookingLimitPercentage(10)
                                                           ->managedPublisherAccountID( $publisher->ID )
                                                               ;
    $response = $ysm_ws->addBookingLimitToPreferredSellingRule( bookingLimit => $booking_limit );
    ok( $response );
    is( $response->operationSucceeded, 'true' );
    $booking_limit = $response->bookingLimit;

    # test getBookingLimitsForPreferredSellingRule
    my @booking_limits = $ysm_ws->getBookingLimitsForPreferredSellingRule();
    ok( @booking_limits );

    # test updateBookingLimit
    $booking_limit->bookingLimitPercentage(5);
    $response = $ysm_ws->updateBookingLimit( bookingLimit => $booking_limit );
    ok( $response );
    is( $response->operationSucceeded, 'true' );
    is( $booking_limit->bookingLimitPercentage, $response->bookingLimit->bookingLimitPercentage );

    # test getBookingLimit
    my $retrieved_booking_limit = $ysm_ws->getBookingLimit( bookingLimitID => $booking_limit->ID );
    ok( $retrieved_booking_limit );
    is( $retrieved_booking_limit->ID, $booking_limit->ID );

    # test deleteBookingLimit
    $response = $ysm_ws->deleteBookingLimit( bookingLimitID => $retrieved_booking_limit->ID );
    ok( $response );
    is( $response->operationSucceeded, 'true' );

    # test addBookingLimitToStandardSellingRule
    $booking_limit = Yahoo::Marketing::APT::BookingLimit->new
                                                           ->bookingLimitPercentage(20)
                                                           ->managedPublisherAccountID( $publisher->ID )
                                                               ;
    $response = $ysm_ws->addBookingLimitToStandardSellingRule( bookingLimit => $booking_limit );
    ok( $response );
    is( $response->operationSucceeded, 'true' );
    $booking_limit = $response->bookingLimit;

    # test getBookingLimitsForStandardSellingRule
    my @book_limits = $ysm_ws->getBookingLimitsForStandardSellingRule();
    ok( @book_limits );

    $ysm_ws->deleteBookingLimit( bookingLimitID => $booking_limit->ID );

    # test addInventoryOptInToStandardSellingRule
    my $inventory_optin = Yahoo::Marketing::APT::InventoryOptIn->new
                                                               ->managedPublisherAccountID( $publisher->ID )
                                                                   ;
    $response = $ysm_ws->addInventoryOptInToStandardSellingRule( inventoryOptIn => $inventory_optin );
    ok( $response );
    is( $response->operationSucceeded, 'true' );
    $inventory_optin = $response->inventoryOptIn;

    # test updateInventoryOptIn
    $response = $ysm_ws->updateInventoryOptIn( inventoryOptIn => $inventory_optin );
    ok( $response );
    is( $response->operationSucceeded, 'true' );

    # test getInventoryOptIn
    my $retrieved_inventory_optin = $ysm_ws->getInventoryOptIn( inventoryOptInID => $inventory_optin->ID );
    ok( $retrieved_inventory_optin );
    is( $retrieved_inventory_optin->ID, $inventory_optin->ID );

    # test deleteInventoryOptin
    $response = $ysm_ws->deleteInventoryOptIn( inventoryOptInID => $inventory_optin->ID );
    ok( $response );
    is( $response->operationSucceeded, 'true' );

    # test getStandardSellingRuleID
    my $standard_selling_rule_id = $ysm_ws->getStandardSellingRuleID();
    ok( $standard_selling_rule_id );

    # test getSupportedTargetingAttributeTypesForTargetingRule
    my @targeting_attr_types = $ysm_ws->getSupportedTargetingAttributeTypesForTargetingRule();
    ok( @targeting_attr_types );

    # test setTargetingRuleForStandardSellingRule
    $response = $ysm_ws->setTargetingRuleForStandardSellingRule( targetingRule => $targeting_rule );
    ok( $response );
    is( $response->operationSucceeded, 'true' );

    # test getTargetingRuleForStandardSellingRule
    $targeting_rule = $ysm_ws->getTargetingRuleForStandardSellingRule();
    ok( $targeting_rule );


}



1;
