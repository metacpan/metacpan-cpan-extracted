package Yahoo::Marketing::APT::Test::TextFlashVariable;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::TextFlashVariable;

sub test_can_create_text_flash_variable_and_set_all_fields : Test(3) {

    my $text_flash_variable = Yahoo::Marketing::APT::TextFlashVariable->new
                                                                 ->defaultText( 'default text' )
                                                                 ->flashVariableName( 'flash variable name' )
                   ;

    ok( $text_flash_variable );

    is( $text_flash_variable->defaultText, 'default text', 'can get default text' );
    is( $text_flash_variable->flashVariableName, 'flash variable name', 'can get flash variable name' );

};



1;

