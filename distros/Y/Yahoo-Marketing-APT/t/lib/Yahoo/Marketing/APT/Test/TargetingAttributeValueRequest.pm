package Yahoo::Marketing::APT::Test::TargetingAttributeValueRequest;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::TargetingAttributeValueRequest;

sub test_can_create_targeting_attribute_value_request_and_set_all_fields : Test(4) {

    my $targeting_attribute_value_request = Yahoo::Marketing::APT::TargetingAttributeValueRequest->new
                                                                                            ->serviceContext( 'service context' )
                                                                                            ->sourceOwner( 'source owner' )
                                                                                            ->targetingAttributeType( 'targeting attribute type' )
                   ;

    ok( $targeting_attribute_value_request );

    is( $targeting_attribute_value_request->serviceContext, 'service context', 'can get service context' );
    is( $targeting_attribute_value_request->sourceOwner, 'source owner', 'can get source owner' );
    is( $targeting_attribute_value_request->targetingAttributeType, 'targeting attribute type', 'can get targeting attribute type' );

};



1;

