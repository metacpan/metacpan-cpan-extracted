package Yahoo::Marketing::APT::Test::ZippedCreativesResponse;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::ZippedCreativesResponse;

sub test_can_create_zipped_creatives_response_and_set_all_fields : Test(5) {

    my $zipped_creatives_response = Yahoo::Marketing::APT::ZippedCreativesResponse->new
                                                                             ->errors( 'errors' )
                                                                             ->flashCreatives( 'flash creatives' )
                                                                             ->imageCreatives( 'image creatives' )
                                                                             ->operationResult( 'operation result' )
                   ;

    ok( $zipped_creatives_response );

    is( $zipped_creatives_response->errors, 'errors', 'can get errors' );
    is( $zipped_creatives_response->flashCreatives, 'flash creatives', 'can get flash creatives' );
    is( $zipped_creatives_response->imageCreatives, 'image creatives', 'can get image creatives' );
    is( $zipped_creatives_response->operationResult, 'operation result', 'can get operation result' );

};



1;

