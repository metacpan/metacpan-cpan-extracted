package Yahoo::Marketing::APT::Test::TextFlashVariableValue;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::TextFlashVariableValue;

sub test_can_create_text_flash_variable_value_and_set_all_fields : Test(3) {

    my $text_flash_variable_value = Yahoo::Marketing::APT::TextFlashVariableValue->new
                                                                            ->flashVariableName( 'flash variable name' )
                                                                            ->text( 'text' )
                   ;

    ok( $text_flash_variable_value );

    is( $text_flash_variable_value->flashVariableName, 'flash variable name', 'can get flash variable name' );
    is( $text_flash_variable_value->text, 'text', 'can get text' );

};



1;

