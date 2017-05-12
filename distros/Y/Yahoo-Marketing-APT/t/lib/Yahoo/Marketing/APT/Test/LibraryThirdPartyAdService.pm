package Yahoo::Marketing::APT::Test::LibraryThirdPartyAdService;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997)

use strict; use warnings;

use base qw/ Yahoo::Marketing::APT::Test::PostTest /;
use Test::More;
use utf8;

use Yahoo::Marketing::APT::LibraryThirdPartyAdService;
use Yahoo::Marketing::APT::LibraryThirdPartyAd;

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
}

sub shutdown_test_folder_service : Test(shutdown) {
    my ( $self ) = @_;

    $self->cleanup_ad_folder;
}


sub test_can_operate_library_third_party_ad : Test(10) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::APT::LibraryThirdPartyAdService->new->parse_config( section => $self->section );

    my $tag_with_micros = q~<![CDATA[<NOLAYER><IFRAME SRC="http://ad.yahoo.com/adi/N3226.Yahoo/B2391090;sz=160x600;ord=[timestamp]?" WIDTH=160 HEIGHT=600 MARGINWIDTH=0 MARGINHEIGHT=0 HSPACE=0 VSPACE=0 FRAMEBORDER=0 SCROLLING=no BORDERCOLOR='#000000'><A HREF="${CLICKURL}http://ad.yahoo.com/jump/N3226.Yahoo/B2391090;abr=!ie4;abr=!ie5;sz=160x600;ord=${REQUESTID}?"><IMG SRC="http://ad.yahoo.com/ad/N3226.Yahoo/B2391090;abr=!ie4;abr=!ie5;sz=160x600;ord=${REQUESTID}?" BORDER=0 WIDTH=160 HEIGHT=600 ALT="Click Here"></A></IFRAME></NOLAYER><ILAYER SRC="http://ad.yahoo.com/adl/N3226.Yahoo/B2391090;sz=160x600;ord=[timestamp]?" WIDTH=160 HEIGHT=600></ILAYER>]]>~;
    my $library_third_party_ad = Yahoo::Marketing::APT::LibraryThirdPartyAd->new
                                                                           ->tagWithMacros( $tag_with_micros )
                                                                           ->name( 'test third party ad' )
                                                                               ;
    # test addLibraryThirdPartyAd
    my $response = $ysm_ws->addLibraryThirdPartyAd( libraryThirdPartyAd => $library_third_party_ad );
    ok( $response, 'can call addLibraryThirdPartyAd' );
    is( $response->operationSucceeded, 'true', 'add library third_party ad successfully' );
    $library_third_party_ad = $response->libraryThirdPartyAd;
    is( $library_third_party_ad->name, 'test third party ad', 'name matches' );

    # test getLibraryThirdPartyAd
    $library_third_party_ad = $ysm_ws->getLibraryThirdPartyAd( libraryThirdPartyAdID => $library_third_party_ad->ID );
    ok( $library_third_party_ad, 'can call getLibraryThirdPartyAd' );
    is( $library_third_party_ad->name, 'test third party ad', 'name matches' );

    # test updateLibraryThirdPartyAd
    $library_third_party_ad->name( 'new third party ad' );
    $response = $ysm_ws->updateLibraryThirdPartyAd( libraryThirdPartyAd => $library_third_party_ad );
    ok( $response, 'can call updateLibraryThirdPartyAd' );
    is( $response->operationSucceeded, 'true', 'update library third_party ad successfully' );
    $library_third_party_ad = $response->libraryThirdPartyAd;
    is( $library_third_party_ad->name, 'new third party ad', 'name matches' );

    # test deleteLibraryThirdPartyAd
    $response = $ysm_ws->deleteLibraryThirdPartyAd( libraryThirdPartyAdID => $library_third_party_ad->ID );
    ok( $response, 'can call deleteLibraryThirdPartyAd' );
    is( $response->operationSucceeded, 'true', 'delete library third_party ad successfully' );
}


