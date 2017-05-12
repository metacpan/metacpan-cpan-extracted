package Yahoo::Marketing::APT::Test::CustomizableFlashCreative;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::CustomizableFlashCreative;

sub test_can_create_customizable_flash_creative_and_set_all_fields : Test(26) {

    my $customizable_flash_creative = Yahoo::Marketing::APT::CustomizableFlashCreative->new
                                                                                 ->ID( 'id' )
                                                                                 ->accountID( 'account id' )
                                                                                 ->actionScriptVersion( 'action script version' )
                                                                                 ->binaryData( 'binary data' )
                                                                                 ->createTimestamp( '2009-01-06T17:51:55' )
                                                                                 ->fileExtension( 'file extension' )
                                                                                 ->flashCreativeID( 'flash creative id' )
                                                                                 ->flashVersion( 'flash version' )
                                                                                 ->folderID( 'folder id' )
                                                                                 ->frameCount( 'frame count' )
                                                                                 ->frameRate( 'frame rate' )
                                                                                 ->hasAudio( 'has audio' )
                                                                                 ->hasVideo( 'has video' )
                                                                                 ->height( 'height' )
                                                                                 ->imageFlashVariables( 'image flash variables' )
                                                                                 ->lastUpdateTimestamp( '2009-01-07T17:51:55' )
                                                                                 ->name( 'name' )
                                                                                 ->secureURL( 'secure url' )
                                                                                 ->status( 'status' )
                                                                                 ->textFlashVariables( 'text flash variables' )
                                                                                 ->type( 'type' )
                                                                                 ->url( 'url' )
                                                                                 ->urlPath( 'url path' )
                                                                                 ->weight( 'weight' )
                                                                                 ->width( 'width' )
                   ;

    ok( $customizable_flash_creative );

    is( $customizable_flash_creative->ID, 'id', 'can get id' );
    is( $customizable_flash_creative->accountID, 'account id', 'can get account id' );
    is( $customizable_flash_creative->actionScriptVersion, 'action script version', 'can get action script version' );
    is( $customizable_flash_creative->binaryData, 'binary data', 'can get binary data' );
    is( $customizable_flash_creative->createTimestamp, '2009-01-06T17:51:55', 'can get 2009-01-06T17:51:55' );
    is( $customizable_flash_creative->fileExtension, 'file extension', 'can get file extension' );
    is( $customizable_flash_creative->flashCreativeID, 'flash creative id', 'can get flash creative id' );
    is( $customizable_flash_creative->flashVersion, 'flash version', 'can get flash version' );
    is( $customizable_flash_creative->folderID, 'folder id', 'can get folder id' );
    is( $customizable_flash_creative->frameCount, 'frame count', 'can get frame count' );
    is( $customizable_flash_creative->frameRate, 'frame rate', 'can get frame rate' );
    is( $customizable_flash_creative->hasAudio, 'has audio', 'can get has audio' );
    is( $customizable_flash_creative->hasVideo, 'has video', 'can get has video' );
    is( $customizable_flash_creative->height, 'height', 'can get height' );
    is( $customizable_flash_creative->imageFlashVariables, 'image flash variables', 'can get image flash variables' );
    is( $customizable_flash_creative->lastUpdateTimestamp, '2009-01-07T17:51:55', 'can get 2009-01-07T17:51:55' );
    is( $customizable_flash_creative->name, 'name', 'can get name' );
    is( $customizable_flash_creative->secureURL, 'secure url', 'can get secure url' );
    is( $customizable_flash_creative->status, 'status', 'can get status' );
    is( $customizable_flash_creative->textFlashVariables, 'text flash variables', 'can get text flash variables' );
    is( $customizable_flash_creative->type, 'type', 'can get type' );
    is( $customizable_flash_creative->url, 'url', 'can get url' );
    is( $customizable_flash_creative->urlPath, 'url path', 'can get url path' );
    is( $customizable_flash_creative->weight, 'weight', 'can get weight' );
    is( $customizable_flash_creative->width, 'width', 'can get width' );

};



1;

