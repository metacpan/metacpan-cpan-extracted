package Yahoo::Marketing::Test::UpdateForKeywordCarrierSetting;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::UpdateForKeywordCarrierSetting;

sub test_can_create_update_for_keyword_carrier_setting_and_set_all_fields : Test(4) {

    my $update_for_keyword_carrier_setting = Yahoo::Marketing::UpdateForKeywordCarrierSetting->new
                                                                                             ->carrier( 'carrier' )
                                                                                             ->editorialStatus( 'editorial status' )
                                                                                             ->url( 'url' )
                   ;

    ok( $update_for_keyword_carrier_setting );

    is( $update_for_keyword_carrier_setting->carrier, 'carrier', 'can get carrier' );
    is( $update_for_keyword_carrier_setting->editorialStatus, 'editorial status', 'can get editorial status' );
    is( $update_for_keyword_carrier_setting->url, 'url', 'can get url' );

};



1;

