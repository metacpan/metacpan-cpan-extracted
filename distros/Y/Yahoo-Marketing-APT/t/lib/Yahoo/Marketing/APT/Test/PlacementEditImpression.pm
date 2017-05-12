package Yahoo::Marketing::APT::Test::PlacementEditImpression;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::PlacementEditImpression;

sub test_can_create_placement_edit_impression_and_set_all_fields : Test(5) {

    my $placement_edit_impression = Yahoo::Marketing::APT::PlacementEditImpression->new
                                                                             ->count( 'count' )
                                                                             ->impressionChangeType( 'impression change type' )
                                                                             ->qtyChangeType( 'qty change type' )
                                                                             ->qtyType( 'qty type' )
                   ;

    ok( $placement_edit_impression );

    is( $placement_edit_impression->count, 'count', 'can get count' );
    is( $placement_edit_impression->impressionChangeType, 'impression change type', 'can get impression change type' );
    is( $placement_edit_impression->qtyChangeType, 'qty change type', 'can get qty change type' );
    is( $placement_edit_impression->qtyType, 'qty type', 'can get qty type' );

};



1;

