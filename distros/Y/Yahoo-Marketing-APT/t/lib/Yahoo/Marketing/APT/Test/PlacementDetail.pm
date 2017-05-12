package Yahoo::Marketing::APT::Test::PlacementDetail;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::PlacementDetail;

sub test_can_create_placement_detail_and_set_all_fields : Test(5) {

    my $placement_detail = Yahoo::Marketing::APT::PlacementDetail->new
                                                            ->discounts( 'discounts' )
                                                            ->pixel( 'pixel' )
                                                            ->placement( 'placement' )
                                                            ->targetingProfile( 'targeting profile' )
                   ;

    ok( $placement_detail );

    is( $placement_detail->discounts, 'discounts', 'can get discounts' );
    is( $placement_detail->pixel, 'pixel', 'can get pixel' );
    is( $placement_detail->placement, 'placement', 'can get placement' );
    is( $placement_detail->targetingProfile, 'targeting profile', 'can get targeting profile' );

};



1;

