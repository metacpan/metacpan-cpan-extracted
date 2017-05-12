package Yahoo::Marketing::APT::Test::CustomContentCategoryResponse;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::CustomContentCategoryResponse;

sub test_can_create_custom_content_category_response_and_set_all_fields : Test(4) {

    my $custom_content_category_response = Yahoo::Marketing::APT::CustomContentCategoryResponse->new
                                                                                          ->category( 'category' )
                                                                                          ->errors( 'errors' )
                                                                                          ->operationSucceeded( 'operation succeeded' )
                   ;

    ok( $custom_content_category_response );

    is( $custom_content_category_response->category, 'category', 'can get category' );
    is( $custom_content_category_response->errors, 'errors', 'can get errors' );
    is( $custom_content_category_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );

};



1;

