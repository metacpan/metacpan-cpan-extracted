package Yahoo::Marketing::Test::AdCarrierEditorialReasons;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::AdCarrierEditorialReasons;

sub test_can_create_ad_carrier_editorial_reasons_and_set_all_fields : Test(2) {

    my $ad_carrier_editorial_reasons = Yahoo::Marketing::AdCarrierEditorialReasons->new
                                                                                  ->adCarrierEditorialReasonInfo( 'ad carrier editorial reason info' )
                   ;

    ok( $ad_carrier_editorial_reasons );

    is( $ad_carrier_editorial_reasons->adCarrierEditorialReasonInfo, 'ad carrier editorial reason info', 'can get ad carrier editorial reason info' );

};



1;

