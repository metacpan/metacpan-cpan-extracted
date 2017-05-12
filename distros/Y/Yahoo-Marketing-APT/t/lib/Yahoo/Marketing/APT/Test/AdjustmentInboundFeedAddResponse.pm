package Yahoo::Marketing::APT::Test::AdjustmentInboundFeedAddResponse;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::AdjustmentInboundFeedAddResponse;

sub test_can_create_adjustment_inbound_feed_add_response_and_set_all_fields : Test(5) {

    my $adjustment_inbound_feed_add_response = Yahoo::Marketing::APT::AdjustmentInboundFeedAddResponse->new
                                                                                                 ->adjustmentInboundFeed( 'adjustment inbound feed' )
                                                                                                 ->errors( 'errors' )
                                                                                                 ->operationSucceeded( 'operation succeeded' )
                                                                                                 ->uploadToken( 'upload token' )
                   ;

    ok( $adjustment_inbound_feed_add_response );

    is( $adjustment_inbound_feed_add_response->adjustmentInboundFeed, 'adjustment inbound feed', 'can get adjustment inbound feed' );
    is( $adjustment_inbound_feed_add_response->errors, 'errors', 'can get errors' );
    is( $adjustment_inbound_feed_add_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );
    is( $adjustment_inbound_feed_add_response->uploadToken, 'upload token', 'can get upload token' );

};



1;

