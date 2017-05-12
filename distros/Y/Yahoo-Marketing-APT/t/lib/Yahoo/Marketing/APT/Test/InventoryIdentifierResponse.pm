package Yahoo::Marketing::APT::Test::InventoryIdentifierResponse;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::InventoryIdentifierResponse;

sub test_can_create_inventory_identifier_response_and_set_all_fields : Test(4) {

    my $inventory_identifier_response = Yahoo::Marketing::APT::InventoryIdentifierResponse->new
                                                                                     ->errors( 'errors' )
                                                                                     ->inventoryIdentifier( 'inventory identifier' )
                                                                                     ->operationSucceeded( 'operation succeeded' )
                   ;

    ok( $inventory_identifier_response );

    is( $inventory_identifier_response->errors, 'errors', 'can get errors' );
    is( $inventory_identifier_response->inventoryIdentifier, 'inventory identifier', 'can get inventory identifier' );
    is( $inventory_identifier_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );

};



1;

