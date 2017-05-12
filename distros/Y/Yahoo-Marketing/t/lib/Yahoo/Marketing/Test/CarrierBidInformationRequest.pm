package Yahoo::Marketing::Test::CarrierBidInformationRequest;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::CarrierBidInformationRequest;

sub test_can_create_carrier_bid_information_request_and_set_all_fields : Test(6) {

    my $carrier_bid_information_request = Yahoo::Marketing::CarrierBidInformationRequest->new
                                                                                        ->accountID( 'account id' )
                                                                                        ->adGroupID( 'ad group id' )
                                                                                        ->carriers( 'carriers' )
                                                                                        ->keyword( 'keyword' )
                                                                                        ->marketID( 'market id' )
                   ;

    ok( $carrier_bid_information_request );

    is( $carrier_bid_information_request->accountID, 'account id', 'can get account id' );
    is( $carrier_bid_information_request->adGroupID, 'ad group id', 'can get ad group id' );
    is( $carrier_bid_information_request->carriers, 'carriers', 'can get carriers' );
    is( $carrier_bid_information_request->keyword, 'keyword', 'can get keyword' );
    is( $carrier_bid_information_request->marketID, 'market id', 'can get market id' );

};



1;

