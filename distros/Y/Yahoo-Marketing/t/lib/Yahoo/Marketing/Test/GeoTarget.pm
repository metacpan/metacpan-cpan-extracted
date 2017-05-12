package Yahoo::Marketing::Test::GeoTarget;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::GeoTarget;

sub test_can_create_geo_target_and_set_all_fields : Test(3) {

    my $geo_target = Yahoo::Marketing::GeoTarget->new
                                                ->geoLocation( 'geo location' )
                                                ->premium( 'premium' )
                   ;

    ok( $geo_target );

    is( $geo_target->geoLocation, 'geo location', 'can get geo location' );
    is( $geo_target->premium, 'premium', 'can get premium' );

};



1;

