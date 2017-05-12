package Yahoo::Marketing::APT::Test::InventoryOptIn;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::InventoryOptIn;

sub test_can_create_inventory_opt_in_and_set_all_fields : Test(8) {

    my $inventory_opt_in = Yahoo::Marketing::APT::InventoryOptIn->new
                                                           ->ID( 'id' )
                                                           ->adSizeIDs( 'ad size ids' )
                                                           ->contentTopicIDs( 'content topic ids' )
                                                           ->createTimestamp( '2009-01-06T17:51:55' )
                                                           ->lastUpdateTimestamp( '2009-01-07T17:51:55' )
                                                           ->managedPublisherAccountID( 'managed publisher account id' )
                                                           ->siteID( 'site id' )
                   ;

    ok( $inventory_opt_in );

    is( $inventory_opt_in->ID, 'id', 'can get id' );
    is( $inventory_opt_in->adSizeIDs, 'ad size ids', 'can get ad size ids' );
    is( $inventory_opt_in->contentTopicIDs, 'content topic ids', 'can get content topic ids' );
    is( $inventory_opt_in->createTimestamp, '2009-01-06T17:51:55', 'can get 2009-01-06T17:51:55' );
    is( $inventory_opt_in->lastUpdateTimestamp, '2009-01-07T17:51:55', 'can get 2009-01-07T17:51:55' );
    is( $inventory_opt_in->managedPublisherAccountID, 'managed publisher account id', 'can get managed publisher account id' );
    is( $inventory_opt_in->siteID, 'site id', 'can get site id' );

};



1;

