package Yahoo::Marketing::APT::Test::FlashCreativeService;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997)

use strict; use warnings;

use base qw/ Yahoo::Marketing::APT::Test::PostTest /;
use Test::More;
use utf8;

use Yahoo::Marketing::APT::FlashCreativeService;
use Yahoo::Marketing::APT::FlashCreative;

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


sub test_can_operate_flash_creative : Test(16) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::APT::FlashCreativeService->new->parse_config( section => $self->section );

    my $flash_file = 't/libdata/test_flsh_crtv.swf';
    open(FILE, $flash_file) or die "$@";
    my $buf; my $base64;
    while (read(FILE, $buf, 60*57)) {
        $base64 .= encode_base64($buf);
    }

    my $flash_creative = Yahoo::Marketing::APT::FlashCreative->new
                                                             ->binaryData($base64)
                                                             ->name( 'test flash creative' )
                                                                 ;
    # test addFlashCreative
    my $response = $ysm_ws->addFlashCreative( flashCreative => $flash_creative );
    ok( $response, 'can call addFlashCreative' );
    is( $response->operationSucceeded, 'true' );
    $flash_creative = $response->flashCreative;
    is( $flash_creative->name, 'test flash creative', 'name matches' );

    # test getFlashCreative
    $flash_creative = $ysm_ws->getFlashCreative( flashCreativeID => $flash_creative->ID );
    ok( $flash_creative, 'can call getFlashCreative' );
    is( $flash_creative->name, 'test flash creative', 'name matches' );

    # test updateFlashCreative
    $flash_creative->name( 'new flash creative' );
    $response = $ysm_ws->updateFlashCreative( flashCreative => $flash_creative );
    ok( $response, 'can call updateFlashCreative' );
    is( $response->operationSucceeded, 'true' );
    $flash_creative = $response->flashCreative;
    is( $flash_creative->name, 'new flash creative', 'name matches' );

    # test copyFlashCreative
    $response = $ysm_ws->copyFlashCreative( flashCreativeID => $flash_creative->ID, destinationFolderID => $self->common_test_data( 'test_creative_folder' )->ID );
    ok( $response, 'can call copyFlashCreative' );
    is( $response->operationSucceeded, 'true', 'copy flash creative successfully' );
    my $copied_flash_creative = $response->flashCreative;
    is( $copied_flash_creative->folderID, $self->common_test_data( 'test_creative_folder' )->ID, 'folder id matches' );

    # test deleteFlashCreative
    $response = $ysm_ws->deleteFlashCreative( flashCreativeID => $copied_flash_creative->ID );
    ok( $response, 'can delete flash creative' );
    is( $response->operationSucceeded, 'true', 'delete flash creative successfully' );

    # test moveFlashCreative
    $response = $ysm_ws->moveFlashCreative( flashCreativeID => $flash_creative->ID, destinationFolderID => $self->common_test_data( 'test_creative_folder' )->ID );
    ok( $response, 'can call moveFlashCreative' );
    is( $response->operationSucceeded, 'true', 'move flash creative successfully' );
    my $moved_flash_creative = $response->flashCreative;
    is( $moved_flash_creative->folderID, $self->common_test_data( 'test_creative_folder' )->ID, 'folder id matches' );

    # clean up
    $ysm_ws->deleteFlashCreative( flashCreativeID => $moved_flash_creative->ID );

}


