package Yahoo::Marketing::APT::Test::AdDeliveryModeDescriptor;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::AdDeliveryModeDescriptor;

sub test_can_create_ad_delivery_mode_descriptor_and_set_all_fields : Test(5) {

    my $ad_delivery_mode_descriptor = Yahoo::Marketing::APT::AdDeliveryModeDescriptor->new
                                                                                ->ID( 'id' )
                                                                                ->accountID( 'account id' )
                                                                                ->description( 'description' )
                                                                                ->name( 'name' )
                   ;

    ok( $ad_delivery_mode_descriptor );

    is( $ad_delivery_mode_descriptor->ID, 'id', 'can get id' );
    is( $ad_delivery_mode_descriptor->accountID, 'account id', 'can get account id' );
    is( $ad_delivery_mode_descriptor->description, 'description', 'can get description' );
    is( $ad_delivery_mode_descriptor->name, 'name', 'can get name' );

};



1;

