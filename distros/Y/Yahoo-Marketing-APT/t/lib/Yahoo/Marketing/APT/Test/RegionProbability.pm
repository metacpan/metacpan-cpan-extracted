package Yahoo::Marketing::APT::Test::RegionProbability;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::RegionProbability;

sub test_can_create_region_probability_and_set_all_fields : Test(5) {

    my $region_probability = Yahoo::Marketing::APT::RegionProbability->new
                                                                ->extendedName( 'extended name' )
                                                                ->probability( 'probability' )
                                                                ->region( 'region' )
                                                                ->regionParentWOEID( 'region parent woeid' )
                   ;

    ok( $region_probability );

    is( $region_probability->extendedName, 'extended name', 'can get extended name' );
    is( $region_probability->probability, 'probability', 'can get probability' );
    is( $region_probability->region, 'region', 'can get region' );
    is( $region_probability->regionParentWOEID, 'region parent woeid', 'can get region parent woeid' );

};



1;

