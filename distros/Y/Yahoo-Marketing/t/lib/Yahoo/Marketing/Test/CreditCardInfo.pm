package Yahoo::Marketing::Test::CreditCardInfo;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::CreditCardInfo;

sub test_can_create_credit_card_info_and_set_all_fields : Test(6) {

    my $credit_card_info = Yahoo::Marketing::CreditCardInfo->new
                                                           ->cardNumber( 'card number' )
                                                           ->cardType( 'card type' )
                                                           ->expMonth( 'exp month' )
                                                           ->expYear( 'exp year' )
                                                           ->securityCode( 'security code' )
                   ;

    ok( $credit_card_info );

    is( $credit_card_info->cardNumber, 'card number', 'can get card number' );
    is( $credit_card_info->cardType, 'card type', 'can get card type' );
    is( $credit_card_info->expMonth, 'exp month', 'can get exp month' );
    is( $credit_card_info->expYear, 'exp year', 'can get exp year' );
    is( $credit_card_info->securityCode, 'security code', 'can get security code' );

};



1;

