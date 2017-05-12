package Yahoo::Marketing::APT::Test::AdjustmentPlacement;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::AdjustmentPlacement;

sub test_can_create_adjustment_placement_and_set_all_fields : Test(17) {

    my $adjustment_placement = Yahoo::Marketing::APT::AdjustmentPlacement->new
                                                                    ->ID( 'id' )
                                                                    ->accountID( 'account id' )
                                                                    ->currency( 'currency' )
                                                                    ->deliveryGoal( 'delivery goal' )
                                                                    ->price( 'price' )
                                                                    ->primaryDeliveryStats( 'primary delivery stats' )
                                                                    ->primaryStatsCost( 'primary stats cost' )
                                                                    ->processingStatus( 'processing status' )
                                                                    ->reconciledDeliveryStats( 'reconciled delivery stats' )
                                                                    ->reconciledStatsCost( 'reconciled stats cost' )
                                                                    ->reconciliationAction( 'reconciliation action' )
                                                                    ->reconciliationComments( 'reconciliation comments' )
                                                                    ->reconciliationMonth( 'reconciliation month' )
                                                                    ->reconciliationRuleID( 'reconciliation rule id' )
                                                                    ->secondaryDeliveryStats( 'secondary delivery stats' )
                                                                    ->secondaryStatsCost( 'secondary stats cost' )
                   ;

    ok( $adjustment_placement );

    is( $adjustment_placement->ID, 'id', 'can get id' );
    is( $adjustment_placement->accountID, 'account id', 'can get account id' );
    is( $adjustment_placement->currency, 'currency', 'can get currency' );
    is( $adjustment_placement->deliveryGoal, 'delivery goal', 'can get delivery goal' );
    is( $adjustment_placement->price, 'price', 'can get price' );
    is( $adjustment_placement->primaryDeliveryStats, 'primary delivery stats', 'can get primary delivery stats' );
    is( $adjustment_placement->primaryStatsCost, 'primary stats cost', 'can get primary stats cost' );
    is( $adjustment_placement->processingStatus, 'processing status', 'can get processing status' );
    is( $adjustment_placement->reconciledDeliveryStats, 'reconciled delivery stats', 'can get reconciled delivery stats' );
    is( $adjustment_placement->reconciledStatsCost, 'reconciled stats cost', 'can get reconciled stats cost' );
    is( $adjustment_placement->reconciliationAction, 'reconciliation action', 'can get reconciliation action' );
    is( $adjustment_placement->reconciliationComments, 'reconciliation comments', 'can get reconciliation comments' );
    is( $adjustment_placement->reconciliationMonth, 'reconciliation month', 'can get reconciliation month' );
    is( $adjustment_placement->reconciliationRuleID, 'reconciliation rule id', 'can get reconciliation rule id' );
    is( $adjustment_placement->secondaryDeliveryStats, 'secondary delivery stats', 'can get secondary delivery stats' );
    is( $adjustment_placement->secondaryStatsCost, 'secondary stats cost', 'can get secondary stats cost' );

};



1;

