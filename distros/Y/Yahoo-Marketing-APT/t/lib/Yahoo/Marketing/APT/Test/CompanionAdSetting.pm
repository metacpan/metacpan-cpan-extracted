package Yahoo::Marketing::APT::Test::CompanionAdSetting;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::CompanionAdSetting;

sub test_can_create_companion_ad_setting_and_set_all_fields : Test(5) {

    my $companion_ad_setting = Yahoo::Marketing::APT::CompanionAdSetting->new
                                                                   ->adBehaviorID( 'ad behavior id' )
                                                                   ->adDeliveryModeID( 'ad delivery mode id' )
                                                                   ->adFormatID( 'ad format id' )
                                                                   ->adSizeID( 'ad size id' )
                   ;

    ok( $companion_ad_setting );

    is( $companion_ad_setting->adBehaviorID, 'ad behavior id', 'can get ad behavior id' );
    is( $companion_ad_setting->adDeliveryModeID, 'ad delivery mode id', 'can get ad delivery mode id' );
    is( $companion_ad_setting->adFormatID, 'ad format id', 'can get ad format id' );
    is( $companion_ad_setting->adSizeID, 'ad size id', 'can get ad size id' );

};



1;

