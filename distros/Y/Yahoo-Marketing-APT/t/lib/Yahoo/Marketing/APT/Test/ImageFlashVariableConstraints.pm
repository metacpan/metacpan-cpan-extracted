package Yahoo::Marketing::APT::Test::ImageFlashVariableConstraints;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::ImageFlashVariableConstraints;

sub test_can_create_image_flash_variable_constraints_and_set_all_fields : Test(5) {

    my $image_flash_variable_constraints = Yahoo::Marketing::APT::ImageFlashVariableConstraints->new
                                                                                          ->defaultImageCreativeID( 'default image creative id' )
                                                                                          ->editable( 'editable' )
                                                                                          ->flashVariableName( 'flash variable name' )
                                                                                          ->hidden( 'hidden' )
                   ;

    ok( $image_flash_variable_constraints );

    is( $image_flash_variable_constraints->defaultImageCreativeID, 'default image creative id', 'can get default image creative id' );
    is( $image_flash_variable_constraints->editable, 'editable', 'can get editable' );
    is( $image_flash_variable_constraints->flashVariableName, 'flash variable name', 'can get flash variable name' );
    is( $image_flash_variable_constraints->hidden, 'hidden', 'can get hidden' );

};



1;

