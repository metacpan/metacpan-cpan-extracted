package Yahoo::Marketing::APT::Test::LibraryCustomHTMLAdService;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997)

use strict; use warnings;

use base qw/ Yahoo::Marketing::APT::Test::PostTest /;
use Test::More;
use utf8;

use Yahoo::Marketing::APT::LibraryCustomHTMLAdService;
use Yahoo::Marketing::APT::ImageCreativeService;
use Yahoo::Marketing::APT::ImageCreative;
use Yahoo::Marketing::APT::LibraryCustomHTMLAd;

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


sub test_can_operate_library_customHTML_ad : Test(10) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::APT::LibraryCustomHTMLAdService->new->parse_config( section => $self->section );
    my $html_tag = q~<![CDATA[<a href='${CLICKURL}http://yahoo.com'><img src='${IMAGEURL}~.
        $self->common_test_data('test_image_creative')->urlPath.
        q~' alt='Click here'/></a>]]>~;
    my $library_customHTML_ad = Yahoo::Marketing::APT::LibraryCustomHTMLAd->new
                                                                          ->creativeIDs( [$self->common_test_data('test_image_creative')->ID] )
                                                                          ->height(100)
                                                                          ->htmlTagWithMacros( $html_tag )
                                                                          ->name( 'test customHTML ad' )
                                                                          ->width( 100 )
                                                                              ;
    # test addLibraryCustomHTMLAd
    my $response = $ysm_ws->addLibraryCustomHTMLAd( libraryCustomHTMLAd => $library_customHTML_ad );
    ok( $response, 'can call addLibraryCustomHTMLAd' );
    is( $response->operationSucceeded, 'true', 'add library customHTML ad successfully' );
    $library_customHTML_ad = $response->libraryCustomHTMLAd;
    like( $library_customHTML_ad->name, qr/test customHTML ad/, 'name matches' );

    # test getLibraryCustomHTMLAd
    $library_customHTML_ad = $ysm_ws->getLibraryCustomHTMLAd( libraryCustomHTMLAdID => $library_customHTML_ad->ID );
    ok( $library_customHTML_ad, 'can call getLibraryCustomHTMLAd' );
    like( $library_customHTML_ad->name, qr/test customHTML ad/, 'name matches' );

    # test updateLibraryCustomHTMLAd
    $library_customHTML_ad->name( 'new customHTML ad' );
    $library_customHTML_ad->creativeIDs( [$self->common_test_data('test_image_creative')->ID] );
    $response = $ysm_ws->updateLibraryCustomHTMLAd( libraryCustomHTMLAd => $library_customHTML_ad );
    ok( $response, 'can call updateLibraryCustomHTMLAd' );
    is( $response->operationSucceeded, 'true', 'update library customHTML ad successfully' );
    $library_customHTML_ad = $response->libraryCustomHTMLAd;
    like( $library_customHTML_ad->name, qr/new customHTML ad/, 'name matches' );

    # test deleteLibraryCustomHTMLAd
    $response = $ysm_ws->deleteLibraryCustomHTMLAd( libraryCustomHTMLAdID => $library_customHTML_ad->ID );
    ok( $response, 'can call deleteLibraryCustomHTMLAd' );
    is( $response->operationSucceeded, 'true', 'delete library customHTML ad successfully' );
}


sub test_can_operate_library_customHTML_ads : Test(16) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::APT::LibraryCustomHTMLAdService->new->parse_config( section => $self->section );

    my $html_tag = q~<![CDATA[<a href='${CLICKURL}http://yahoo.com'><img src='${IMAGEURL}~.
        $self->common_test_data('test_image_creative')->urlPath.
        q~' alt='Click here'/></a>]]>~;
    my $library_customHTML_ad = Yahoo::Marketing::APT::LibraryCustomHTMLAd->new
                                                                          ->creativeIDs( [$self->common_test_data('test_image_creative')->ID] )
                                                                          ->height(100)
                                                                          ->htmlTagWithMacros( $html_tag )
                                                                          ->name( 'test customHTML ad' )
                                                                          ->width( 100 )
                                                                              ;
    # test addLibraryCustomHTMLAds
    my @responses = $ysm_ws->addLibraryCustomHTMLAds( libraryCustomHTMLAds => [$library_customHTML_ad] );
    ok( @responses, 'can call addLibraryCustomHTMLAds' );
    is( $responses[0]->operationSucceeded, 'true', 'add library customHTML ads successfully' );
    $library_customHTML_ad = $responses[0]->libraryCustomHTMLAd;
    like( $library_customHTML_ad->name, qr/test customHTML ad/, 'name matches' );

    # test getLibraryCustomHTMLAds
    my @library_customHTML_ads = $ysm_ws->getLibraryCustomHTMLAds( libraryCustomHTMLAdIDs => [$library_customHTML_ad->ID] );
    ok( @library_customHTML_ads, 'can call getLibraryCustomHTMLAds' );
    like( $library_customHTML_ads[0]->name, qr/test customHTML ad/, 'name matches' );

    # test updateLibraryCustomHTMLAd
    $library_customHTML_ad->name( 'new customHTML ad' );
    $library_customHTML_ad->creativeIDs( [$self->common_test_data('test_image_creative')->ID] );
    @responses = $ysm_ws->updateLibraryCustomHTMLAds( libraryCustomHTMLAds => [$library_customHTML_ad] );
    ok( @responses, 'can call updateLibraryCustomHTMLAds' );
    is( $responses[0]->operationSucceeded, 'true', 'update library customHTML ads successfully' );
    $library_customHTML_ad = $responses[0]->libraryCustomHTMLAd;
    like( $library_customHTML_ad->name, qr/new customHTML ad/, 'name matches' );

    # test getLibraryCustomHTMLAdCountByAccountID
    my $count = $ysm_ws->getLibraryCustomHTMLAdCountByAccountID();
    ok( $count, 'can call getLibraryCustomHTMLAdCountByAccountID' );
    like( $count, qr/\d+/, 'can get library customHTML ad count by account id successfully' );

    # test getLibraryCustomHTMLAdsByAccountID
    @library_customHTML_ads = $ysm_ws->getLibraryCustomHTMLAdsByAccountID(startElement => 0, numElements => 1000 );
    ok( @library_customHTML_ads, 'can call getLibraryCustomHTMLAdsByAccountID' );
    my $found = 0;
    foreach ( @library_customHTML_ads ) {
        ++$found and last if $_->ID eq $library_customHTML_ad->ID;
    }
    is( $found, 1, 'can get library customHTML ads by account id' );

    # test getLibraryCustomHTMLAdsByFolderID
    @library_customHTML_ads = $ysm_ws->getLibraryCustomHTMLAdsByFolderID( folderID => $library_customHTML_ad->folderID );
    ok( @library_customHTML_ads, 'can call getLibraryCustomHTMLAdsByFolderID' );
    $found = 0;
    foreach ( @library_customHTML_ads ) {
        ++$found and last if $_->ID eq $library_customHTML_ad->ID;
    }
    is( $found, 1, 'can get library customHTML ads by account id' );

    # test deleteLibraryCustomHTMLAds
    @responses = $ysm_ws->deleteLibraryCustomHTMLAds( libraryCustomHTMLAdIDs => [$library_customHTML_ad->ID] );
    ok( @responses, 'can call deleteLibraryCustomHTMLAds' );
    is( $responses[0]->operationSucceeded, 'true', 'delete library customHTML ads successfully' );
}


1;
