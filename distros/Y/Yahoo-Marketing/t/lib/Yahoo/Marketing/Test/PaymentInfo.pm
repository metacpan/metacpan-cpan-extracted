package Yahoo::Marketing::Test::PaymentInfo;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::PaymentInfo;

sub test_can_create_payment_info_and_set_all_fields : Test(3) {

    my $payment_info = Yahoo::Marketing::PaymentInfo->new
                                                    ->chargeAmount( 'charge amount' )
                                                    ->paymentMethodId( 'payment method id' )
                   ;

    ok( $payment_info );

    is( $payment_info->chargeAmount, 'charge amount', 'can get charge amount' );
    is( $payment_info->paymentMethodId, 'payment method id', 'can get payment method id' );

};



1;

