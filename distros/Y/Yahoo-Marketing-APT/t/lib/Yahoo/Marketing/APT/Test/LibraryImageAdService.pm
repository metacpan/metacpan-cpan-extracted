package Yahoo::Marketing::APT::Test::LibraryImageAdService;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997)

use strict; use warnings;

use base qw/ Yahoo::Marketing::APT::Test::PostTest /;
use Test::More;
use utf8;

use Yahoo::Marketing::APT::LibraryImageAdService;
use Yahoo::Marketing::APT::ImageCreativeService;
use Yahoo::Marketing::APT::ImageCreative;
use Yahoo::Marketing::APT::CompositeURL;
use Yahoo::Marketing::APT::Url;
use Yahoo::Marketing::APT::LibraryImageAd;

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

    # add an image creative for ad testing
    my $ysm_ws = Yahoo::Marketing::APT::ImageCreativeService->new->parse_config( section => $self->section );

    my $image_file = 't/libdata/test_img_crtv.gif';
    open(FILE, $image_file) or die "$@";
    my $buf = undef; my $base64 = undef;
    while (read(FILE, $buf, 60*57)) {
        $base64 .= encode_base64($buf);
    }

    my $image_creative = Yahoo::Marketing::APT::ImageCreative->new
                                                             ->binaryData($base64)
                                                             ->name( "test image creative $$" )
                                                                 ;
    # test addImageCreative
    my $response = $ysm_ws->addImageCreative( imageCreative => $image_creative );
    if ( $response->operationSucceeded ne 'true' ) {
        die "addImageCreative failed";
    }
    $self->common_test_data('test_image_creative', $response->imageCreative);

}

sub shutdown_test_folder_service : Test(shutdown) {
    my ( $self ) = @_;

    my $ysm_ws = Yahoo::Marketing::APT::ImageCreativeService->new->parse_config( section => $self->section );
    $ysm_ws->deleteImageCreative( imageCreativeID => $self->common_test_data('test_image_creative')->ID );

    $self->cleanup_ad_folder;
}


sub test_can_operate_library_image_ad : Test(10) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::APT::LibraryImageAdService->new->parse_config( section => $self->section );
    my $url = Yahoo::Marketing::APT::Url->new
                                        ->url( 'http://www.publisherwebsite.com/destication.html' );
    my $composite_url = Yahoo::Marketing::APT::CompositeURL->new
                                                           ->clickThroughURL( $url );
    my $library_image_ad = Yahoo::Marketing::APT::LibraryImageAd->new
                                                                ->compositeClickThroughURL( $composite_url )
                                                                ->imageCreativeID( $self->common_test_data('test_image_creative')->ID )
                                                                ->name( 'test image ad' )
                                                                ->windowTarget( 'NewWindow' )
                                                                    ;
    # test addLibraryImageAd
    my $response = $ysm_ws->addLibraryImageAd( libraryImageAd => $library_image_ad );
    ok( $response, 'can call addLibraryImageAd' );
    is( $response->operationSucceeded, 'true', 'add library image ad successfully' );
    $library_image_ad = $response->libraryImageAd;
    is( $library_image_ad->name, 'test image ad', 'name matches' );

    # test getLibraryImageAd
    $library_image_ad = $ysm_ws->getLibraryImageAd( libraryImageAdID => $library_image_ad->ID );
    ok( $library_image_ad, 'can call getLibraryImageAd' );
    is( $library_image_ad->name, 'test image ad', 'name matches' );

    # test updateLibraryImageAd
    $library_image_ad->name( 'new image ad' );
    $response = $ysm_ws->updateLibraryImageAd( libraryImageAd => $library_image_ad );
    ok( $response, 'can call updateLibraryImageAd' );
    is( $response->operationSucceeded, 'true', 'update library image ad successfully' );
    $library_image_ad = $response->libraryImageAd;
    is( $library_image_ad->name, 'new image ad', 'name matches' );

    # test deleteLibraryImageAd
    $response = $ysm_ws->deleteLibraryImageAd( libraryImageAdID => $library_image_ad->ID );
    ok( $response, 'can call deleteLibraryImageAd' );
    is( $response->operationSucceeded, 'true', 'delete library image ad successfully' );
}


sub test_can_operate_library_image_ads : Test(16) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::APT::LibraryImageAdService->new->parse_config( section => $self->section );
    my $url = Yahoo::Marketing::APT::Url->new
                                        ->url( 'http://www.publisherwebsite.com/destication.html' );
    my $composite_url = Yahoo::Marketing::APT::CompositeURL->new
                                                           ->clickThroughURL( $url );
    my $library_image_ad = Yahoo::Marketing::APT::LibraryImageAd->new
                                                                ->compositeClickThroughURL( $composite_url )
                                                                ->imageCreativeID( $self->common_test_data('test_image_creative')->ID )
                                                                ->name( 'test image ad' )
                                                                ->windowTarget( 'NewWindow' )
                                                                    ;
    # test addLibraryImageAds
    my @responses = $ysm_ws->addLibraryImageAds( libraryImageAds => [$library_image_ad] );
    ok( @responses, 'can call addLibraryImageAds' );
    is( $responses[0]->operationSucceeded, 'true', 'add library image ads successfully' );
    $library_image_ad = $responses[0]->libraryImageAd;
    is( $library_image_ad->name, 'test image ad', 'name matches' );

    # test getLibraryImageAds
    my @library_image_ads = $ysm_ws->getLibraryImageAds( libraryImageAdIDs => [$library_image_ad->ID] );
    ok( @library_image_ads, 'can call getLibraryImageAds' );
    is( $library_image_ads[0]->name, 'test image ad', 'name matches' );

    # test updateLibraryImageAd
    $library_image_ad->name( 'new image ad' );
    @responses = $ysm_ws->updateLibraryImageAds( libraryImageAds => [$library_image_ad] );
    ok( @responses, 'can call updateLibraryImageAds' );
    is( $responses[0]->operationSucceeded, 'true', 'update library image ads successfully' );
    $library_image_ad = $responses[0]->libraryImageAd;
    is( $library_image_ad->name, 'new image ad', 'name matches' );

    # test getLibraryImageAdCountByAccountID
    my $count = $ysm_ws->getLibraryImageAdCountByAccountID();
    ok( $count, 'can call getLibraryImageAdCountByAccountID' );
    like( $count, qr/\d+/, 'can get library image ad count by account id successfully' );

    # test getLibraryImageAdsByAccountID
    @library_image_ads = $ysm_ws->getLibraryImageAdsByAccountID(startElement => 0, numElements => 1000 );
    ok( @library_image_ads, 'can call getLibraryImageAdsByAccountID' );
    my $found = 0;
    foreach ( @library_image_ads ) {
        ++$found and last if $_->ID eq $library_image_ad->ID;
    }
    is( $found, 1, 'can get library image ads by account id' );

    # test getLibraryImageAdsByFolderID
     @library_image_ads = $ysm_ws->getLibraryImageAdsByFolderID( folderID => $library_image_ad->folderID );
    ok( @library_image_ads, 'can call getLibraryImageAdsByFolderID' );
    $found = 0;
    foreach ( @library_image_ads ) {
        ++$found and last if $_->ID eq $library_image_ad->ID;
    }
    is( $found, 1, 'can get library image ads by account id' );

    # test deleteLibraryImageAds
    @responses = $ysm_ws->deleteLibraryImageAds( libraryImageAdIDs => [$library_image_ad->ID] );
    ok( @responses, 'can call deleteLibraryImageAds' );
    is( $responses[0]->operationSucceeded, 'true', 'delete library image ads successfully' );
}


1;
