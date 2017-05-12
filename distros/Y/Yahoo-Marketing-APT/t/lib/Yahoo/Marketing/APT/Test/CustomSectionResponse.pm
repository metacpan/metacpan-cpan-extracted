package Yahoo::Marketing::APT::Test::CustomSectionResponse;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::CustomSectionResponse;

sub test_can_create_custom_section_response_and_set_all_fields : Test(4) {

    my $custom_section_response = Yahoo::Marketing::APT::CustomSectionResponse->new
                                                                         ->customSection( 'custom section' )
                                                                         ->errors( 'errors' )
                                                                         ->operationSucceeded( 'operation succeeded' )
                   ;

    ok( $custom_section_response );

    is( $custom_section_response->customSection, 'custom section', 'can get custom section' );
    is( $custom_section_response->errors, 'errors', 'can get errors' );
    is( $custom_section_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );

};



1;

