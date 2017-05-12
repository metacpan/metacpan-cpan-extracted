package Yahoo::Marketing::APT::Test::TargetingAttributeValue;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::TargetingAttributeValue;

sub test_can_create_targeting_attribute_value_and_set_all_fields : Test(12) {

    my $targeting_attribute_value = Yahoo::Marketing::APT::TargetingAttributeValue->new
                                                                             ->ID( 'id' )
                                                                             ->accountID( 'account id' )
                                                                             ->customTargetingAttributeOwnership( 'custom targeting attribute ownership' )
                                                                             ->description( 'description' )
                                                                             ->isActive( 'is active' )
                                                                             ->name( 'name' )
                                                                             ->origin( 'origin' )
                                                                             ->parentID( 'parent id' )
                                                                             ->parentType( 'parent type' )
                                                                             ->sourceOwner( 'source owner' )
                                                                             ->type( 'type' )
                   ;

    ok( $targeting_attribute_value );

    is( $targeting_attribute_value->ID, 'id', 'can get id' );
    is( $targeting_attribute_value->accountID, 'account id', 'can get account id' );
    is( $targeting_attribute_value->customTargetingAttributeOwnership, 'custom targeting attribute ownership', 'can get custom targeting attribute ownership' );
    is( $targeting_attribute_value->description, 'description', 'can get description' );
    is( $targeting_attribute_value->isActive, 'is active', 'can get is active' );
    is( $targeting_attribute_value->name, 'name', 'can get name' );
    is( $targeting_attribute_value->origin, 'origin', 'can get origin' );
    is( $targeting_attribute_value->parentID, 'parent id', 'can get parent id' );
    is( $targeting_attribute_value->parentType, 'parent type', 'can get parent type' );
    is( $targeting_attribute_value->sourceOwner, 'source owner', 'can get source owner' );
    is( $targeting_attribute_value->type, 'type', 'can get type' );

};



1;

