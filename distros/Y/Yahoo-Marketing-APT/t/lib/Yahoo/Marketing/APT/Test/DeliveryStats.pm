package Yahoo::Marketing::APT::Test::DeliveryStats;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::DeliveryStats;

sub test_can_create_delivery_stats_and_set_all_fields : Test(3) {

    my $delivery_stats = Yahoo::Marketing::APT::DeliveryStats->new
                                                        ->deliveryStats( 'delivery stats' )
                                                        ->deliveryType( 'delivery type' )
                   ;

    ok( $delivery_stats );

    is( $delivery_stats->deliveryStats, 'delivery stats', 'can get delivery stats' );
    is( $delivery_stats->deliveryType, 'delivery type', 'can get delivery type' );

};



1;

