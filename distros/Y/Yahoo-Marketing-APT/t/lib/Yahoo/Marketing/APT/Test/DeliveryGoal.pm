package Yahoo::Marketing::APT::Test::DeliveryGoal;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::DeliveryGoal;

sub test_can_create_delivery_goal_and_set_all_fields : Test(3) {

    my $delivery_goal = Yahoo::Marketing::APT::DeliveryGoal->new
                                                      ->deliveryTarget( 'delivery target' )
                                                      ->deliveryType( 'delivery type' )
                   ;

    ok( $delivery_goal );

    is( $delivery_goal->deliveryTarget, 'delivery target', 'can get delivery target' );
    is( $delivery_goal->deliveryType, 'delivery type', 'can get delivery type' );

};



1;

