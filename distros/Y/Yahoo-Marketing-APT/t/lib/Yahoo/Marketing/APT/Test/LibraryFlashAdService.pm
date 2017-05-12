package Yahoo::Marketing::APT::Test::LibraryFlashAdService;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997)

use strict; use warnings;

use base qw/ Yahoo::Marketing::APT::Test::PostTest /;
use Test::More;
use utf8;

use Yahoo::Marketing::APT::LibraryFlashAdService;
use Yahoo::Marketing::APT::FlashCreativeService;
use Yahoo::Marketing::APT::ImageCreativeService;
use Yahoo::Marketing::APT::LibraryFlashAd;
use Yahoo::Marketing::APT::FlashCreative;
use Yahoo::Marketing::APT::ImageCreative;
use Yahoo::Marketing::APT::CompositeURL;
use Yahoo::Marketing::APT::Url;
use Yahoo::Marketing::APT::AlternateImage;

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


sub startup_test_folder_service : Test(startup) {
    my ( $self ) = @_;

    $self->common_test_data( 'test_ad_folder', $self->create_folder( type => 'AdFolder' ) ) unless defined $self->common_test_data( 'test_ad_folder' );

    # add a flash creative for ad testing
    my $ysm_ws = Yahoo::Marketing::APT::FlashCreativeService->new->parse_config( section => $self->section );

    my $flash_file = 't/libdata/test_flsh_crtv.swf';
    open(FILE, $flash_file) or die "$@";
    my $buf; my $base64;
    while (read(FILE, $buf, 60*57)) {
        $base64 .= encode_base64($buf);
    }

    my $flash_creative = Yahoo::Marketing::APT::FlashCreative->new
                                                             ->binaryData($base64)
                                                             ->name( "test flash creative $$" )
                                                                 ;
    my $response = $ysm_ws->addFlashCreative( flashCreative => $flash_creative );
    if ( $response->operationSucceeded ne 'true' ) {
        die "addFlashCreative failed";
    }
    $self->common_test_data('test_flash_creative', $response->flashCreative);

    # add an image creative for ad testing
    $ysm_ws = Yahoo::Marketing::APT::ImageCreativeService->new->parse_config( section => $self->section );

    my $image_file = 't/libdata/test_img_crtv.gif';
    open(FILE, $image_file) or die "$@";
    $buf = undef; $base64 = undef;
    while (read(FILE, $buf, 60*57)) {
        $base64 .= encode_base64($buf);
    }

    my $image_creative = Yahoo::Marketing::APT::ImageCreative->new
                                                             ->binaryData($base64)
                                                             ->name( "test image creative $$" )
                                                                 ;
    # test addImageCreative
    $response = $ysm_ws->addImageCreative( imageCreative => $image_creative );
    if ( $response->operationSucceeded ne 'true' ) {
        die "addImageCreative failed";
    }
    $self->common_test_data('test_image_creative', $response->imageCreative);

}

sub shutdown_test_folder_service : Test(shutdown) {
    my ( $self ) = @_;

    my $ysm_ws = Yahoo::Marketing::APT::FlashCreativeService->new->parse_config( section => $self->section );
    $ysm_ws->deleteFlashCreative( flashCreativeID => $self->common_test_data('test_flash_creative')->ID );

    $ysm_ws = Yahoo::Marketing::APT::ImageCreativeService->new->parse_config( section => $self->section );
    $ysm_ws->deleteImageCreative( imageCreativeID => $self->common_test_data('test_image_creative')->ID );

    $self->cleanup_ad_folder;
}


sub test_can_operate_library_flash_ad : Test(10) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::APT::LibraryFlashAdService->new->parse_config( section => $self->section );
    my $url = Yahoo::Marketing::APT::Url->new
                                        ->url( 'http://www.publisherwebsite.com/destication.html' );
    my $composite_url = Yahoo::Marketing::APT::CompositeURL->new
                                                           ->clickThroughURL( $url );
    my $alternate_image = Yahoo::Marketing::APT::AlternateImage->new
                                                               ->compositeClickThroughURL( $composite_url )
                                                               ->imageCreativeID( $self->common_test_data('test_image_creative')->ID );
    my $library_flash_ad = Yahoo::Marketing::APT::LibraryFlashAd->new
                                                                ->alternateImage( $alternate_image )
                                                                ->compositeClickThroughURLs( [$composite_url] )
                                                                ->flashCreativeID( $self->common_test_data('test_flash_creative')->ID )
                                                                ->name( 'test flash ad' )
                                                                ->windowTarget( 'NewWindow' )
                                                                    ;
    # test addLibraryFlashAd
    my $response = $ysm_ws->addLibraryFlashAd( libraryFlashAd => $library_flash_ad );
    ok( $response, 'can call addLibraryFlashAd' );
    is( $response->operationSucceeded, 'true', 'add library flash ad successfully' );
    $library_flash_ad = $response->libraryFlashAd;
    is( $library_flash_ad->name, 'test flash ad', 'name matches' );

    # test getLibraryFlashAd
    $library_flash_ad = $ysm_ws->getLibraryFlashAd( libraryFlashAdID => $library_flash_ad->ID );
    ok( $library_flash_ad, 'can call getLibraryFlashAd' );
    is( $library_flash_ad->name, 'test flash ad', 'name matches' );

    # test updateLibraryFlashAd
    $library_flash_ad->name( 'new flash ad' );
    $response = $ysm_ws->updateLibraryFlashAd( libraryFlashAd => $library_flash_ad );
    ok( $response, 'can call updateLibraryFlashAd' );
    is( $response->operationSucceeded, 'true', 'update library flash ad successfully' );
    $library_flash_ad = $response->libraryFlashAd;
    is( $library_flash_ad->name, 'new flash ad', 'name matches' );

    # test deleteLibraryFlashAd
    $response = $ysm_ws->deleteLibraryFlashAd( libraryFlashAdID => $library_flash_ad->ID );
    ok( $response, 'can call deleteLibraryFlashAd' );
    is( $response->operationSucceeded, 'true', 'delete library flash ad successfully' );
}

