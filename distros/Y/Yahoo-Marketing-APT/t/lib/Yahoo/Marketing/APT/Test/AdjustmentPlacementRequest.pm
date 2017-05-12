package Yahoo::Marketing::APT::Test::AdjustmentPlacementRequest;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::AdjustmentPlacementRequest;

sub test_can_create_adjustment_placement_request_and_set_all_fields : Test(3) {

    my $adjustment_placement_request = Yahoo::Marketing::APT::AdjustmentPlacementRequest->new
                                                                                   ->adjustmentPlacementID( 'adjustment placement id' )
                                                                                   ->reconciliationMonth( 'reconciliation month' )
                   ;

    ok( $adjustment_placement_request );

    is( $adjustment_placement_request->adjustmentPlacementID, 'adjustment placement id', 'can get adjustment placement id' );
    is( $adjustment_placement_request->reconciliationMonth, 'reconciliation month', 'can get reconciliation month' );

};



1;

