package Yahoo::Marketing::APT::Test::AdjustmentInboundFeedAddRequest;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::AdjustmentInboundFeedAddRequest;

sub test_can_create_adjustment_inbound_feed_add_request_and_set_all_fields : Test(3) {

    my $adjustment_inbound_feed_add_request = Yahoo::Marketing::APT::AdjustmentInboundFeedAddRequest->new
                                                                                               ->adjustmentInboundFeed( 'adjustment inbound feed' )
                                                                                               ->uploadToken( 'upload token' )
                   ;

    ok( $adjustment_inbound_feed_add_request );

    is( $adjustment_inbound_feed_add_request->adjustmentInboundFeed, 'adjustment inbound feed', 'can get adjustment inbound feed' );
    is( $adjustment_inbound_feed_add_request->uploadToken, 'upload token', 'can get upload token' );

};



1;

