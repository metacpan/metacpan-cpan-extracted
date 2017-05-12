package Yahoo::Marketing::Test::CampaignCarrierSetting;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::CampaignCarrierSetting;

sub test_can_create_campaign_carrier_setting_and_set_all_fields : Test(3) {

    my $campaign_carrier_setting = Yahoo::Marketing::CampaignCarrierSetting->new
                                                                           ->carrier( 'carrier' )
                                                                           ->status( 'status' )
                   ;

    ok( $campaign_carrier_setting );

    is( $campaign_carrier_setting->carrier, 'carrier', 'can get carrier' );
    is( $campaign_carrier_setting->status, 'status', 'can get status' );

};



1;

