package Yahoo::Marketing::APT::Test::AudienceSegmentCategoryResponse;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::AudienceSegmentCategoryResponse;

sub test_can_create_audience_segment_category_response_and_set_all_fields : Test(4) {

    my $audience_segment_category_response = Yahoo::Marketing::APT::AudienceSegmentCategoryResponse->new
                                                                                              ->audienceSegmentCategory( 'audience segment category' )
                                                                                              ->errors( 'errors' )
                                                                                              ->operationSucceeded( 'operation succeeded' )
                   ;

    ok( $audience_segment_category_response );

    is( $audience_segment_category_response->audienceSegmentCategory, 'audience segment category', 'can get audience segment category' );
    is( $audience_segment_category_response->errors, 'errors', 'can get errors' );
    is( $audience_segment_category_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );

};



1;

