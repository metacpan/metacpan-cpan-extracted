package Yahoo::Marketing::APT::Test::CostFeed;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::CostFeed;

sub test_can_create_cost_feed_and_set_all_fields : Test(5) {

    my $cost_feed = Yahoo::Marketing::APT::CostFeed->new
                                              ->ID( 'id' )
                                              ->accountID( 'account id' )
                                              ->createTimestamp( '2009-01-06T17:51:55' )
                                              ->downloadURL( 'download url' )
                   ;

    ok( $cost_feed );

    is( $cost_feed->ID, 'id', 'can get id' );
    is( $cost_feed->accountID, 'account id', 'can get account id' );
    is( $cost_feed->createTimestamp, '2009-01-06T17:51:55', 'can get 2009-01-06T17:51:55' );
    is( $cost_feed->downloadURL, 'download url', 'can get download url' );

};



1;

