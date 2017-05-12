package Yahoo::Marketing::APT::Test::InventoryIdentifier;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::InventoryIdentifier;

sub test_can_create_inventory_identifier_and_set_all_fields : Test(6) {

    my $inventory_identifier = Yahoo::Marketing::APT::InventoryIdentifier->new
                                                                    ->ID( 'id' )
                                                                    ->description( 'description' )
                                                                    ->name( 'name' )
                                                                    ->siteID( 'site id' )
                                                                    ->targetingAttributeDescriptors( 'targeting attribute descriptors' )
                   ;

    ok( $inventory_identifier );

    is( $inventory_identifier->ID, 'id', 'can get id' );
    is( $inventory_identifier->description, 'description', 'can get description' );
    is( $inventory_identifier->name, 'name', 'can get name' );
    is( $inventory_identifier->siteID, 'site id', 'can get site id' );
    is( $inventory_identifier->targetingAttributeDescriptors, 'targeting attribute descriptors', 'can get targeting attribute descriptors' );

};



1;

