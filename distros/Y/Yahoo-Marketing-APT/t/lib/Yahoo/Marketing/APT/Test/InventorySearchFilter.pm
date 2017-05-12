package Yahoo::Marketing::APT::Test::InventorySearchFilter;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::InventorySearchFilter;

sub test_can_create_inventory_search_filter_and_set_all_fields : Test(3) {

    my $inventory_search_filter = Yahoo::Marketing::APT::InventorySearchFilter->new
                                                                         ->maximumPrice( 'maximum price' )
                                                                         ->minimumImpressions( 'minimum impressions' )
                   ;

    ok( $inventory_search_filter );

    is( $inventory_search_filter->maximumPrice, 'maximum price', 'can get maximum price' );
    is( $inventory_search_filter->minimumImpressions, 'minimum impressions', 'can get minimum impressions' );

};



1;

