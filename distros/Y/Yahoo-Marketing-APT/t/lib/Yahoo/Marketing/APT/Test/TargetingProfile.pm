package Yahoo::Marketing::APT::Test::TargetingProfile;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::TargetingProfile;

sub test_can_create_targeting_profile_and_set_all_fields : Test(4) {

    my $targeting_profile = Yahoo::Marketing::APT::TargetingProfile->new
                                                              ->ID( 'id' )
                                                              ->accountID( 'account id' )
                                                              ->targetingAttributes( 'targeting attributes' )
                   ;

    ok( $targeting_profile );

    is( $targeting_profile->ID, 'id', 'can get id' );
    is( $targeting_profile->accountID, 'account id', 'can get account id' );
    is( $targeting_profile->targetingAttributes, 'targeting attributes', 'can get targeting attributes' );

};



1;

