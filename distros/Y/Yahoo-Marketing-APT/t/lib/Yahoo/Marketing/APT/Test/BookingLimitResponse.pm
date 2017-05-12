package Yahoo::Marketing::APT::Test::BookingLimitResponse;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::BookingLimitResponse;

sub test_can_create_booking_limit_response_and_set_all_fields : Test(4) {

    my $booking_limit_response = Yahoo::Marketing::APT::BookingLimitResponse->new
                                                                       ->bookingLimit( 'booking limit' )
                                                                       ->errors( 'errors' )
                                                                       ->operationSucceeded( 'operation succeeded' )
                   ;

    ok( $booking_limit_response );

    is( $booking_limit_response->bookingLimit, 'booking limit', 'can get booking limit' );
    is( $booking_limit_response->errors, 'errors', 'can get errors' );
    is( $booking_limit_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );

};



1;

