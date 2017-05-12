package Yahoo::Marketing::APT::Test::YahooPremiumBehavioralSegmentTargeting;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::YahooPremiumBehavioralSegmentTargeting;

sub test_can_create_yahoo_premium_behavioral_segment_targeting_and_set_all_fields : Test(3) {

    my $yahoo_premium_behavioral_segment_targeting = Yahoo::Marketing::APT::YahooPremiumBehavioralSegmentTargeting->new
                                                                                                             ->targetingAttributeID( 'targeting attribute id' )
                                                                                                             ->yahooPremiumBehavioralSegmentTargetingProgram( 'yahoo premium behavioral segment targeting program' )
                   ;

    ok( $yahoo_premium_behavioral_segment_targeting );

    is( $yahoo_premium_behavioral_segment_targeting->targetingAttributeID, 'targeting attribute id', 'can get targeting attribute id' );
    is( $yahoo_premium_behavioral_segment_targeting->yahooPremiumBehavioralSegmentTargetingProgram, 'yahoo premium behavioral segment targeting program', 'can get yahoo premium behavioral segment targeting program' );

};



1;

