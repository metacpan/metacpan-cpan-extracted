package Yahoo::Marketing::APT::Test::FolderService;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997)

use strict; use warnings;

use base qw/ Yahoo::Marketing::APT::Test::PostTest /;
use Test::More;
use utf8;

use Yahoo::Marketing::APT::FolderService;
use Yahoo::Marketing::APT::Folder;
use Yahoo::Marketing::APT::FlashCreativeService;
use Yahoo::Marketing::APT::ImageCreativeService;
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


sub test_can_operate_folder : Test(21) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::APT::FolderService->new->parse_config( section => $self->section );
    my $flash_creative_ws = Yahoo::Marketing::APT::FlashCreativeService->new->parse_config( section => $self->section );
    my $image_creative_ws = Yahoo::Marketing::APT::ImageCreativeService->new->parse_config( section => $self->section );

    # test getRootFolder
    my $root_folder = $ysm_ws->getRootFolder( folderType => 'CreativeFolder' );
    ok( $root_folder, 'can call getRootFolder');
    is( $root_folder->type, 'CreativeFolder', 'folder type matches' );

    my $folder = Yahoo::Marketing::APT::Folder->new
                                              ->name( "my test folder" )
                                              ->parentFolderID( $root_folder->ID )
                                                  ;
    # test addFolder
    my $response = $ysm_ws->addFolder( folder => $folder );
    ok( $response, 'can call addFolder' );
    is( $response->operationResult, 'Success', 'add folder successfully' );
    $folder = $response->folder;

    # test getFolder
    $folder = $ysm_ws->getFolder( folderID => $folder->ID );
    ok( $folder, 'can call getFolder' );
    is( $folder->name, 'my test folder', 'name matches' );

    # test updateFolder
    $folder->name( 'my new folder' );
    $response = $ysm_ws->updateFolder( folder => $folder );
    ok( $response, 'can call updateFolder' );
    is( $response->operationResult, 'Success', 'update folder successfully' );
    $folder = $response->folder;

    # test copyFolder
    $response = $ysm_ws->copyFolder( folderID => $folder->ID, destinationParentFolderID => $root_folder->ID );
    ok( $response, 'can call copyFolder' );
    is( $response->operationResult, 'Success', 'copy folder successfully' );
    my $copied_folder = $response->folder;

    # test moveFolder
    $response = $ysm_ws->moveFolder( folderID => $copied_folder->ID, destinationParentFolderID => $folder->ID );
    ok( $response, 'can call moveFolder' );
    is( $response->operationSucceeded, 'true', 'move folder successfully' );

    my $zipped_creative = './t/libdata/creative.zip';
    open(FILE, $zipped_creative) or die "$@";
    my $buf; my $base64;
    while (read(FILE, $buf, 60*57)) {
        $base64 .= encode_base64($buf);
    }
    # test addZippedCreatives
    $response = $ysm_ws->addZippedCreatives( folderID => $folder->ID, binaryData => $base64 );
    ok( $response, 'can call addZippedCreative' );
    is( $response->operationResult, 'Success', 'copy folder successfully' );
    my $flash_creatives = $response->flashCreatives;
    my $image_creatives = $response->imageCreatives;
    is( scalar @$flash_creatives, 1, 'flash creatives added' );
    is( scalar @$image_creatives, 1, 'image creatives added' );

    # test getFolderItemsByFolderID
    my @items = $ysm_ws->getFolderItemsByFolderID( folderID => $folder->ID );
    ok( @items, 'can get folder items by folder id' );

    # test moveFolderContents
    $response = $ysm_ws->moveFolderContents( folderID => $folder->ID, destinationParentFolderID => $copied_folder->ID );
    ok( $response, 'can call moveFolderContents' );
    is( $response->operationSucceeded, 'true', 'move folder contents successfully' );

    # clean up
    $flash_creative_ws->deleteFlashCreative( flashCreativeID => $flash_creatives->[0]->ID );
    $image_creative_ws->deleteImageCreative( imageCreativeID => $image_creatives->[0]->ID );

    # test deleteFolder
    $response = $ysm_ws->deleteFolder( folderID => $copied_folder->ID );
    ok( $response, 'can call deleteFolder' );
    is( $response->operationSucceeded, 'true', 'delete folder successfully' );

    $ysm_ws->deleteFolder( folderID => $folder->ID );
}


sub test_can_operate_folders : Test(13) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::APT::FolderService->new->parse_config( section => $self->section );

    # test getRootFolder
    my $root_folder = $ysm_ws->getRootFolder( folderType => 'CreativeFolder' );
    ok( $root_folder, 'can call getRootFolder');
    is( $root_folder->type, 'CreativeFolder', 'folder type matches' );

    my $folder1 = Yahoo::Marketing::APT::Folder->new
                                               ->name( "my test folder1" )
                                               ->parentFolderID( $root_folder->ID )
                                                  ;
    my $folder2 = Yahoo::Marketing::APT::Folder->new
                                               ->name( "my test folder2" )
                                               ->parentFolderID( $root_folder->ID )
                                                  ;

    # test addFolders
    my @responses = $ysm_ws->addFolders( folders => [$folder1, $folder2] );
    ok( @responses, 'can call addFolders' );
    is( $responses[0]->operationResult, 'Success', 'add folders successfully' );
    $folder1 = $responses[0]->folder;
    $folder2 = $responses[1]->folder;

    # test getFolders
    my @folders = $ysm_ws->getFolders( folderIDs => [ map {$_->ID} ($folder1, $folder2) ] );
    ok( @folders, 'can call getFolders' );
    like( $folders[0]->name, qr/my test folder/, 'name matches' );

    # test getFoldersByParentID
    @folders = $ysm_ws->getFoldersByParentID( parentFolderID => $root_folder->ID );
    ok( @folders, 'can call getFoldersByParentID' );
    my $found;
    foreach (@folders) {
        $found = 1 if $_->name =~ /my test folder/;
    }
    is( $found, 1, 'find target folder' );

    # test updateFolders
    $folder1->name( 'my new folder1' );
    $folder2->name( 'my new folder2' );
    @responses = $ysm_ws->updateFolders( folders => [$folder1, $folder2] );
    ok( @responses, 'can call updateFolders' );
    is( $responses[0]->operationResult, 'Success', 'update folder successfully' );
    $folder1 = $responses[0]->folder;
    $folder2 = $responses[1]->folder;
    like( $folder1->name, qr/my new folder/, 'name matches' );

    # test deleteFolders
    @responses = $ysm_ws->deleteFolders( folderIDs => [ $folder1->ID, $folder2->ID ] );
    ok( @responses, 'can call deleteFolders' );
    is( $responses[0]->operationSucceeded, 'true', 'delete folders successfully' );

}



1;
