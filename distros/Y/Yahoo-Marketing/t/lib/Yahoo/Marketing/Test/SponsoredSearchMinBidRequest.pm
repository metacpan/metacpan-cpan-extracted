package Yahoo::Marketing::Test::SponsoredSearchMinBidRequest;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::SponsoredSearchMinBidRequest;

sub test_can_create_sponsored_search_min_bid_request_and_set_all_fields : Test(3) {

    my $sponsored_search_min_bid_request = Yahoo::Marketing::SponsoredSearchMinBidRequest->new
                                                                                         ->adGroupID( 'ad group id' )
                                                                                         ->keyword( 'keyword' )
                   ;

    ok( $sponsored_search_min_bid_request );

    is( $sponsored_search_min_bid_request->adGroupID, 'ad group id', 'can get ad group id' );
    is( $sponsored_search_min_bid_request->keyword, 'keyword', 'can get keyword' );

};



1;

