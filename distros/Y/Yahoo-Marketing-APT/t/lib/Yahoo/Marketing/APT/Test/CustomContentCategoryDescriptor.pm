package Yahoo::Marketing::APT::Test::CustomContentCategoryDescriptor;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::CustomContentCategoryDescriptor;

sub test_can_create_custom_content_category_descriptor_and_set_all_fields : Test(4) {

    my $custom_content_category_descriptor = Yahoo::Marketing::APT::CustomContentCategoryDescriptor->new
                                                                                              ->ID( 'id' )
                                                                                              ->name( 'name' )
                                                                                              ->siteID( 'site id' )
                   ;

    ok( $custom_content_category_descriptor );

    is( $custom_content_category_descriptor->ID, 'id', 'can get id' );
    is( $custom_content_category_descriptor->name, 'name', 'can get name' );
    is( $custom_content_category_descriptor->siteID, 'site id', 'can get site id' );

};



1;

