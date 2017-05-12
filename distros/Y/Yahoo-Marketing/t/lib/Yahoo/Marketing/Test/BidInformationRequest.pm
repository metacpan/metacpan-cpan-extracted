package Yahoo::Marketing::Test::BidInformationRequest;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::BidInformationRequest;

sub test_can_create_bid_information_request_and_set_all_fields : Test(6) {

    my $bid_information_request = Yahoo::Marketing::BidInformationRequest->new
                                                                         ->accountID( 'account id' )
                                                                         ->adGroupID( 'ad group id' )
                                                                         ->keyword( 'keyword' )
                                                                         ->marketID( 'market id' )
                                                                         ->network( 'network' )
                   ;

    ok( $bid_information_request );

    is( $bid_information_request->accountID, 'account id', 'can get account id' );
    is( $bid_information_request->adGroupID, 'ad group id', 'can get ad group id' );
    is( $bid_information_request->keyword, 'keyword', 'can get keyword' );
    is( $bid_information_request->marketID, 'market id', 'can get market id' );
    is( $bid_information_request->network, 'network', 'can get network' );

};



1;

