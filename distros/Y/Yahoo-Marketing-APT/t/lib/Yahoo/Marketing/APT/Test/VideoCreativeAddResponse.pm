package Yahoo::Marketing::APT::Test::VideoCreativeAddResponse;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::VideoCreativeAddResponse;

sub test_can_create_video_creative_add_response_and_set_all_fields : Test(5) {

    my $video_creative_add_response = Yahoo::Marketing::APT::VideoCreativeAddResponse->new
                                                                                ->errors( 'errors' )
                                                                                ->operationSucceeded( 'operation succeeded' )
                                                                                ->uploadToken( 'upload token' )
                                                                                ->videoCreative( 'video creative' )
                   ;

    ok( $video_creative_add_response );

    is( $video_creative_add_response->errors, 'errors', 'can get errors' );
    is( $video_creative_add_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );
    is( $video_creative_add_response->uploadToken, 'upload token', 'can get upload token' );
    is( $video_creative_add_response->videoCreative, 'video creative', 'can get video creative' );

};



1;

