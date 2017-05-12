package Yahoo::Marketing::APT::Test::PiggybackPixel;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::PiggybackPixel;

sub test_can_create_piggyback_pixel_and_set_all_fields : Test(5) {

    my $piggyback_pixel = Yahoo::Marketing::APT::PiggybackPixel->new
                                                          ->createTimestamp( '2009-01-06T17:51:55' )
                                                          ->lastUpdateTimestamp( '2009-01-07T17:51:55' )
                                                          ->pixelCode( 'pixel code' )
                                                          ->pixelCodeType( 'pixel code type' )
                   ;

    ok( $piggyback_pixel );

    is( $piggyback_pixel->createTimestamp, '2009-01-06T17:51:55', 'can get 2009-01-06T17:51:55' );
    is( $piggyback_pixel->lastUpdateTimestamp, '2009-01-07T17:51:55', 'can get 2009-01-07T17:51:55' );
    is( $piggyback_pixel->pixelCode, 'pixel code', 'can get pixel code' );
    is( $piggyback_pixel->pixelCodeType, 'pixel code type', 'can get pixel code type' );

};



1;

