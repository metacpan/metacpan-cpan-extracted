package Yahoo::Marketing::APT::Test::RateCardResponse;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::RateCardResponse;

sub test_can_create_rate_card_response_and_set_all_fields : Test(4) {

    my $rate_card_response = Yahoo::Marketing::APT::RateCardResponse->new
                                                               ->errors( 'errors' )
                                                               ->operationSucceeded( 'operation succeeded' )
                                                               ->rateCard( 'rate card' )
                   ;

    ok( $rate_card_response );

    is( $rate_card_response->errors, 'errors', 'can get errors' );
    is( $rate_card_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );
    is( $rate_card_response->rateCard, 'rate card', 'can get rate card' );

};



1;

