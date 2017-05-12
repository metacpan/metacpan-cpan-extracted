package Yahoo::Marketing::Test::KeywordCarrierEditorialReasonInfo;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::KeywordCarrierEditorialReasonInfo;

sub test_can_create_keyword_carrier_editorial_reason_info_and_set_all_fields : Test(3) {

    my $keyword_carrier_editorial_reason_info = Yahoo::Marketing::KeywordCarrierEditorialReasonInfo->new
                                                                                                   ->carrier( 'carrier' )
                                                                                                   ->keywordEditorialReasons( 'keyword editorial reasons' )
                   ;

    ok( $keyword_carrier_editorial_reason_info );

    is( $keyword_carrier_editorial_reason_info->carrier, 'carrier', 'can get carrier' );
    is( $keyword_carrier_editorial_reason_info->keywordEditorialReasons, 'keyword editorial reasons', 'can get keyword editorial reasons' );

};



1;

