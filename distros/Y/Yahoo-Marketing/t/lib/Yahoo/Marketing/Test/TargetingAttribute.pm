package Yahoo::Marketing::Test::TargetingAttribute;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::TargetingAttribute;

sub test_can_create_targeting_attribute_and_set_all_fields : Test(3) {

    my $targeting_attribute = Yahoo::Marketing::TargetingAttribute->new
                                                                  ->premium( 'premium' )
                                                                  ->targetingAttributeDescriptor( 'targeting attribute descriptor' )
                   ;

    ok( $targeting_attribute );

    is( $targeting_attribute->premium, 'premium', 'can get premium' );
    is( $targeting_attribute->targetingAttributeDescriptor, 'targeting attribute descriptor', 'can get targeting attribute descriptor' );

};



1;

