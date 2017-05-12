package Yahoo::Marketing::APT::Test::FlashCreativeResponse;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::FlashCreativeResponse;

sub test_can_create_flash_creative_response_and_set_all_fields : Test(4) {

    my $flash_creative_response = Yahoo::Marketing::APT::FlashCreativeResponse->new
                                                                         ->errors( 'errors' )
                                                                         ->flashCreative( 'flash creative' )
                                                                         ->operationSucceeded( 'operation succeeded' )
                   ;

    ok( $flash_creative_response );

    is( $flash_creative_response->errors, 'errors', 'can get errors' );
    is( $flash_creative_response->flashCreative, 'flash creative', 'can get flash creative' );
    is( $flash_creative_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );

};



1;

