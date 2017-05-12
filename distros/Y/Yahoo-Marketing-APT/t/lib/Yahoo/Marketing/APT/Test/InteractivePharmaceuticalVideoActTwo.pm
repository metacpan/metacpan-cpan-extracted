package Yahoo::Marketing::APT::Test::InteractivePharmaceuticalVideoActTwo;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::InteractivePharmaceuticalVideoActTwo;

sub test_can_create_interactive_pharmaceutical_video_act_two_and_set_all_fields : Test(3) {

    my $interactive_pharmaceutical_video_act_two = Yahoo::Marketing::APT::InteractivePharmaceuticalVideoActTwo->new
                                                                                                         ->extendedBannerFlashCreativeID( 'extended banner flash creative id' )
                                                                                                         ->thinBannerFlashCreativeID( 'thin banner flash creative id' )
                   ;

    ok( $interactive_pharmaceutical_video_act_two );

    is( $interactive_pharmaceutical_video_act_two->extendedBannerFlashCreativeID, 'extended banner flash creative id', 'can get extended banner flash creative id' );
    is( $interactive_pharmaceutical_video_act_two->thinBannerFlashCreativeID, 'thin banner flash creative id', 'can get thin banner flash creative id' );

};



1;

