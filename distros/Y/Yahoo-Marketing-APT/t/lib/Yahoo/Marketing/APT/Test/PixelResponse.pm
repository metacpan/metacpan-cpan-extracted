package Yahoo::Marketing::APT::Test::PixelResponse;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::PixelResponse;

sub test_can_create_pixel_response_and_set_all_fields : Test(4) {

    my $pixel_response = Yahoo::Marketing::APT::PixelResponse->new
                                                        ->errors( 'errors' )
                                                        ->operationSucceeded( 'operation succeeded' )
                                                        ->pixel( 'pixel' )
                   ;

    ok( $pixel_response );

    is( $pixel_response->errors, 'errors', 'can get errors' );
    is( $pixel_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );
    is( $pixel_response->pixel, 'pixel', 'can get pixel' );

};



1;

