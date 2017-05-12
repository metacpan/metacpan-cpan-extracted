package Yahoo::Marketing::APT::Test::InventoryOptInResponse;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::InventoryOptInResponse;

sub test_can_create_inventory_opt_in_response_and_set_all_fields : Test(4) {

    my $inventory_opt_in_response = Yahoo::Marketing::APT::InventoryOptInResponse->new
                                                                            ->errors( 'errors' )
                                                                            ->inventoryOptIn( 'inventory opt in' )
                                                                            ->operationSucceeded( 'operation succeeded' )
                   ;

    ok( $inventory_opt_in_response );

    is( $inventory_opt_in_response->errors, 'errors', 'can get errors' );
    is( $inventory_opt_in_response->inventoryOptIn, 'inventory opt in', 'can get inventory opt in' );
    is( $inventory_opt_in_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );

};



1;

