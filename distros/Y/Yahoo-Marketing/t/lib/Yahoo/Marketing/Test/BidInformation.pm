package Yahoo::Marketing::Test::BidInformation;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::BidInformation;

sub test_can_create_bid_information_and_set_all_fields : Test(3) {

    my $bid_information = Yahoo::Marketing::BidInformation->new
                                                          ->bid( 'bid' )
                                                          ->cutOffBid( 'cut off bid' )
                   ;

    ok( $bid_information );

    is( $bid_information->bid, 'bid', 'can get bid' );
    is( $bid_information->cutOffBid, 'cut off bid', 'can get cut off bid' );

};



1;

