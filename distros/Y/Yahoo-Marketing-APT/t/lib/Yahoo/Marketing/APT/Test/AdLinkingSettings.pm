package Yahoo::Marketing::APT::Test::AdLinkingSettings;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::AdLinkingSettings;

sub test_can_create_ad_linking_settings_and_set_all_fields : Test(4) {

    my $ad_linking_settings = Yahoo::Marketing::APT::AdLinkingSettings->new
                                                                 ->adLinkingType( 'ad linking type' )
                                                                 ->companionAdSettings( 'companion ad settings' )
                                                                 ->storyBoardAdSizeID( 'story board ad size id' )
                   ;

    ok( $ad_linking_settings );

    is( $ad_linking_settings->adLinkingType, 'ad linking type', 'can get ad linking type' );
    is( $ad_linking_settings->companionAdSettings, 'companion ad settings', 'can get companion ad settings' );
    is( $ad_linking_settings->storyBoardAdSizeID, 'story board ad size id', 'can get story board ad size id' );

};



1;

