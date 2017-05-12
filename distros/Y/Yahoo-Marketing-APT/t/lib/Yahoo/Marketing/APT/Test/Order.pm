package Yahoo::Marketing::APT::Test::Order;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::Order;

sub test_can_create_order_and_set_all_fields : Test(23) {

    my $order = Yahoo::Marketing::APT::Order->new
                                       ->ID( 'id' )
                                       ->PONumber( 'ponumber' )
                                       ->accountID( 'account id' )
                                       ->availableBudget( 'available budget' )
                                       ->billingTermsID( 'billing terms id' )
                                       ->createTimestamp( '2009-01-06T17:51:55' )
                                       ->currency( 'currency' )
                                       ->dailySpendLimit( 'daily spend limit' )
                                       ->endDate( '2009-01-07T17:51:55' )
                                       ->externalComments( 'external comments' )
                                       ->externalOrderID( 'external order id' )
                                       ->grossCost( 'gross cost' )
                                       ->internalComments( 'internal comments' )
                                       ->isBillOnThirdParty( 'is bill on third party' )
                                       ->isInternal( 'is internal' )
                                       ->lastUpdateTimestamp( '2009-01-08T17:51:55' )
                                       ->name( 'name' )
                                       ->netBudget( 'net budget' )
                                       ->startDate( '2009-01-09T17:51:55' )
                                       ->status( 'status' )
                                       ->timezone( 'timezone' )
                                       ->totalBudget( 'total budget' )
                   ;

    ok( $order );

    is( $order->ID, 'id', 'can get id' );
    is( $order->PONumber, 'ponumber', 'can get ponumber' );
    is( $order->accountID, 'account id', 'can get account id' );
    is( $order->availableBudget, 'available budget', 'can get available budget' );
    is( $order->billingTermsID, 'billing terms id', 'can get billing terms id' );
    is( $order->createTimestamp, '2009-01-06T17:51:55', 'can get 2009-01-06T17:51:55' );
    is( $order->currency, 'currency', 'can get currency' );
    is( $order->dailySpendLimit, 'daily spend limit', 'can get daily spend limit' );
    is( $order->endDate, '2009-01-07T17:51:55', 'can get 2009-01-07T17:51:55' );
    is( $order->externalComments, 'external comments', 'can get external comments' );
    is( $order->externalOrderID, 'external order id', 'can get external order id' );
    is( $order->grossCost, 'gross cost', 'can get gross cost' );
    is( $order->internalComments, 'internal comments', 'can get internal comments' );
    is( $order->isBillOnThirdParty, 'is bill on third party', 'can get is bill on third party' );
    is( $order->isInternal, 'is internal', 'can get is internal' );
    is( $order->lastUpdateTimestamp, '2009-01-08T17:51:55', 'can get 2009-01-08T17:51:55' );
    is( $order->name, 'name', 'can get name' );
    is( $order->netBudget, 'net budget', 'can get net budget' );
    is( $order->startDate, '2009-01-09T17:51:55', 'can get 2009-01-09T17:51:55' );
    is( $order->status, 'status', 'can get status' );
    is( $order->timezone, 'timezone', 'can get timezone' );
    is( $order->totalBudget, 'total budget', 'can get total budget' );

};



1;

