package Yahoo::Marketing::APT::Test::AdDeliveryModeResponse;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::AdDeliveryModeResponse;

sub test_can_create_ad_delivery_mode_response_and_set_all_fields : Test(4) {

    my $ad_delivery_mode_response = Yahoo::Marketing::APT::AdDeliveryModeResponse->new
                                                                            ->adDeliveryMode( 'ad delivery mode' )
                                                                            ->errors( 'errors' )
                                                                            ->operationSucceeded( 'operation succeeded' )
                   ;

    ok( $ad_delivery_mode_response );

    is( $ad_delivery_mode_response->adDeliveryMode, 'ad delivery mode', 'can get ad delivery mode' );
    is( $ad_delivery_mode_response->errors, 'errors', 'can get errors' );
    is( $ad_delivery_mode_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );

};



1;

