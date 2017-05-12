package Yahoo::Marketing::APT::Test::PlacementEditSettings;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::PlacementEditSettings;

sub test_can_create_placement_edit_settings_and_set_all_fields : Test(5) {

    my $placement_edit_settings = Yahoo::Marketing::APT::PlacementEditSettings->new
                                                                         ->placementEditEndDate( '2009-01-06T17:51:55' )
                                                                         ->placementEditImpression( 'placement edit impression' )
                                                                         ->placementEditPrice( 'placement edit price' )
                                                                         ->startDate( '2009-01-07T17:51:55' )
                   ;

    ok( $placement_edit_settings );

    is( $placement_edit_settings->placementEditEndDate, '2009-01-06T17:51:55', 'can get 2009-01-06T17:51:55' );
    is( $placement_edit_settings->placementEditImpression, 'placement edit impression', 'can get placement edit impression' );
    is( $placement_edit_settings->placementEditPrice, 'placement edit price', 'can get placement edit price' );
    is( $placement_edit_settings->startDate, '2009-01-07T17:51:55', 'can get 2009-01-07T17:51:55' );

};



1;

