package Yahoo::Marketing::APT::Test::VideoCreativeAddRequest;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::VideoCreativeAddRequest;

sub test_can_create_video_creative_add_request_and_set_all_fields : Test(3) {

    my $video_creative_add_request = Yahoo::Marketing::APT::VideoCreativeAddRequest->new
                                                                              ->uploadToken( 'upload token' )
                                                                              ->videoCreative( 'video creative' )
                   ;

    ok( $video_creative_add_request );

    is( $video_creative_add_request->uploadToken, 'upload token', 'can get upload token' );
    is( $video_creative_add_request->videoCreative, 'video creative', 'can get video creative' );

};



1;

