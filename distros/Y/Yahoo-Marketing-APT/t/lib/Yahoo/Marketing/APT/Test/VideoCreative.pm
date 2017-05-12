package Yahoo::Marketing::APT::Test::VideoCreative;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::VideoCreative;

sub test_can_create_video_creative_and_set_all_fields : Test(21) {

    my $video_creative = Yahoo::Marketing::APT::VideoCreative->new
                                                        ->ID( 'id' )
                                                        ->accountID( 'account id' )
                                                        ->aspectHeight( 'aspect height' )
                                                        ->aspectWidth( 'aspect width' )
                                                        ->createTimestamp( '2009-01-06T17:51:55' )
                                                        ->fileExtension( 'file extension' )
                                                        ->folderID( 'folder id' )
                                                        ->height( 'height' )
                                                        ->lastUpdateTimestamp( '2009-01-07T17:51:55' )
                                                        ->name( 'name' )
                                                        ->oneHundredKbsURL( 'one hundred kbs url' )
                                                        ->oneThousandKbsURL( 'one thousand kbs url' )
                                                        ->processingStatus( 'processing status' )
                                                        ->sevenHundredKbsURL( 'seven hundred kbs url' )
                                                        ->status( 'status' )
                                                        ->threeHundredKbsURL( 'three hundred kbs url' )
                                                        ->thumbnailURL( 'thumbnail url' )
                                                        ->type( 'type' )
                                                        ->weight( 'weight' )
                                                        ->width( 'width' )
                   ;

    ok( $video_creative );

    is( $video_creative->ID, 'id', 'can get id' );
    is( $video_creative->accountID, 'account id', 'can get account id' );
    is( $video_creative->aspectHeight, 'aspect height', 'can get aspect height' );
    is( $video_creative->aspectWidth, 'aspect width', 'can get aspect width' );
    is( $video_creative->createTimestamp, '2009-01-06T17:51:55', 'can get 2009-01-06T17:51:55' );
    is( $video_creative->fileExtension, 'file extension', 'can get file extension' );
    is( $video_creative->folderID, 'folder id', 'can get folder id' );
    is( $video_creative->height, 'height', 'can get height' );
    is( $video_creative->lastUpdateTimestamp, '2009-01-07T17:51:55', 'can get 2009-01-07T17:51:55' );
    is( $video_creative->name, 'name', 'can get name' );
    is( $video_creative->oneHundredKbsURL, 'one hundred kbs url', 'can get one hundred kbs url' );
    is( $video_creative->oneThousandKbsURL, 'one thousand kbs url', 'can get one thousand kbs url' );
    is( $video_creative->processingStatus, 'processing status', 'can get processing status' );
    is( $video_creative->sevenHundredKbsURL, 'seven hundred kbs url', 'can get seven hundred kbs url' );
    is( $video_creative->status, 'status', 'can get status' );
    is( $video_creative->threeHundredKbsURL, 'three hundred kbs url', 'can get three hundred kbs url' );
    is( $video_creative->thumbnailURL, 'thumbnail url', 'can get thumbnail url' );
    is( $video_creative->type, 'type', 'can get type' );
    is( $video_creative->weight, 'weight', 'can get weight' );
    is( $video_creative->width, 'width', 'can get width' );

};



1;

