package Yahoo::Marketing::APT::Test::CustomizableFlashTemplateResponse;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::CustomizableFlashTemplateResponse;

sub test_can_create_customizable_flash_template_response_and_set_all_fields : Test(4) {

    my $customizable_flash_template_response = Yahoo::Marketing::APT::CustomizableFlashTemplateResponse->new
                                                                                                  ->customizableFlashTemplate( 'customizable flash template' )
                                                                                                  ->errors( 'errors' )
                                                                                                  ->operationSucceeded( 'operation succeeded' )
                   ;

    ok( $customizable_flash_template_response );

    is( $customizable_flash_template_response->customizableFlashTemplate, 'customizable flash template', 'can get customizable flash template' );
    is( $customizable_flash_template_response->errors, 'errors', 'can get errors' );
    is( $customizable_flash_template_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );

};



1;

