package Yahoo::Marketing::Test::BidUpdateInfo;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::BidUpdateInfo;

sub test_can_create_bid_update_info_and_set_all_fields : Test(5) {

    my $bid_update_info = Yahoo::Marketing::BidUpdateInfo->new
                                                         ->bid( 'bid' )
                                                         ->bidStatus( 'bid status' )
                                                         ->cutOffBid( 'cut off bid' )
                                                         ->keywordId( 'keyword id' )
                   ;

    ok( $bid_update_info );

    is( $bid_update_info->bid, 'bid', 'can get bid' );
    is( $bid_update_info->bidStatus, 'bid status', 'can get bid status' );
    is( $bid_update_info->cutOffBid, 'cut off bid', 'can get cut off bid' );
    is( $bid_update_info->keywordId, 'keyword id', 'can get keyword id' );

};



1;

