package Yahoo::Marketing::APT::Test::CustomContentCategory;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::CustomContentCategory;

sub test_can_create_custom_content_category_and_set_all_fields : Test(8) {

    my $custom_content_category = Yahoo::Marketing::APT::CustomContentCategory->new
                                                                         ->ID( 'id' )
                                                                         ->createTimestamp( '2009-01-06T17:51:55' )
                                                                         ->description( 'description' )
                                                                         ->lastUpdateTimestamp( '2009-01-07T17:51:55' )
                                                                         ->name( 'name' )
                                                                         ->siteID( 'site id' )
                                                                         ->targetingAttributeType( 'targeting attribute type' )
                   ;

    ok( $custom_content_category );

    is( $custom_content_category->ID, 'id', 'can get id' );
    is( $custom_content_category->createTimestamp, '2009-01-06T17:51:55', 'can get 2009-01-06T17:51:55' );
    is( $custom_content_category->description, 'description', 'can get description' );
    is( $custom_content_category->lastUpdateTimestamp, '2009-01-07T17:51:55', 'can get 2009-01-07T17:51:55' );
    is( $custom_content_category->name, 'name', 'can get name' );
    is( $custom_content_category->siteID, 'site id', 'can get site id' );
    is( $custom_content_category->targetingAttributeType, 'targeting attribute type', 'can get targeting attribute type' );

};



1;

