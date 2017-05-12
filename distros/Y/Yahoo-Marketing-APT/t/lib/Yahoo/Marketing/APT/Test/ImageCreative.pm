package Yahoo::Marketing::APT::Test::ImageCreative;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::ImageCreative;

sub test_can_create_image_creative_and_set_all_fields : Test(17) {

    my $image_creative = Yahoo::Marketing::APT::ImageCreative->new
                                                        ->ID( 'id' )
                                                        ->accountID( 'account id' )
                                                        ->binaryData( 'binary data' )
                                                        ->createTimestamp( '2009-01-06T17:51:55' )
                                                        ->fileExtension( 'file extension' )
                                                        ->folderID( 'folder id' )
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

    ok( $image_creative );

    is( $image_creative->ID, 'id', 'can get id' );
    is( $image_creative->accountID, 'account id', 'can get account id' );
    is( $image_creative->binaryData, 'binary data', 'can get binary data' );
    is( $image_creative->createTimestamp, '2009-01-06T17:51:55', 'can get 2009-01-06T17:51:55' );
    is( $image_creative->fileExtension, 'file extension', 'can get file extension' );
    is( $image_creative->folderID, 'folder id', 'can get folder id' );
    is( $image_creative->height, 'height', 'can get height' );
    is( $image_creative->lastUpdateTimestamp, '2009-01-07T17:51:55', 'can get 2009-01-07T17:51:55' );
    is( $image_creative->name, 'name', 'can get name' );
    is( $image_creative->secureURL, 'secure url', 'can get secure url' );
    is( $image_creative->status, 'status', 'can get status' );
    is( $image_creative->type, 'type', 'can get type' );
    is( $image_creative->url, 'url', 'can get url' );
    is( $image_creative->urlPath, 'url path', 'can get url path' );
    is( $image_creative->weight, 'weight', 'can get weight' );
    is( $image_creative->width, 'width', 'can get width' );

};



1;

