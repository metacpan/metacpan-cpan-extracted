package Yahoo::Marketing::Test::KeywordCarrierEditorialReasons;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::KeywordCarrierEditorialReasons;

sub test_can_create_keyword_carrier_editorial_reasons_and_set_all_fields : Test(2) {

    my $keyword_carrier_editorial_reasons = Yahoo::Marketing::KeywordCarrierEditorialReasons->new
                                                                                            ->keywordCarrierEditorialReasonInfo( 'keyword carrier editorial reason info' )
                   ;

    ok( $keyword_carrier_editorial_reasons );

    is( $keyword_carrier_editorial_reasons->keywordCarrierEditorialReasonInfo, 'keyword carrier editorial reason info', 'can get keyword carrier editorial reason info' );

};



1;

