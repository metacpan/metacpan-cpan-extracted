package Yahoo::Marketing::APT::Test::PixelService;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997)

use strict; use warnings;

use base qw/ Yahoo::Marketing::APT::Test::PostTest /;
use Test::More;
use utf8;

use Yahoo::Marketing::APT::PixelService;
use Yahoo::Marketing::APT::Pixel;
use Yahoo::Marketing::APT::PixelResponse;
use Yahoo::Marketing::APT::PiggybackPixel;
use Yahoo::Marketing::APT::BasicResponse;
use Data::Dumper;

# use SOAP::Lite +trace => [qw/ debug method fault /];


sub SKIP_CLASS {
    my $self = shift;
    # 'not running post tests' is a true value
    return 'not running post tests' unless $self->run_post_tests;
    return;
}


sub startup_test_pixel_service : Test(startup) {
    my ( $self ) = @_;

    $self->common_test_data( 'test_pixel', $self->create_pixel ) unless defined $self->common_test_data( 'test_pixel' );
}


sub test_can_operate_pixel : Test(17) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::APT::PixelService->new->parse_config( section => $self->section );

    # test getPixel
    my $pixel = $ysm_ws->getPixel( pixelID => $self->common_test_data( 'test_pixel' )->ID );
    ok( $pixel, 'can get pixel' );
    is( $pixel->name, $self->common_test_data( 'test_pixel' )->name, 'name matches' );

    # test updatePixel
    $pixel->pixelFrequency( Yahoo::Marketing::APT::PixelFrequency->new
                                                                 ->type( 'First' ) );
    my $response = $ysm_ws->updatePixel( pixel => $pixel );
    ok( $response, 'can update pixel' );
    is( $response->operationSucceeded, 'true', 'update pixel successfully' );
    is( $response->pixel->pixelFrequency->type, 'First', 'pixel frequency value matches' );

    # test setPiggybackPixels
    my $piggy_back_pixel = Yahoo::Marketing::APT::PiggybackPixel->new
                                                                ->pixelCode('javascript:alert(1)')
                                                                ->pixelCodeType( 'JavaScript' )
                                                                    ;
    $response = $ysm_ws->setPiggybackPixels( pixelID => $pixel->ID, piggybackPixels => [$piggy_back_pixel] );
    ok( $response, 'can set piggy back pixels' );
    is( $response->operationSucceeded, 'true', 'set piggy back pixels successfully' );

    # test getPixelCode
    my $pixel_code = $ysm_ws->getPixelCode( pixelID => $pixel->ID, pixelCodeType => 'JavaScript' );
    ok( $pixel_code, 'can get pixel code' );

    # test getPiggybackPixels
    my @piggy_back_pixels = $ysm_ws->getPiggybackPixels( pixelID => $pixel->ID );
    ok( @piggy_back_pixels, 'can get piggy back pixels' );
    is( $piggy_back_pixels[0]->pixelCode, $piggy_back_pixel->pixelCode, 'pixel code matches' );

    # test activatePixel
    $response = $ysm_ws->activatePixel( pixelID => $pixel->ID );
    ok( $response, 'can activate pixel' );
    is( $response->operationSucceeded, 'true', 'activate pixel successfully' );

    # test deactivatePixel
    $response = $ysm_ws->deactivatePixel( pixelID => $pixel->ID );
    ok( $response, 'can deactivate pixel' );
    is( $response->operationSucceeded, 'true', 'deactivate pixel successfully' );

    # test getPixelCountByAccountID
    my $count = $ysm_ws->getPixelCountByAccountID();
    ok( $count, 'can get pixel count by account id' );

    # test deletePiggybackPixels
    $response = $ysm_ws->deletePiggybackPixels( pixelID => $pixel->ID );
    ok( $response, 'can delete piggy back pixels' );
    is( $response->operationSucceeded, 'true', 'delete piggy back pixels successfully' );

}


sub test_can_operate_pixels : Test(9) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::APT::PixelService->new->parse_config( section => $self->section );

    # test getPixels
    my @pixels = $ysm_ws->getPixels( pixelIDs => [$self->common_test_data( 'test_pixel' )->ID] );
    ok( @pixels, 'can get pixels' );
    is( $pixels[0]->name, $self->common_test_data( 'test_pixel' )->name, 'name matches' );

    # test updatePixels
    my $pixel = $pixels[0];
    $pixel->pixelFrequency( Yahoo::Marketing::APT::PixelFrequency->new
                                                                 ->type( 'Every' ) );
    my @responses = $ysm_ws->updatePixels( pixels => [$pixel] );
    ok( @responses, 'can update pixels' );
    is( $responses[0]->operationSucceeded, 'true', 'update pixels successfully' );
    is( $responses[0]->pixel->pixelFrequency->type, 'Every', 'pixel frequency value matches' );

    # test activatePixels
    @responses = $ysm_ws->activatePixels( pixelIDs => [$pixel->ID] );
    ok( @responses, 'can activate pixels' );
    is( $responses[0]->operationSucceeded, 'true', 'activate pixels successfully' );

    # test deactivatePixels
    @responses = $ysm_ws->deactivatePixels( pixelIDs => [$pixel->ID] );
    ok( @responses, 'can deactivate pixels' );
    is( $responses[0]->operationSucceeded, 'true', 'deactivate pixels successfully' );
}

1;

