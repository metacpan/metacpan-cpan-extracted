package Yahoo::Marketing::APT::Test::PaletteService;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997)

use strict; use warnings;

use base qw/ Yahoo::Marketing::APT::Test::PostTest /;
use Test::More;
use utf8;

use Yahoo::Marketing::APT::PaletteService;
use Yahoo::Marketing::APT::Palette;

use Data::Dumper;

# use SOAP::Lite +trace => [qw/ debug method fault /];


sub SKIP_CLASS {
    my $self = shift;
    # 'not running post tests' is a true value
    return 'not running post tests' unless $self->run_post_tests;
    return;
}


sub test_palette_service : Test(11) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::APT::PaletteService->new->parse_config( section => $self->section);

    # test addPalette
    my $palette = Yahoo::Marketing::APT::Palette->new
                                                ->backgroundColor( 'FFB6C1' )
                                                ->borderColor( '9B30FF' )
                                                ->descriptionColor( '008B8B' )
                                                ->name( 'test palette' )
                                                ->titleColor( '808069' )
                                                ->urlColor( 'FFF8DC' )
                                                    ;
    my $response = $ysm_ws->addPalette( palette => $palette );
    ok( $response );
    is( $response->operationSucceeded, 'true' );
    $palette = $response->palette;

    # test updatePalette
    $ysm_ws->updatePalette( palette => $palette->urlColor( 'CCCCCC' ) );
    $response = $ysm_ws->updatePalette( palette => $palette );
    ok( $response );
    is( $response->operationSucceeded, 'true' );
    $palette = $response->palette;
    is( $palette->urlColor, 'CCCCCC' );

    # test getPalettesByAccountID
    my @palettes = $ysm_ws->getPalettesByAccountID();
    ok( @palettes );

    # test getPalette
    $palette = $ysm_ws->getPalette( paletteID => $palette->ID );
    ok( $palette );

    # test copyPalette
    $response = $ysm_ws->copyPalette( paletteID => $palette->ID, newName => 'copy palette' );
    ok( $response );
    is( $response->operationSucceeded, 'true' );
    my $copied_palette = $response->palette;

    # test deletePalette
    $response = $ysm_ws->deletePalette( paletteID => $palette->ID );
    ok( $response );
    is( $response->operationSucceeded, 'true' );

    $ysm_ws->deletePalette( paletteID => $copied_palette->ID );
}




1;
