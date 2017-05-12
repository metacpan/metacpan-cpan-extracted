package Yahoo::Marketing::APT::Test::ImageFlashVariable;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::ImageFlashVariable;

sub test_can_create_image_flash_variable_and_set_all_fields : Test(3) {

    my $image_flash_variable = Yahoo::Marketing::APT::ImageFlashVariable->new
                                                                   ->defaultImageCreativeID( 'default image creative id' )
                                                                   ->flashVariableName( 'flash variable name' )
                   ;

    ok( $image_flash_variable );

    is( $image_flash_variable->defaultImageCreativeID, 'default image creative id', 'can get default image creative id' );
    is( $image_flash_variable->flashVariableName, 'flash variable name', 'can get flash variable name' );

};



1;

