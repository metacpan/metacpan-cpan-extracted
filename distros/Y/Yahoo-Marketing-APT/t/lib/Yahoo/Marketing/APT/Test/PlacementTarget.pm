package Yahoo::Marketing::APT::Test::PlacementTarget;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::PlacementTarget;

sub test_can_create_placement_target_and_set_all_fields : Test(3) {

    my $placement_target = Yahoo::Marketing::APT::PlacementTarget->new
                                                            ->ID( 'id' )
                                                            ->type( 'type' )
                   ;

    ok( $placement_target );

    is( $placement_target->ID, 'id', 'can get id' );
    is( $placement_target->type, 'type', 'can get type' );

};



1;

