package Yahoo::Marketing::APT::Test::CustomSegmentResponse;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::CustomSegmentResponse;

sub test_can_create_custom_segment_response_and_set_all_fields : Test(4) {

    my $custom_segment_response = Yahoo::Marketing::APT::CustomSegmentResponse->new
                                                                         ->customSegment( 'custom segment' )
                                                                         ->errors( 'errors' )
                                                                         ->operationSucceeded( 'operation succeeded' )
                   ;

    ok( $custom_segment_response );

    is( $custom_segment_response->customSegment, 'custom segment', 'can get custom segment' );
    is( $custom_segment_response->errors, 'errors', 'can get errors' );
    is( $custom_segment_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );

};



1;

