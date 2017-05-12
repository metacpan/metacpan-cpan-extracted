package Yahoo::Marketing::APT::Test::TargetingAttributeDetails;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::TargetingAttributeDetails;

sub test_can_create_targeting_attribute_details_and_set_all_fields : Test(4) {

    my $targeting_attribute_details = Yahoo::Marketing::APT::TargetingAttributeDetails->new
                                                                                 ->isExcluded( 'is excluded' )
                                                                                 ->targetingAttributeID( 'targeting attribute id' )
                                                                                 ->targetingAttributeValue( 'targeting attribute value' )
                   ;

    ok( $targeting_attribute_details );

    is( $targeting_attribute_details->isExcluded, 'is excluded', 'can get is excluded' );
    is( $targeting_attribute_details->targetingAttributeID, 'targeting attribute id', 'can get targeting attribute id' );
    is( $targeting_attribute_details->targetingAttributeValue, 'targeting attribute value', 'can get targeting attribute value' );

};



1;

