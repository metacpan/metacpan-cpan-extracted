package Yahoo::Marketing::APT::Test::InventoryIdentifierService;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997)

use strict; use warnings;

use base qw/ Yahoo::Marketing::APT::Test::PostTest /;
use Test::More;
use utf8;

use Yahoo::Marketing::APT::InventoryIdentifierService;
use Yahoo::Marketing::APT::InventoryIdentifier;
use Yahoo::Marketing::APT::InventoryIdentifierResponse;
use Yahoo::Marketing::APT::PiggybackPixel;
use Yahoo::Marketing::APT::BasicResponse;
use Yahoo::Marketing::APT::TargetingAttributeDescriptor;
use Yahoo::Marketing::APT::TargetingDictionaryService;
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


sub test_operate_inventory_identifier : Test(9) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::APT::InventoryIdentifierService->new->parse_config( section => $self->section );

    # test getSupportedTargetingAttributeTypes
    my @types = $ysm_ws->getSupportedTargetingAttributeTypes();
    ok(@types, 'can call getSupportedTargetingAttributeTypes' );

    my $dic_ws = Yahoo::Marketing::APT::TargetingDictionaryService->new->parse_config( section => $self->section );
    my @values = $dic_ws->getTargetingAttributes(
        targetingAttributeType => 'AdSize',
        startElement           => 0,
        numElements            => 10,
    );

    my $inventory_identifier = Yahoo::Marketing::APT::InventoryIdentifier
        ->new
        ->name( 'test_inventory_identifier' )
        ->siteID( $self->common_test_data( 'test_site' )->ID )
        ->targetingAttributeDescriptors( [Yahoo::Marketing::APT::TargetingAttributeDescriptor->new->targetingAttributeID($values[0]->ID)->targetingAttributeType('AdSize')] );

    my $response = $ysm_ws->addInventoryIdentifier( inventoryIdentifier => $inventory_identifier );
    ok( $response, 'can call addInventoryIdentifier' );
    is( $response->operationSucceeded, 'true', 'add inventory identifier successfully' );
    $inventory_identifier = $response->inventoryIdentifier;

    # test getInventoryIdentifier
    my $fetched_inventory_identifier = $ysm_ws->getInventoryIdentifier( inventoryIdentifierID => $inventory_identifier->ID );
    ok( $fetched_inventory_identifier, 'can call getInventoryIdentifier' );
    is( $fetched_inventory_identifier->name, $inventory_identifier->name, 'name matches' );

    # test updateInventoryIdentifier
    $inventory_identifier->name( 'new_test_inventory_identifier' );
    $response = $ysm_ws->updateInventoryIdentifier( inventoryIdentifier => $inventory_identifier );
    ok( $response, 'can call updateInventoryIdentifier' );
    is( $response->operationSucceeded, 'true', 'update inventory identifier successfully' );

    # test deleteInventoryIdentifier
    $response = $ysm_ws->deleteInventoryIdentifier( inventoryIdentifierID => $inventory_identifier->ID );
    ok( $response, 'can call deleteInventoryIdentifier' );
    is( $response->operationSucceeded, 'true', 'delete inventory identifier successfully' );

}


sub test_operate_inventory_identifiers : Test(11) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::APT::InventoryIdentifierService->new->parse_config( section => $self->section );

    # test getSupportedTargetingAttributeTypes
    my @types = $ysm_ws->getSupportedTargetingAttributeTypes();
    ok(@types, 'can call getSupportedTargetingAttributeTypes' );

    my $dic_ws = Yahoo::Marketing::APT::TargetingDictionaryService->new->parse_config( section => $self->section );
    my @values = $dic_ws->getTargetingAttributes(
        targetingAttributeType => 'AdSize',
        startElement           => 0,
        numElements            => 10,
    );

    my $inventory_identifiers = [ Yahoo::Marketing::APT::InventoryIdentifier
        ->new
        ->name( 'test_inventory_identifier' )
        ->siteID( $self->common_test_data( 'test_site' )->ID )
        ->targetingAttributeDescriptors( [Yahoo::Marketing::APT::TargetingAttributeDescriptor->new->targetingAttributeID($values[0]->ID)->targetingAttributeType('AdSize')] ) ];

    my @responses = $ysm_ws->addInventoryIdentifiers( inventoryIdentifiers => $inventory_identifiers );
    ok( @responses, 'can call addInventoryIdentifiers' );
    is( $responses[0]->operationSucceeded, 'true', 'add inventory identifiers successfully' );
    $inventory_identifiers = [ $responses[0]->inventoryIdentifier ];

    # test getInventoryIdentifiers
    my @fetched_inventory_identifiers = $ysm_ws->getInventoryIdentifiers( inventoryIdentifierIDs => [$inventory_identifiers->[0]->ID] );
    ok( @fetched_inventory_identifiers, 'can call getInventoryIdentifiers' );
    is( $fetched_inventory_identifiers[0]->name, $inventory_identifiers->[0]->name, 'name matches' );

    # test updateInventoryIdentifiers
    $inventory_identifiers->[0]->name( 'new_test_inventory_identifier' );
    @responses = $ysm_ws->updateInventoryIdentifiers( inventoryIdentifiers => $inventory_identifiers );
    ok( @responses, 'can call updateInventoryIdentifiers' );
    is( $responses[0]->operationSucceeded, 'true', 'update inventory identifiers successfully' );

    # test getInventoryIdentifiersBySiteID
    @fetched_inventory_identifiers = $ysm_ws->getInventoryIdentifiersBySiteID( siteID => $self->common_test_data( 'test_site' )->ID );
    ok( @fetched_inventory_identifiers, 'can call getInventoryIdentifiersBySiteID' );
    ok( $fetched_inventory_identifiers[0]->ID, 'can get ID' );

    # test deleteInventoryIdentifiers
    @responses = $ysm_ws->deleteInventoryIdentifiers( inventoryIdentifierIDs => [$inventory_identifiers->[0]->ID] );
    ok( @responses, 'can call deleteInventoryIdentifiers' );
    is( $responses[0]->operationSucceeded, 'true', 'delete inventory identifiers successfully' );

}


1;
