package Yahoo::Marketing::Test::TargetingProfile;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::TargetingProfile;

sub test_can_create_targeting_profile_and_set_all_fields : Test(5) {

    my $targeting_profile = Yahoo::Marketing::TargetingProfile->new
                                                              ->dayPartingTargeting( 'day parting targeting' )
                                                              ->demographicTargeting( 'demographic targeting' )
                                                              ->geoTargets( 'geo targets' )
                                                              ->networkDistribution( 'network distribution' )
                   ;

    ok( $targeting_profile );

    is( $targeting_profile->dayPartingTargeting, 'day parting targeting', 'can get day parting targeting' );
    is( $targeting_profile->demographicTargeting, 'demographic targeting', 'can get demographic targeting' );
    is( $targeting_profile->geoTargets, 'geo targets', 'can get geo targets' );
    is( $targeting_profile->networkDistribution, 'network distribution', 'can get network distribution' );

};



1;

