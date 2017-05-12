package Yahoo::Marketing::APT::Test::DefaultBaseRate;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::DefaultBaseRate;

sub test_can_create_default_base_rate_and_set_all_fields : Test(8) {

    my $default_base_rate = Yahoo::Marketing::APT::DefaultBaseRate->new
                                                             ->ID( 'id' )
                                                             ->floorCPM( 'floor cpm' )
                                                             ->listCPM( 'list cpm' )
                                                             ->listFloorPercentageMarkup( 'list floor percentage markup' )
                                                             ->rateCardID( 'rate card id' )
                                                             ->targetCPM( 'target cpm' )
                                                             ->targetFloorPercentageMarkup( 'target floor percentage markup' )
                   ;

    ok( $default_base_rate );

    is( $default_base_rate->ID, 'id', 'can get id' );
    is( $default_base_rate->floorCPM, 'floor cpm', 'can get floor cpm' );
    is( $default_base_rate->listCPM, 'list cpm', 'can get list cpm' );
    is( $default_base_rate->listFloorPercentageMarkup, 'list floor percentage markup', 'can get list floor percentage markup' );
    is( $default_base_rate->rateCardID, 'rate card id', 'can get rate card id' );
    is( $default_base_rate->targetCPM, 'target cpm', 'can get target cpm' );
    is( $default_base_rate->targetFloorPercentageMarkup, 'target floor percentage markup', 'can get target floor percentage markup' );

};



1;

