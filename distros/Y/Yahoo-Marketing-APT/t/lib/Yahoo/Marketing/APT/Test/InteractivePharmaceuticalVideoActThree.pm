package Yahoo::Marketing::APT::Test::InteractivePharmaceuticalVideoActThree;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::InteractivePharmaceuticalVideoActThree;

sub test_can_create_interactive_pharmaceutical_video_act_three_and_set_all_fields : Test(16) {

    my $interactive_pharmaceutical_video_act_three = Yahoo::Marketing::APT::InteractivePharmaceuticalVideoActThree->new
                                                                                                             ->brandingLogoClickUrl( 'branding logo click url' )
                                                                                                             ->brandingLogoFlashCreativeID( 'branding logo flash creative id' )
                                                                                                             ->companyName( 'company name' )
                                                                                                             ->isiInformation( 'isi information' )
                                                                                                             ->isiUrl( 'isi url' )
                                                                                                             ->playback0Beacons( 'playback0 beacons' )
                                                                                                             ->playback100Beacons( 'playback100 beacons' )
                                                                                                             ->playback25Beacons( 'playback25 beacons' )
                                                                                                             ->playback50Beacons( 'playback50 beacons' )
                                                                                                             ->playback75Beacons( 'playback75 beacons' )
                                                                                                             ->prescriptionPdfClickUrl( 'prescription pdf click url' )
                                                                                                             ->sliderButtonFlashCreativeID( 'slider button flash creative id' )
                                                                                                             ->sliderClickUrl( 'slider click url' )
                                                                                                             ->sliderPanelFlashCreativeID( 'slider panel flash creative id' )
                                                                                                             ->videoCreativeID( 'video creative id' )
                   ;

    ok( $interactive_pharmaceutical_video_act_three );

    is( $interactive_pharmaceutical_video_act_three->brandingLogoClickUrl, 'branding logo click url', 'can get branding logo click url' );
    is( $interactive_pharmaceutical_video_act_three->brandingLogoFlashCreativeID, 'branding logo flash creative id', 'can get branding logo flash creative id' );
    is( $interactive_pharmaceutical_video_act_three->companyName, 'company name', 'can get company name' );
    is( $interactive_pharmaceutical_video_act_three->isiInformation, 'isi information', 'can get isi information' );
    is( $interactive_pharmaceutical_video_act_three->isiUrl, 'isi url', 'can get isi url' );
    is( $interactive_pharmaceutical_video_act_three->playback0Beacons, 'playback0 beacons', 'can get playback0 beacons' );
    is( $interactive_pharmaceutical_video_act_three->playback100Beacons, 'playback100 beacons', 'can get playback100 beacons' );
    is( $interactive_pharmaceutical_video_act_three->playback25Beacons, 'playback25 beacons', 'can get playback25 beacons' );
    is( $interactive_pharmaceutical_video_act_three->playback50Beacons, 'playback50 beacons', 'can get playback50 beacons' );
    is( $interactive_pharmaceutical_video_act_three->playback75Beacons, 'playback75 beacons', 'can get playback75 beacons' );
    is( $interactive_pharmaceutical_video_act_three->prescriptionPdfClickUrl, 'prescription pdf click url', 'can get prescription pdf click url' );
    is( $interactive_pharmaceutical_video_act_three->sliderButtonFlashCreativeID, 'slider button flash creative id', 'can get slider button flash creative id' );
    is( $interactive_pharmaceutical_video_act_three->sliderClickUrl, 'slider click url', 'can get slider click url' );
    is( $interactive_pharmaceutical_video_act_three->sliderPanelFlashCreativeID, 'slider panel flash creative id', 'can get slider panel flash creative id' );
    is( $interactive_pharmaceutical_video_act_three->videoCreativeID, 'video creative id', 'can get video creative id' );

};



1;