sub test_can_operate_library_flash_ads : Test(16) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::APT::LibraryFlashAdService->new->parse_config( section => $self->section );
    my $url = Yahoo::Marketing::APT::Url->new
                                        ->url( 'http://www.publisherwebsite.com/destication.html' );
    my $composite_url = Yahoo::Marketing::APT::CompositeURL->new
                                                           ->clickThroughURL( $url );
    my $alternate_image = Yahoo::Marketing::APT::AlternateImage->new
                                                               ->compositeClickThroughURL( $composite_url )
                                                               ->imageCreativeID( $self->common_test_data('test_image_creative')->ID );
    my $library_flash_ad = Yahoo::Marketing::APT::LibraryFlashAd->new
                                                                ->alternateImage( $alternate_image )
                                                                ->compositeClickThroughURLs( [$composite_url] )
                                                                ->flashCreativeID( $self->common_test_data('test_flash_creative')->ID )
                                                                ->name( 'test flash ad' )
                                                                ->windowTarget( 'NewWindow' )
                                                                    ;
    # test addLibraryFlashAds
    my @responses = $ysm_ws->addLibraryFlashAds( libraryFlashAds => [$library_flash_ad] );
    ok( @responses, 'can call addLibraryFlashAds' );
    is( $responses[0]->operationSucceeded, 'true', 'add library flash ads successfully' );
    $library_flash_ad = $responses[0]->libraryFlashAd;
    is( $library_flash_ad->name, 'test flash ad', 'name matches' );

    # test getLibraryFlashAds
    my @library_flash_ads = $ysm_ws->getLibraryFlashAds( libraryFlashAdIDs => [$library_flash_ad->ID] );
    ok( @library_flash_ads, 'can call getLibraryFlashAds' );
    is( $library_flash_ads[0]->name, 'test flash ad', 'name matches' );

    # test updateLibraryFlashAd
    $library_flash_ad->name( 'new flash ad' );
    @responses = $ysm_ws->updateLibraryFlashAds( libraryFlashAds => [$library_flash_ad] );
    ok( @responses, 'can call updateLibraryFlashAds' );
    is( $responses[0]->operationSucceeded, 'true', 'update library flash ads successfully' );
    $library_flash_ad = $responses[0]->libraryFlashAd;
    is( $library_flash_ad->name, 'new flash ad', 'name matches' );

    # test getLibraryFlashAdCountByAccountID
    my $count = $ysm_ws->getLibraryFlashAdCountByAccountID();
    ok( $count, 'can call getLibraryFlashAdCountByAccountID' );
    like( $count, qr/\d+/, 'can get library flash ad count by account id successfully' );

    # test getLibraryFlashAdsByAccountID
    @library_flash_ads = $ysm_ws->getLibraryFlashAdsByAccountID(startElement => 0, numElements => 1000 );
    ok( @library_flash_ads, 'can call getLibraryFlashAdsByAccountID' );
    my $found = 0;
    foreach ( @library_flash_ads ) {
        ++$found and last if $_->ID eq $library_flash_ad->ID;
    }
    is( $found, 1, 'can get library flash ads by account id' );

    # test getLibraryFlashAdsByFolderID
     @library_flash_ads = $ysm_ws->getLibraryFlashAdsByFolderID( folderID => $library_flash_ad->folderID );
    ok( @library_flash_ads, 'can call getLibraryFlashAdsByFolderID' );
    $found = 0;
    foreach ( @library_flash_ads ) {
        ++$found and last if $_->ID eq $library_flash_ad->ID;
    }
    is( $found, 1, 'can get library flash ads by account id' );

    # test deleteLibraryFlashAds
    @responses = $ysm_ws->deleteLibraryFlashAds( libraryFlashAdIDs => [$library_flash_ad->ID] );
    ok( @responses, 'can call deleteLibraryFlashAds' );
    is( $responses[0]->operationSucceeded, 'true', 'delete library flash ads successfully' );
}

1;
