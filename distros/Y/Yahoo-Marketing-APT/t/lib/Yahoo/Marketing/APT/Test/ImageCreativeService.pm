package Yahoo::Marketing::APT::Test::ImageCreativeService;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997)

use strict; use warnings;

use base qw/ Yahoo::Marketing::APT::Test::PostTest /;
use Test::More;
use utf8;

use Yahoo::Marketing::APT::ImageCreativeService;
use Yahoo::Marketing::APT::ImageCreative;

use MIME::Base64 qw(encode_base64);
use Data::Dumper;

# use SOAP::Lite +trace => [qw/ debug method fault /];


sub SKIP_CLASS {
    my $self = shift;
    # 'not running post tests' is a true value
    return 'not running post tests' unless $self->run_post_tests;
    return;
}

sub section {
    my ( $self ) = @_;
    return $self->SUPER::section().'_managed_advertiser';
}

sub startup_test_creative_folder_service : Test(startup) {
    my ( $self ) = @_;

    $self->common_test_data( 'test_creative_folder', $self->create_folder( type => 'CreativeFolder') ) unless defined $self->common_test_data( 'test_creative_folder' );
}

sub shutdown_test_creative_folder_service : Test(shutdown) {
    my ( $self ) = @_;

    $self->cleanup_creative_folder;
}


sub test_can_operate_image_creative : Test(16) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::APT::ImageCreativeService->new->parse_config( section => $self->section );

    my $image_file = 't/libdata/test_img_crtv.gif';
    open(FILE, $image_file) or die "$@";
    my $buf; my $base64;
    while (read(FILE, $buf, 60*57)) {
        $base64 .= encode_base64($buf);
    }

    my $image_creative = Yahoo::Marketing::APT::ImageCreative->new
                                                             ->binaryData($base64)
                                                             ->name( 'test image creative' )
                                                                 ;
    # test addImageCreative
    my $response = $ysm_ws->addImageCreative( imageCreative => $image_creative );
    ok( $response, 'can call addImageCreative' );
    is( $response->operationSucceeded, 'true' );
    $image_creative = $response->imageCreative;
    is( $image_creative->name, 'test image creative', 'name matches' );

    # test getImageCreative
    $image_creative = $ysm_ws->getImageCreative( imageCreativeID => $image_creative->ID );
    ok( $image_creative, 'can call getImageCreative' );
    is( $image_creative->name, 'test image creative', 'name matches' );

    # test updateImageCreative
    $image_creative->name( 'new image creative' );
    $response = $ysm_ws->updateImageCreative( imageCreative => $image_creative );
    ok( $response, 'can call updateImageCreative' );
    is( $response->operationSucceeded, 'true' );
    $image_creative = $response->imageCreative;
    is( $image_creative->name, 'new image creative', 'name matches' );

    # test copyImageCreative
    $response = $ysm_ws->copyImageCreative( imageCreativeID => $image_creative->ID, destinationFolderID => $self->common_test_data( 'test_creative_folder' )->ID );
    ok( $response, 'can call copyImageCreative' );
    is( $response->operationSucceeded, 'true', 'copy image creative successfully' );
    my $copied_image_creative = $response->imageCreative;
    is( $copied_image_creative->folderID, $self->common_test_data( 'test_creative_folder' )->ID, 'folder id matches' );

    # test deleteImageCreative
    $response = $ysm_ws->deleteImageCreative( imageCreativeID => $copied_image_creative->ID );
    ok( $response, 'can delete image creative' );
    is( $response->operationSucceeded, 'true', 'delete image creative successfully' );

    # test moveImageCreative
    $response = $ysm_ws->moveImageCreative( imageCreativeID => $image_creative->ID, destinationFolderID => $self->common_test_data( 'test_creative_folder' )->ID );
    ok( $response, 'can call moveImageCreative' );
    is( $response->operationSucceeded, 'true', 'move image creative successfully' );
    my $moved_image_creative = $response->imageCreative;
    is( $moved_image_creative->folderID, $self->common_test_data( 'test_creative_folder' )->ID, 'folder id matches' );

    # clean up
    $ysm_ws->deleteImageCreative( imageCreativeID => $moved_image_creative->ID );

}


