package Yahoo::Marketing::APT::Test::PlacementFrequencyTargetingAttributes;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::PlacementFrequencyTargetingAttributes;

sub test_can_create_placement_frequency_targeting_attributes_and_set_all_fields : Test(3) {

    my $placement_frequency_targeting_attributes = Yahoo::Marketing::APT::PlacementFrequencyTargetingAttributes->new
                                                                                                          ->dayParting( 'day parting' )
                                                                                                          ->frequencyCap( 'frequency cap' )
                   ;

    ok( $placement_frequency_targeting_attributes );

    is( $placement_frequency_targeting_attributes->dayParting, 'day parting', 'can get day parting' );
    is( $placement_frequency_targeting_attributes->frequencyCap, 'frequency cap', 'can get frequency cap' );

};



1;

