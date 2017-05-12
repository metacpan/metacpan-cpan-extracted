package Yahoo::Marketing::Test::UpdateForKeywordCarrierConfig;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::UpdateForKeywordCarrierConfig;

sub test_can_create_update_for_keyword_carrier_config_and_set_all_fields : Test(2) {

    my $update_for_keyword_carrier_config = Yahoo::Marketing::UpdateForKeywordCarrierConfig->new
                                                                                           ->carrierSettings( 'carrier settings' )
                   ;

    ok( $update_for_keyword_carrier_config );

    is( $update_for_keyword_carrier_config->carrierSettings, 'carrier settings', 'can get carrier settings' );

};



1;

