package Yahoo::Marketing::APT::Test::CustomizableFlashTemplate;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::CustomizableFlashTemplate;

sub test_can_create_customizable_flash_template_and_set_all_fields : Test(15) {

    my $customizable_flash_template = Yahoo::Marketing::APT::CustomizableFlashTemplate->new
                                                                                 ->ID( 'id' )
                                                                                 ->accountID( 'account id' )
                                                                                 ->adFormat( 'ad format' )
                                                                                 ->adSizeID( 'ad size id' )
                                                                                 ->createTimestamp( '2009-01-06T17:51:55' )
                                                                                 ->customizableFlashCreativeID( 'customizable flash creative id' )
                                                                                 ->folderID( 'folder id' )
                                                                                 ->height( 'height' )
                                                                                 ->imageFlashVariableConstraints( 'image flash variable constraints' )
                                                                                 ->lastUpdateTimestamp( '2009-01-07T17:51:55' )
                                                                                 ->name( 'name' )
                                                                                 ->status( 'status' )
                                                                                 ->textFlashVariableConstraints( 'text flash variable constraints' )
                                                                                 ->width( 'width' )
                   ;

    ok( $customizable_flash_template );

    is( $customizable_flash_template->ID, 'id', 'can get id' );
    is( $customizable_flash_template->accountID, 'account id', 'can get account id' );
    is( $customizable_flash_template->adFormat, 'ad format', 'can get ad format' );
    is( $customizable_flash_template->adSizeID, 'ad size id', 'can get ad size id' );
    is( $customizable_flash_template->createTimestamp, '2009-01-06T17:51:55', 'can get 2009-01-06T17:51:55' );
    is( $customizable_flash_template->customizableFlashCreativeID, 'customizable flash creative id', 'can get customizable flash creative id' );
    is( $customizable_flash_template->folderID, 'folder id', 'can get folder id' );
    is( $customizable_flash_template->height, 'height', 'can get height' );
    is( $customizable_flash_template->imageFlashVariableConstraints, 'image flash variable constraints', 'can get image flash variable constraints' );
    is( $customizable_flash_template->lastUpdateTimestamp, '2009-01-07T17:51:55', 'can get 2009-01-07T17:51:55' );
    is( $customizable_flash_template->name, 'name', 'can get name' );
    is( $customizable_flash_template->status, 'status', 'can get status' );
    is( $customizable_flash_template->textFlashVariableConstraints, 'text flash variable constraints', 'can get text flash variable constraints' );
    is( $customizable_flash_template->width, 'width', 'can get width' );

};



1;

