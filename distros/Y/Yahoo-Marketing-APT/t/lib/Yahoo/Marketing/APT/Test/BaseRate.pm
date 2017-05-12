package Yahoo::Marketing::APT::Test::BaseRate;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::BaseRate;

sub test_can_create_base_rate_and_set_all_fields : Test(11) {

    my $base_rate = Yahoo::Marketing::APT::BaseRate->new
                                              ->ID( 'id' )
                                              ->endDate( '2009-01-06T17:51:55' )
                                              ->floorCPM( 'floor cpm' )
                                              ->listCPM( 'list cpm' )
                                              ->listFloorPercentageMarkup( 'list floor percentage markup' )
                                              ->rateCardID( 'rate card id' )
                                              ->startDate( '2009-01-07T17:51:55' )
                                              ->targetCPM( 'target cpm' )
                                              ->targetFloorPercentageMarkup( 'target floor percentage markup' )
                                              ->targetingAttributeDescriptorsWithAny( 'targeting attribute descriptors with any' )
                   ;

    ok( $base_rate );

    is( $base_rate->ID, 'id', 'can get id' );
    is( $base_rate->endDate, '2009-01-06T17:51:55', 'can get 2009-01-06T17:51:55' );
    is( $base_rate->floorCPM, 'floor cpm', 'can get floor cpm' );
    is( $base_rate->listCPM, 'list cpm', 'can get list cpm' );
    is( $base_rate->listFloorPercentageMarkup, 'list floor percentage markup', 'can get list floor percentage markup' );
    is( $base_rate->rateCardID, 'rate card id', 'can get rate card id' );
    is( $base_rate->startDate, '2009-01-07T17:51:55', 'can get 2009-01-07T17:51:55' );
    is( $base_rate->targetCPM, 'target cpm', 'can get target cpm' );
    is( $base_rate->targetFloorPercentageMarkup, 'target floor percentage markup', 'can get target floor percentage markup' );
    is( $base_rate->targetingAttributeDescriptorsWithAny, 'targeting attribute descriptors with any', 'can get targeting attribute descriptors with any' );

};



1;

