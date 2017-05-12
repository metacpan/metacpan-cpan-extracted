package Yahoo::Marketing::APT::Test::ImageFlashVariableValue;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::ImageFlashVariableValue;

sub test_can_create_image_flash_variable_value_and_set_all_fields : Test(3) {

    my $image_flash_variable_value = Yahoo::Marketing::APT::ImageFlashVariableValue->new
                                                                              ->flashVariableName( 'flash variable name' )
                                                                              ->imageCreativeID( 'image creative id' )
                   ;

    ok( $image_flash_variable_value );

    is( $image_flash_variable_value->flashVariableName, 'flash variable name', 'can get flash variable name' );
    is( $image_flash_variable_value->imageCreativeID, 'image creative id', 'can get image creative id' );

};



1;

