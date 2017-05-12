package Yahoo::Marketing::Test::CampaignCarrierConfig;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::CampaignCarrierConfig;

sub test_can_create_campaign_carrier_config_and_set_all_fields : Test(2) {

    my $campaign_carrier_config = Yahoo::Marketing::CampaignCarrierConfig->new
                                                                         ->carrierSettings( 'carrier settings' )
                   ;

    ok( $campaign_carrier_config );

    is( $campaign_carrier_config->carrierSettings, 'carrier settings', 'can get carrier settings' );

};



1;

