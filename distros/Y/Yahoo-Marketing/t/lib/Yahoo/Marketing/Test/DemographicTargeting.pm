package Yahoo::Marketing::Test::DemographicTargeting;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::DemographicTargeting;

sub test_can_create_demographic_targeting_and_set_all_fields : Test(4) {

    my $demographic_targeting = Yahoo::Marketing::DemographicTargeting->new
                                                                      ->ageTargets( 'age targets' )
                                                                      ->genderTargets( 'gender targets' )
                                                                      ->underAgeFilter( 'under age filter' )
                   ;

    ok( $demographic_targeting );

    is( $demographic_targeting->ageTargets, 'age targets', 'can get age targets' );
    is( $demographic_targeting->genderTargets, 'gender targets', 'can get gender targets' );
    is( $demographic_targeting->underAgeFilter, 'under age filter', 'can get under age filter' );

};



1;