sub test_can_operate_image_creatives : Test(21) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::APT::ImageCreativeService->new->parse_config( section => $self->section );

    my $image_file = 't/libdata/test_img_crtv.gif';
    open(FILE, $image_file) or die "$@";
    my $buf; my $base64;
    while (read(FILE, $buf, 60*57)) {
        $base64 .= encode_base64($buf);
    }

    my $image_creative1 = Yahoo::Marketing::APT::ImageCreative->new
                                                              ->binaryData($base64)
                                                              ->name( 'test image creative 1' )
                                                                 ;
    my $image_creative2 = Yahoo::Marketing::APT::ImageCreative->new
                                                              ->binaryData($base64)
                                                              ->name( 'test image creative 2' )
                                                                 ;
    # test addImageCreatives
    my @responses = $ysm_ws->addImageCreatives( imageCreatives => [$image_creative1, $image_creative2] );
    ok( @responses, 'can call addImageCreatives' );
    is( $responses[0]->operationSucceeded, 'true' );
    $image_creative1 = $responses[0]->imageCreative;
    $image_creative2 = $responses[1]->imageCreative;
    like( $image_creative1->name, qr/test image creative/, 'name matches' );

    # test getImageCreatives
    my @image_creatives = $ysm_ws->getImageCreatives( imageCreativeIDs => [$image_creative1->ID, $image_creative2->ID] );
    ok( @image_creatives, 'can call getImageCreatives' );
    like( $image_creatives[0]->name, qr/test image creative/, 'name matches' );

    # test updateImageCreatives
    $image_creative1->name( 'new image creative 1' );
    $image_creative2->name( 'new image creative 2' );
    @responses = $ysm_ws->updateImageCreatives( imageCreatives => [$image_creative1, $image_creative2] );
    ok( @responses, 'can call updateImageCreatives' );
    is( $responses[0]->operationSucceeded, 'true' );
    $image_creative1 = $responses[0]->imageCreative;
    $image_creative2 = $responses[1]->imageCreative;
    like( $image_creative1->name, qr/new image creative/, 'name matches' );

    # test copyImageCreatives
    @responses = $ysm_ws->copyImageCreatives( imageCreativeIDs => [$image_creative1->ID, $image_creative2->ID], destinationFolderID => $self->common_test_data( 'test_creative_folder' )->ID );
    ok( @responses, 'can call copyImageCreatives' );
    is( $responses[0]->operationSucceeded, 'true', 'copy image creatives successfully' );
    my $copied_image_creative1 = $responses[0]->imageCreative;
    my $copied_image_creative2 = $responses[1]->imageCreative;
    is( $copied_image_creative1->folderID, $self->common_test_data( 'test_creative_folder' )->ID, 'folder id matches' );

    # test deleteImageCreatives
    @responses = $ysm_ws->deleteImageCreatives( imageCreativeIDs => [$copied_image_creative1->ID, $copied_image_creative2->ID] );
    ok( @responses, 'can delete image creatives' );
    is( $responses[0]->operationSucceeded, 'true', 'delete image creatives successfully' );

    # test moveImageCreative
    @responses = $ysm_ws->moveImageCreatives( imageCreativeIDs => [$image_creative1->ID, $image_creative2->ID], destinationFolderID => $self->common_test_data( 'test_creative_folder' )->ID );
    ok( @responses, 'can call moveImageCreatives' );
    is( $responses[0]->operationSucceeded, 'true', 'move image creatives successfully' );
    my $moved_image_creative1 = $responses[0]->imageCreative;
    my $moved_image_creative2 = $responses[1]->imageCreative;
    is( $moved_image_creative1->folderID, $self->common_test_data( 'test_creative_folder' )->ID, 'folder id matches' );

    # test getImageCreativeCountByAccountID
    my $count = $ysm_ws->getImageCreativeCountByAccountID();
    ok( $count, 'can call getImageCreativeCountByAccountID' );

    # test getImageCreativesByAccountID
    @image_creatives = $ysm_ws->getImageCreativesByAccountID( startElement => 0, numElements => 1000 );
    ok( @image_creatives, 'can call getImageCreativesByAccountID' );
    my $found;
    foreach ( @image_creatives ) {
        ++$found and last if $_->name =~ /new image creative/;
    }
    is( $found, 1, 'can find target image creatives' );

    # test getImageCreativesByFolderID
    @image_creatives = $ysm_ws->getImageCreativesByFolderID( folderID => $self->common_test_data( 'test_creative_folder' )->ID );
    ok( @image_creatives, 'can call getImageCreativesByFolderID' );
    $found = 0;
    foreach ( @image_creatives ) {
        ++$found and last if $_->name =~ /new image creative/;
    }
    is( $found, 1, 'can find target image creatives' );

    # clean up
    $ysm_ws->deleteImageCreatives( imageCreativeIDs => [$moved_image_creative1->ID, $moved_image_creative2->ID] );

}



1;


