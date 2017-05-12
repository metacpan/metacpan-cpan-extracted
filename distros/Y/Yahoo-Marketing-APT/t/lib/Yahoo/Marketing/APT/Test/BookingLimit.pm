package Yahoo::Marketing::APT::Test::BookingLimit;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::BookingLimit;

sub test_can_create_booking_limit_and_set_all_fields : Test(9) {

    my $booking_limit = Yahoo::Marketing::APT::BookingLimit->new
                                                      ->ID( 'id' )
                                                      ->bookingLimitPercentage( 'booking limit percentage' )
                                                      ->contentTopicIDs( 'content topic ids' )
                                                      ->createTimestamp( '2009-01-06T17:51:55' )
                                                      ->lastUpdateTimestamp( '2009-01-07T17:51:55' )
                                                      ->managedPublisherAccountID( 'managed publisher account id' )
                                                      ->sellingRuleType( 'selling rule type' )
                                                      ->siteID( 'site id' )
                   ;

    ok( $booking_limit );

    is( $booking_limit->ID, 'id', 'can get id' );
    is( $booking_limit->bookingLimitPercentage, 'booking limit percentage', 'can get booking limit percentage' );
    is( $booking_limit->contentTopicIDs, 'content topic ids', 'can get content topic ids' );
    is( $booking_limit->createTimestamp, '2009-01-06T17:51:55', 'can get 2009-01-06T17:51:55' );
    is( $booking_limit->lastUpdateTimestamp, '2009-01-07T17:51:55', 'can get 2009-01-07T17:51:55' );
    is( $booking_limit->managedPublisherAccountID, 'managed publisher account id', 'can get managed publisher account id' );
    is( $booking_limit->sellingRuleType, 'selling rule type', 'can get selling rule type' );
    is( $booking_limit->siteID, 'site id', 'can get site id' );

};



1;

