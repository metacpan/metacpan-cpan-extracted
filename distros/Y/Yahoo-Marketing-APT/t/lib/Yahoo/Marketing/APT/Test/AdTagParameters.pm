package Yahoo::Marketing::APT::Test::AdTagParameters;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::AdTagParameters;

sub test_can_create_ad_tag_parameters_and_set_all_fields : Test(4) {

    my $ad_tag_parameters = Yahoo::Marketing::APT::AdTagParameters->new
                                                             ->inventoryIdentifierID( 'inventory identifier id' )
                                                             ->siteID( 'site id' )
                                                             ->targetingAttributeDescriptors( 'targeting attribute descriptors' )
                   ;

    ok( $ad_tag_parameters );

    is( $ad_tag_parameters->inventoryIdentifierID, 'inventory identifier id', 'can get inventory identifier id' );
    is( $ad_tag_parameters->siteID, 'site id', 'can get site id' );
    is( $ad_tag_parameters->targetingAttributeDescriptors, 'targeting attribute descriptors', 'can get targeting attribute descriptors' );

};



1;

