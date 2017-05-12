package Yahoo::Marketing::APT::Test::AdjustmentOrderRequest;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::AdjustmentOrderRequest;

sub test_can_create_adjustment_order_request_and_set_all_fields : Test(3) {

    my $adjustment_order_request = Yahoo::Marketing::APT::AdjustmentOrderRequest->new
                                                                           ->adjustmentOrderID( 'adjustment order id' )
                                                                           ->reconciliationMonth( 'reconciliation month' )
                   ;

    ok( $adjustment_order_request );

    is( $adjustment_order_request->adjustmentOrderID, 'adjustment order id', 'can get adjustment order id' );
    is( $adjustment_order_request->reconciliationMonth, 'reconciliation month', 'can get reconciliation month' );

};



1;

