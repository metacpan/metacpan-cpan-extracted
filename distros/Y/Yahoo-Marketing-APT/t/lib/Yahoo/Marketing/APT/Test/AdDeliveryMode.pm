package Yahoo::Marketing::APT::Test::AdDeliveryMode;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::AdDeliveryMode;

sub test_can_create_ad_delivery_mode_and_set_all_fields : Test(7) {

    my $ad_delivery_mode = Yahoo::Marketing::APT::AdDeliveryMode->new
                                                           ->ID( 'id' )
                                                           ->accountID( 'account id' )
                                                           ->description( 'description' )
                                                           ->name( 'name' )
                                                           ->origin( 'origin' )
                                                           ->parentID( 'parent id' )
                   ;

    ok( $ad_delivery_mode );

    is( $ad_delivery_mode->ID, 'id', 'can get id' );
    is( $ad_delivery_mode->accountID, 'account id', 'can get account id' );
    is( $ad_delivery_mode->description, 'description', 'can get description' );
    is( $ad_delivery_mode->name, 'name', 'can get name' );
    is( $ad_delivery_mode->origin, 'origin', 'can get origin' );
    is( $ad_delivery_mode->parentID, 'parent id', 'can get parent id' );

};



1;

