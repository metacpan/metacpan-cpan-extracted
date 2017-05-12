package Yahoo::Marketing::APT::Test::Inventory;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::Inventory;

sub test_can_create_inventory_and_set_all_fields : Test(8) {

    my $inventory = Yahoo::Marketing::APT::Inventory->new
                                               ->availableImpressions( 'available impressions' )
                                               ->bookableImpressions( 'bookable impressions' )
                                               ->floorPrice( 'floor price' )
                                               ->listPrice( 'list price' )
                                               ->soldOutPeriods( 'sold out periods' )
                                               ->targetPrice( 'target price' )
                                               ->totalImpressions( 'total impressions' )
                   ;

    ok( $inventory );

    is( $inventory->availableImpressions, 'available impressions', 'can get available impressions' );
    is( $inventory->bookableImpressions, 'bookable impressions', 'can get bookable impressions' );
    is( $inventory->floorPrice, 'floor price', 'can get floor price' );
    is( $inventory->listPrice, 'list price', 'can get list price' );
    is( $inventory->soldOutPeriods, 'sold out periods', 'can get sold out periods' );
    is( $inventory->targetPrice, 'target price', 'can get target price' );
    is( $inventory->totalImpressions, 'total impressions', 'can get total impressions' );

};



1;

