package Yahoo::Marketing::APT::Test::CustomSection;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::CustomSection;

sub test_can_create_custom_section_and_set_all_fields : Test(8) {

    my $custom_section = Yahoo::Marketing::APT::CustomSection->new
                                                        ->ID( 'id' )
                                                        ->createTimestamp( '2009-01-06T17:51:55' )
                                                        ->description( 'description' )
                                                        ->lastUpdateTimestamp( '2009-01-07T17:51:55' )
                                                        ->name( 'name' )
                                                        ->siteID( 'site id' )
                                                        ->targetingAttributeType( 'targeting attribute type' )
                   ;

    ok( $custom_section );

    is( $custom_section->ID, 'id', 'can get id' );
    is( $custom_section->createTimestamp, '2009-01-06T17:51:55', 'can get 2009-01-06T17:51:55' );
    is( $custom_section->description, 'description', 'can get description' );
    is( $custom_section->lastUpdateTimestamp, '2009-01-07T17:51:55', 'can get 2009-01-07T17:51:55' );
    is( $custom_section->name, 'name', 'can get name' );
    is( $custom_section->siteID, 'site id', 'can get site id' );
    is( $custom_section->targetingAttributeType, 'targeting attribute type', 'can get targeting attribute type' );

};



1;

