package Yahoo::Marketing::APT::Test::Pixel;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::Pixel;

sub test_can_create_pixel_and_set_all_fields : Test(11) {

    my $pixel = Yahoo::Marketing::APT::Pixel->new
                                       ->ID( 'id' )
                                       ->accountID( 'account id' )
                                       ->clickLookBackTimePeriod( 'click look back time period' )
                                       ->createTimestamp( '2009-01-06T17:51:55' )
                                       ->expirationTimePeriod( 'expiration time period' )
                                       ->impressionLookBackTimePeriod( 'impression look back time period' )
                                       ->isActive( 'is active' )
                                       ->lastUpdateTimestamp( '2009-01-07T17:51:55' )
                                       ->name( 'name' )
                                       ->pixelFrequency( 'pixel frequency' )
                   ;

    ok( $pixel );

    is( $pixel->ID, 'id', 'can get id' );
    is( $pixel->accountID, 'account id', 'can get account id' );
    is( $pixel->clickLookBackTimePeriod, 'click look back time period', 'can get click look back time period' );
    is( $pixel->createTimestamp, '2009-01-06T17:51:55', 'can get 2009-01-06T17:51:55' );
    is( $pixel->expirationTimePeriod, 'expiration time period', 'can get expiration time period' );
    is( $pixel->impressionLookBackTimePeriod, 'impression look back time period', 'can get impression look back time period' );
    is( $pixel->isActive, 'is active', 'can get is active' );
    is( $pixel->lastUpdateTimestamp, '2009-01-07T17:51:55', 'can get 2009-01-07T17:51:55' );
    is( $pixel->name, 'name', 'can get name' );
    is( $pixel->pixelFrequency, 'pixel frequency', 'can get pixel frequency' );

};



1;

