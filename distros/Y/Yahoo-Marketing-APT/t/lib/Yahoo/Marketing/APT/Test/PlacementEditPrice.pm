package Yahoo::Marketing::APT::Test::PlacementEditPrice;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::PlacementEditPrice;

sub test_can_create_placement_edit_price_and_set_all_fields : Test(5) {

    my $placement_edit_price = Yahoo::Marketing::APT::PlacementEditPrice->new
                                                                   ->price( 'price' )
                                                                   ->priceChangeType( 'price change type' )
                                                                   ->qtyChangeType( 'qty change type' )
                                                                   ->qtyType( 'qty type' )
                   ;

    ok( $placement_edit_price );

    is( $placement_edit_price->price, 'price', 'can get price' );
    is( $placement_edit_price->priceChangeType, 'price change type', 'can get price change type' );
    is( $placement_edit_price->qtyChangeType, 'qty change type', 'can get qty change type' );
    is( $placement_edit_price->qtyType, 'qty type', 'can get qty type' );

};



1;

