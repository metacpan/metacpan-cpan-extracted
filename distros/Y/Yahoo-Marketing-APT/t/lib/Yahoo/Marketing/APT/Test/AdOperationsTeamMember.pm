package Yahoo::Marketing::APT::Test::AdOperationsTeamMember;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::AdOperationsTeamMember;

sub test_can_create_ad_operations_team_member_and_set_all_fields : Test(3) {

    my $ad_operations_team_member = Yahoo::Marketing::APT::AdOperationsTeamMember->new
                                                                            ->primary( 'primary' )
                                                                            ->userID( 'user id' )
                   ;

    ok( $ad_operations_team_member );

    is( $ad_operations_team_member->primary, 'primary', 'can get primary' );
    is( $ad_operations_team_member->userID, 'user id', 'can get user id' );

};



1;