sub test_can_operate_library_third_party_ads : Test(16) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::APT::LibraryThirdPartyAdService->new->parse_config( section => $self->section );
    my $tag_with_micros = q~<![CDATA[<NOLAYER><IFRAME SRC="http://ad.yahoo.com/adi/N3226.Yahoo/B2391090;sz=160x600;ord=[timestamp]?" WIDTH=160 HEIGHT=600 MARGINWIDTH=0 MARGINHEIGHT=0 HSPACE=0 VSPACE=0 FRAMEBORDER=0 SCROLLING=no BORDERCOLOR='#000000'><A HREF="${CLICKURL}http://ad.yahoo.com/jump/N3226.Yahoo/B2391090;abr=!ie4;abr=!ie5;sz=160x600;ord=${REQUESTID}?"><IMG SRC="http://ad.yahoo.com/ad/N3226.Yahoo/B2391090;abr=!ie4;abr=!ie5;sz=160x600;ord=${REQUESTID}?" BORDER=0 WIDTH=160 HEIGHT=600 ALT="Click Here"></A></IFRAME></NOLAYER><ILAYER SRC="http://ad.yahoo.com/adl/N3226.Yahoo/B2391090;sz=160x600;ord=[timestamp]?" WIDTH=160 HEIGHT=600></ILAYER>]]>~;
    my $library_third_party_ad = Yahoo::Marketing::APT::LibraryThirdPartyAd->new
                                                                           ->tagWithMacros( $tag_with_micros )
                                                                           ->name( 'test third party ad' )
                                                                               ;
    # test addLibraryThirdPartyAds
    my @responses = $ysm_ws->addLibraryThirdPartyAds( libraryThirdPartyAds => [$library_third_party_ad] );
    ok( @responses, 'can call addLibraryThirdPartyAds' );
    is( $responses[0]->operationSucceeded, 'true', 'add library third party ads successfully' );
    $library_third_party_ad = $responses[0]->libraryThirdPartyAd;
    is( $library_third_party_ad->name, 'test third party ad', 'name matches' );

    # test getLibraryThirdPartyAds
    my @library_third_party_ads = $ysm_ws->getLibraryThirdPartyAds( libraryThirdPartyAdIDs => [$library_third_party_ad->ID] );
    ok( @library_third_party_ads, 'can call getLibraryThirdPartyAds' );
    is( $library_third_party_ads[0]->name, 'test third party ad', 'name matches' );

    # test updateLibraryThirdPartyAd
    $library_third_party_ad->name( 'new third party ad' );
    @responses = $ysm_ws->updateLibraryThirdPartyAds( libraryThirdPartyAds => [$library_third_party_ad] );
    ok( @responses, 'can call updateLibraryThirdPartyAds' );
    is( $responses[0]->operationSucceeded, 'true', 'update library third party ads successfully' );
    $library_third_party_ad = $responses[0]->libraryThirdPartyAd;
    is( $library_third_party_ad->name, 'new third party ad', 'name matches' );

    # test getLibraryThirdPartyAdCountByAccountID
    my $count = $ysm_ws->getLibraryThirdPartyAdCountByAccountID();
    ok( $count, 'can call getLibraryThirdPartyAdCountByAccountID' );
    like( $count, qr/\d+/, 'can get library third party ad count by account id successfully' );

    # test getLibraryThirdPartyAdsByAccountID
    @library_third_party_ads = $ysm_ws->getLibraryThirdPartyAdsByAccountID(startElement => 0, numElements => 1000 );
    ok( @library_third_party_ads, 'can call getLibraryThirdPartyAdsByAccountID' );
    my $found = 0;
    foreach ( @library_third_party_ads ) {
        ++$found and last if $_->ID eq $library_third_party_ad->ID;
    }
    is( $found, 1, 'can get library third party ads by account id' );

    # test getLibraryThirdPartyAdsByFolderID
    @library_third_party_ads = $ysm_ws->getLibraryThirdPartyAdsByFolderID( folderID => $library_third_party_ad->folderID );
    ok( @library_third_party_ads, 'can call getLibraryThirdPartyAdsByFolderID' );
    $found = 0;
    foreach ( @library_third_party_ads ) {
        ++$found and last if $_->ID eq $library_third_party_ad->ID;
    }
    is( $found, 1, 'can get library third party ads by account id' );

    # test deleteLibraryThirdPartyAds
    @responses = $ysm_ws->deleteLibraryThirdPartyAds( libraryThirdPartyAdIDs => [$library_third_party_ad->ID] );
    ok( @responses, 'can call deleteLibraryThirdPartyAds' );
    is( $responses[0]->operationSucceeded, 'true', 'delete library third party ads successfully' );
}


1;
