package Yahoo::Marketing::APT::Test::TargetingAttributeDescriptorWithAny;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::TargetingAttributeDescriptorWithAny;

sub test_can_create_targeting_attribute_descriptor_with_any_and_set_all_fields : Test(4) {

    my $targeting_attribute_descriptor_with_any = Yahoo::Marketing::APT::TargetingAttributeDescriptorWithAny->new
                                                                                                       ->anyTargetingAttribute( 'any targeting attribute' )
                                                                                                       ->targetingAttributeID( 'targeting attribute id' )
                                                                                                       ->targetingAttributeType( 'targeting attribute type' )
                   ;

    ok( $targeting_attribute_descriptor_with_any );

    is( $targeting_attribute_descriptor_with_any->anyTargetingAttribute, 'any targeting attribute', 'can get any targeting attribute' );
    is( $targeting_attribute_descriptor_with_any->targetingAttributeID, 'targeting attribute id', 'can get targeting attribute id' );
    is( $targeting_attribute_descriptor_with_any->targetingAttributeType, 'targeting attribute type', 'can get targeting attribute type' );

};



1;

