package Yahoo::Marketing::APT::Test::AdjustmentInboundFeed;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::AdjustmentInboundFeed;

sub test_can_create_adjustment_inbound_feed_and_set_all_fields : Test(12) {

    my $adjustment_inbound_feed = Yahoo::Marketing::APT::AdjustmentInboundFeed->new
                                                                         ->ID( 'id' )
                                                                         ->accountID( 'account id' )
                                                                         ->comment( 'comment' )
                                                                         ->downloadURL( 'download url' )
                                                                         ->fileName( 'file name' )
                                                                         ->lastUpdateTimestamp( '2009-01-06T17:51:55' )
                                                                         ->status( 'status' )
                                                                         ->type( 'type' )
                                                                         ->uploadTimestamp( '2009-01-07T17:51:55' )
                                                                         ->uploadedByUserID( 'uploaded by user id' )
                                                                         ->uploadedByUserName( 'uploaded by user name' )
                   ;

    ok( $adjustment_inbound_feed );

    is( $adjustment_inbound_feed->ID, 'id', 'can get id' );
    is( $adjustment_inbound_feed->accountID, 'account id', 'can get account id' );
    is( $adjustment_inbound_feed->comment, 'comment', 'can get comment' );
    is( $adjustment_inbound_feed->downloadURL, 'download url', 'can get download url' );
    is( $adjustment_inbound_feed->fileName, 'file name', 'can get file name' );
    is( $adjustment_inbound_feed->lastUpdateTimestamp, '2009-01-06T17:51:55', 'can get 2009-01-06T17:51:55' );
    is( $adjustment_inbound_feed->status, 'status', 'can get status' );
    is( $adjustment_inbound_feed->type, 'type', 'can get type' );
    is( $adjustment_inbound_feed->uploadTimestamp, '2009-01-07T17:51:55', 'can get 2009-01-07T17:51:55' );
    is( $adjustment_inbound_feed->uploadedByUserID, 'uploaded by user id', 'can get uploaded by user id' );
    is( $adjustment_inbound_feed->uploadedByUserName, 'uploaded by user name', 'can get uploaded by user name' );

};



1;

