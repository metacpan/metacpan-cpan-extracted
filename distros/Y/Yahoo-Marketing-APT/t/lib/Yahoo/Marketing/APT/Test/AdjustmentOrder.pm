package Yahoo::Marketing::APT::Test::AdjustmentOrder;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::AdjustmentOrder;

sub test_can_create_adjustment_order_and_set_all_fields : Test(17) {

    my $adjustment_order = Yahoo::Marketing::APT::AdjustmentOrder->new
                                                            ->ID( 'id' )
                                                            ->accountID( 'account id' )
                                                            ->agencyName( 'agency name' )
                                                            ->certificationTimestamp( '2009-01-06T17:51:55' )
                                                            ->certifiedByUserID( 'certified by user id' )
                                                            ->certifiedByUserName( 'certified by user name' )
                                                            ->companyName( 'company name' )
                                                            ->currency( 'currency' )
                                                            ->endDate( '2009-01-07T17:51:55' )
                                                            ->lastReconciliationTimestamp( '2009-01-08T17:51:55' )
                                                            ->name( 'name' )
                                                            ->processingStatus( 'processing status' )
                                                            ->reconciliationMonth( 'reconciliation month' )
                                                            ->salesPersonName( 'sales person name' )
                                                            ->startDate( '2009-01-09T17:51:55' )
                                                            ->thirdPartySource( 'third party source' )
                   ;

    ok( $adjustment_order );

    is( $adjustment_order->ID, 'id', 'can get id' );
    is( $adjustment_order->accountID, 'account id', 'can get account id' );
    is( $adjustment_order->agencyName, 'agency name', 'can get agency name' );
    is( $adjustment_order->certificationTimestamp, '2009-01-06T17:51:55', 'can get 2009-01-06T17:51:55' );
    is( $adjustment_order->certifiedByUserID, 'certified by user id', 'can get certified by user id' );
    is( $adjustment_order->certifiedByUserName, 'certified by user name', 'can get certified by user name' );
    is( $adjustment_order->companyName, 'company name', 'can get company name' );
    is( $adjustment_order->currency, 'currency', 'can get currency' );
    is( $adjustment_order->endDate, '2009-01-07T17:51:55', 'can get 2009-01-07T17:51:55' );
    is( $adjustment_order->lastReconciliationTimestamp, '2009-01-08T17:51:55', 'can get 2009-01-08T17:51:55' );
    is( $adjustment_order->name, 'name', 'can get name' );
    is( $adjustment_order->processingStatus, 'processing status', 'can get processing status' );
    is( $adjustment_order->reconciliationMonth, 'reconciliation month', 'can get reconciliation month' );
    is( $adjustment_order->salesPersonName, 'sales person name', 'can get sales person name' );
    is( $adjustment_order->startDate, '2009-01-09T17:51:55', 'can get 2009-01-09T17:51:55' );
    is( $adjustment_order->thirdPartySource, 'third party source', 'can get third party source' );

};



1;

