package Yahoo::Marketing::APT::Test::CustomizableFlashCreativeResponse;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::CustomizableFlashCreativeResponse;

sub test_can_create_customizable_flash_creative_response_and_set_all_fields : Test(4) {

    my $customizable_flash_creative_response = Yahoo::Marketing::APT::CustomizableFlashCreativeResponse->new
                                                                                                  ->customizableFlashCreative( 'customizable flash creative' )
                                                                                                  ->errors( 'errors' )
                                                                                                  ->operationSucceeded( 'operation succeeded' )
                   ;

    ok( $customizable_flash_creative_response );

    is( $customizable_flash_creative_response->customizableFlashCreative, 'customizable flash creative', 'can get customizable flash creative' );
    is( $customizable_flash_creative_response->errors, 'errors', 'can get errors' );
    is( $customizable_flash_creative_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );

};



1;

