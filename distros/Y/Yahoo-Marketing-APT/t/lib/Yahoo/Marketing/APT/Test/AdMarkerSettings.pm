package Yahoo::Marketing::APT::Test::AdMarkerSettings;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::AdMarkerSettings;

sub test_can_create_ad_marker_settings_and_set_all_fields : Test(5) {

    my $ad_marker_settings = Yahoo::Marketing::APT::AdMarkerSettings->new
                                                               ->active( 'active' )
                                                               ->attributes( 'attributes' )
                                                               ->defaultUrl( 'default url' )
                                                               ->landingUrl( 'landing url' )
                   ;

    ok( $ad_marker_settings );

    is( $ad_marker_settings->active, 'active', 'can get active' );
    is( $ad_marker_settings->attributes, 'attributes', 'can get attributes' );
    is( $ad_marker_settings->defaultUrl, 'default url', 'can get default url' );
    is( $ad_marker_settings->landingUrl, 'landing url', 'can get landing url' );

};



1;

