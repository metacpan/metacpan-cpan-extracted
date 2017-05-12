package Yahoo::Marketing::APT::Test::AdMarker;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::AdMarker;

sub test_can_create_ad_marker_and_set_all_fields : Test(4) {

    my $ad_marker = Yahoo::Marketing::APT::AdMarker->new
                                              ->ID( 'id' )
                                              ->accountID( 'account id' )
                                              ->adMarkerSettings( 'ad marker settings' )
                   ;

    ok( $ad_marker );

    is( $ad_marker->ID, 'id', 'can get id' );
    is( $ad_marker->accountID, 'account id', 'can get account id' );
    is( $ad_marker->adMarkerSettings, 'ad marker settings', 'can get ad marker settings' );

};



1;