sub test_can_operate_flash_creatives : Test(21) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::APT::FlashCreativeService->new->parse_config( section => $self->section );

    my $flash_file = 't/libdata/test_flsh_crtv.swf';
    open(FILE, $flash_file) or die "$@";
    my $buf; my $base64;
    while (read(FILE, $buf, 60*57)) {
        $base64 .= encode_base64($buf);
    }

    my $flash_creative1 = Yahoo::Marketing::APT::FlashCreative->new
                                                              ->binaryData($base64)
                                                              ->name( 'test flash creative 1' )
                                                                 ;
    my $flash_creative2 = Yahoo::Marketing::APT::FlashCreative->new
                                                              ->binaryData($base64)
                                                              ->name( 'test flash creative 2' )
                                                                 ;
    # test addFlashCreatives
    my @responses = $ysm_ws->addFlashCreatives( flashCreatives => [$flash_creative1, $flash_creative2] );
    ok( @responses, 'can call addFlashCreatives' );
    is( $responses[0]->operationSucceeded, 'true' );
    $flash_creative1 = $responses[0]->flashCreative;
    $flash_creative2 = $responses[1]->flashCreative;
    like( $flash_creative1->name, qr/test flash creative/, 'name matches' );

    # test getFlashCreatives
    my @flash_creatives = $ysm_ws->getFlashCreatives( flashCreativeIDs => [$flash_creative1->ID, $flash_creative2->ID] );
    ok( @flash_creatives, 'can call getFlashCreatives' );
    like( $flash_creatives[0]->name, qr/test flash creative/, 'name matches' );

    # test updateFlashCreatives
    $flash_creative1->name( 'new flash creative 1' );
    $flash_creative2->name( 'new flash creative 2' );
    @responses = $ysm_ws->updateFlashCreatives( flashCreatives => [$flash_creative1, $flash_creative2] );
    ok( @responses, 'can call updateFlashCreatives' );
    is( $responses[0]->operationSucceeded, 'true' );
    $flash_creative1 = $responses[0]->flashCreative;
    $flash_creative2 = $responses[1]->flashCreative;
    like( $flash_creative1->name, qr/new flash creative/, 'name matches' );

    # test copyFlashCreatives
    @responses = $ysm_ws->copyFlashCreatives( flashCreativeIDs => [$flash_creative1->ID, $flash_creative2->ID], destinationFolderID => $self->common_test_data( 'test_creative_folder' )->ID );
    ok( @responses, 'can call copyFlashCreatives' );
    is( $responses[0]->operationSucceeded, 'true', 'copy flash creatives successfully' );
    my $copied_flash_creative1 = $responses[0]->flashCreative;
    my $copied_flash_creative2 = $responses[1]->flashCreative;
    is( $copied_flash_creative1->folderID, $self->common_test_data( 'test_creative_folder' )->ID, 'folder id matches' );

    # test deleteFlashCreatives
    @responses = $ysm_ws->deleteFlashCreatives( flashCreativeIDs => [$copied_flash_creative1->ID, $copied_flash_creative2->ID] );
    ok( @responses, 'can delete flash creatives' );
    is( $responses[0]->operationSucceeded, 'true', 'delete flash creatives successfully' );

    # test moveFlashCreative
    @responses = $ysm_ws->moveFlashCreatives( flashCreativeIDs => [$flash_creative1->ID, $flash_creative2->ID], destinationFolderID => $self->common_test_data( 'test_creative_folder' )->ID );
    ok( @responses, 'can call moveFlashCreatives' );
    is( $responses[0]->operationSucceeded, 'true', 'move flash creatives successfully' );
    my $moved_flash_creative1 = $responses[0]->flashCreative;
    my $moved_flash_creative2 = $responses[1]->flashCreative;
    is( $moved_flash_creative1->folderID, $self->common_test_data( 'test_creative_folder' )->ID, 'folder id matches' );

    # test getFlashCreativeCountByAccountID
    my $count = $ysm_ws->getFlashCreativeCountByAccountID();
    ok( $count, 'can call getFlashCreativeCountByAccountID' );

    # test getFlashCreativesByAccountID
    @flash_creatives = $ysm_ws->getFlashCreativesByAccountID( startElement => 0, numElements => 1000 );
    ok( @flash_creatives, 'can call getFlashCreativesByAccountID' );
    my $found;
    foreach ( @flash_creatives ) {
        ++$found and last if $_->name =~ /new flash creative/;
    }
    is( $found, 1, 'can find target flash creatives' );

    # test getFlashCreativesByFolderID
    @flash_creatives = $ysm_ws->getFlashCreativesByFolderID( folderID => $self->common_test_data( 'test_creative_folder' )->ID );
    ok( @flash_creatives, 'can call getFlashCreativesByFolderID' );
    $found = 0;
    foreach ( @flash_creatives ) {
        ++$found and last if $_->name =~ /new flash creative/;
    }
    is( $found, 1, 'can find target flash creatives' );

    # clean up
    $ysm_ws->deleteFlashCreatives( flashCreativeIDs => [$moved_flash_creative1->ID, $moved_flash_creative2->ID] );

}



1;


