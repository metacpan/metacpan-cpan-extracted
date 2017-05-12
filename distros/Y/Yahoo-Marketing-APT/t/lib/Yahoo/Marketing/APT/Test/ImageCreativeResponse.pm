package Yahoo::Marketing::APT::Test::ImageCreativeResponse;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::ImageCreativeResponse;

sub test_can_create_image_creative_response_and_set_all_fields : Test(4) {

    my $image_creative_response = Yahoo::Marketing::APT::ImageCreativeResponse->new
                                                                         ->errors( 'errors' )
                                                                         ->imageCreative( 'image creative' )
                                                                         ->operationSucceeded( 'operation succeeded' )
                   ;

    ok( $image_creative_response );

    is( $image_creative_response->errors, 'errors', 'can get errors' );
    is( $image_creative_response->imageCreative, 'image creative', 'can get image creative' );
    is( $image_creative_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );

};



1;

