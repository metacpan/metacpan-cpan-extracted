package Yahoo::Marketing::APT::Test::TextFlashVariableConstraints;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::TextFlashVariableConstraints;

sub test_can_create_text_flash_variable_constraints_and_set_all_fields : Test(5) {

    my $text_flash_variable_constraints = Yahoo::Marketing::APT::TextFlashVariableConstraints->new
                                                                                        ->defaultText( 'default text' )
                                                                                        ->editable( 'editable' )
                                                                                        ->flashVariableName( 'flash variable name' )
                                                                                        ->hidden( 'hidden' )
                   ;

    ok( $text_flash_variable_constraints );

    is( $text_flash_variable_constraints->defaultText, 'default text', 'can get default text' );
    is( $text_flash_variable_constraints->editable, 'editable', 'can get editable' );
    is( $text_flash_variable_constraints->flashVariableName, 'flash variable name', 'can get flash variable name' );
    is( $text_flash_variable_constraints->hidden, 'hidden', 'can get hidden' );

};



1;

