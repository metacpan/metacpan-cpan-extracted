package Yahoo::Marketing::APT::Test::AttributeSetting;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::AttributeSetting;

sub test_can_create_attribute_setting_and_set_all_fields : Test(3) {

    my $attribute_setting = Yahoo::Marketing::APT::AttributeSetting->new
                                                              ->attributeID( 'attribute id' )
                                                              ->isExcluded( 'is excluded' )
                   ;

    ok( $attribute_setting );

    is( $attribute_setting->attributeID, 'attribute id', 'can get attribute id' );
    is( $attribute_setting->isExcluded, 'is excluded', 'can get is excluded' );

};



1;

