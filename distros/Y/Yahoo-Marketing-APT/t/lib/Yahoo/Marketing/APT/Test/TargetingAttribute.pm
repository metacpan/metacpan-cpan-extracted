package Yahoo::Marketing::APT::Test::TargetingAttribute;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::TargetingAttribute;

sub test_can_create_targeting_attribute_and_set_all_fields : Test(5) {

    my $targeting_attribute = Yahoo::Marketing::APT::TargetingAttribute->new
                                                                  ->dayPartingTargeting( 'day parting targeting' )
                                                                  ->isExcluded( 'is excluded' )
                                                                  ->targetingAttributeDescriptor( 'targeting attribute descriptor' )
                                                                  ->yahooPremiumBehavioralSegmentTargetingAttribute( 'yahoo premium behavioral segment targeting attribute' )
                   ;

    ok( $targeting_attribute );

    is( $targeting_attribute->dayPartingTargeting, 'day parting targeting', 'can get day parting targeting' );
    is( $targeting_attribute->isExcluded, 'is excluded', 'can get is excluded' );
    is( $targeting_attribute->targetingAttributeDescriptor, 'targeting attribute descriptor', 'can get targeting attribute descriptor' );
    is( $targeting_attribute->yahooPremiumBehavioralSegmentTargetingAttribute, 'yahoo premium behavioral segment targeting attribute', 'can get yahoo premium behavioral segment targeting attribute' );

};



1;

