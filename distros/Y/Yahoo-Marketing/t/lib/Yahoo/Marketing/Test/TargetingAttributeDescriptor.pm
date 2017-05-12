package Yahoo::Marketing::Test::TargetingAttributeDescriptor;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::TargetingAttributeDescriptor;

sub test_can_create_targeting_attribute_descriptor_and_set_all_fields : Test(3) {

    my $targeting_attribute_descriptor = Yahoo::Marketing::TargetingAttributeDescriptor->new
                                                                                       ->targetingAttributeID( 'targeting attribute id' )
                                                                                       ->targetingType( 'targeting type' )
                   ;

    ok( $targeting_attribute_descriptor );

    is( $targeting_attribute_descriptor->targetingAttributeID, 'targeting attribute id', 'can get targeting attribute id' );
    is( $targeting_attribute_descriptor->targetingType, 'targeting type', 'can get targeting type' );

};



1;

