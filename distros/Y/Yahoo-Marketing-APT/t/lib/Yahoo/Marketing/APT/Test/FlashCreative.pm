package Yahoo::Marketing::APT::Test::FlashCreative;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::FlashCreative;

sub test_can_create_flash_creative_and_set_all_fields : Test(23) {

    my $flash_creative = Yahoo::Marketing::APT::FlashCreative->new
                                                        ->ID( 'id' )
                                                        ->accountID( 'account id' )
                                                        ->actionScriptVersion( 'action script version' )
                                                        ->binaryData( 'binary data' )
                                                        ->createTimestamp( '2009-01-06T17:51:55' )
                                                        ->fileExtension( 'file extension' )
                                                        ->flashVersion( 'flash version' )
                                                        ->folderID( 'folder id' )
                                                        ->frameCount( 'frame count' )
                                                        ->frameRate( 'frame rate' )
                                                        ->hasAudio( 'has audio' )
                                                        ->hasVideo( 'has video' )
                                                        ->height( 'height' )
                                                        ->lastUpdateTimestamp( '2009-01-07T17:51:55' )
                                                        ->name( 'name' )
                                                        ->secureURL( 'secure url' )
                                                        ->status( 'status' )
                                                        ->type( 'type' )
                                                        ->url( 'url' )
                                                        ->urlPath( 'url path' )
                                                        ->weight( 'weight' )
                                                        ->width( 'width' )
                   ;

    ok( $flash_creative );

    is( $flash_creative->ID, 'id', 'can get id' );
    is( $flash_creative->accountID, 'account id', 'can get account id' );
    is( $flash_creative->actionScriptVersion, 'action script version', 'can get action script version' );
    is( $flash_creative->binaryData, 'binary data', 'can get binary data' );
    is( $flash_creative->createTimestamp, '2009-01-06T17:51:55', 'can get 2009-01-06T17:51:55' );
    is( $flash_creative->fileExtension, 'file extension', 'can get file extension' );
    is( $flash_creative->flashVersion, 'flash version', 'can get flash version' );
    is( $flash_creative->folderID, 'folder id', 'can get folder id' );
    is( $flash_creative->frameCount, 'frame count', 'can get frame count' );
    is( $flash_creative->frameRate, 'frame rate', 'can get frame rate' );
    is( $flash_creative->hasAudio, 'has audio', 'can get has audio' );
    is( $flash_creative->hasVideo, 'has video', 'can get has video' );
    is( $flash_creative->height, 'height', 'can get height' );
    is( $flash_creative->lastUpdateTimestamp, '2009-01-07T17:51:55', 'can get 2009-01-07T17:51:55' );
    is( $flash_creative->name, 'name', 'can get name' );
    is( $flash_creative->secureURL, 'secure url', 'can get secure url' );
    is( $flash_creative->status, 'status', 'can get status' );
    is( $flash_creative->type, 'type', 'can get type' );
    is( $flash_creative->url, 'url', 'can get url' );
    is( $flash_creative->urlPath, 'url path', 'can get url path' );
    is( $flash_creative->weight, 'weight', 'can get weight' );
    is( $flash_creative->width, 'width', 'can get width' );

};



1;

