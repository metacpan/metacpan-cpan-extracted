package Yahoo::Marketing::APT::Test::AudienceSharingRule;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::AudienceSharingRule;

sub test_can_create_audience_sharing_rule_and_set_all_fields : Test(7) {

    my $audience_sharing_rule = Yahoo::Marketing::APT::AudienceSharingRule->new
                                                                     ->ID( 'id' )
                                                                     ->accountID( 'account id' )
                                                                     ->createTimestamp( '2009-01-06T17:51:55' )
                                                                     ->lastUpdateTimestamp( '2009-01-07T17:51:55' )
                                                                     ->name( 'name' )
                                                                     ->targetingAttributeDescriptors( 'targeting attribute descriptors' )
                   ;

    ok( $audience_sharing_rule );

    is( $audience_sharing_rule->ID, 'id', 'can get id' );
    is( $audience_sharing_rule->accountID, 'account id', 'can get account id' );
    is( $audience_sharing_rule->createTimestamp, '2009-01-06T17:51:55', 'can get 2009-01-06T17:51:55' );
    is( $audience_sharing_rule->lastUpdateTimestamp, '2009-01-07T17:51:55', 'can get 2009-01-07T17:51:55' );
    is( $audience_sharing_rule->name, 'name', 'can get name' );
    is( $audience_sharing_rule->targetingAttributeDescriptors, 'targeting attribute descriptors', 'can get targeting attribute descriptors' );

};



1;

