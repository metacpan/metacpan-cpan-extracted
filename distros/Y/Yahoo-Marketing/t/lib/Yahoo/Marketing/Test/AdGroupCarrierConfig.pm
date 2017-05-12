package Yahoo::Marketing::Test::AdGroupCarrierConfig;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::AdGroupCarrierConfig;

sub test_can_create_ad_group_carrier_config_and_set_all_fields : Test(2) {

    my $ad_group_carrier_config = Yahoo::Marketing::AdGroupCarrierConfig->new
                                                                        ->carrierSettings( 'carrier settings' )
                   ;

    ok( $ad_group_carrier_config );

    is( $ad_group_carrier_config->carrierSettings, 'carrier settings', 'can get carrier settings' );

};



1;

