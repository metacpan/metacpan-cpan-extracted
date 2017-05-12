package Yahoo::Marketing::APT::Test::InteractivePharmaceuticalVideoActFour;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::InteractivePharmaceuticalVideoActFour;

sub test_can_create_interactive_pharmaceutical_video_act_four_and_set_all_fields : Test(2) {

    my $interactive_pharmaceutical_video_act_four = Yahoo::Marketing::APT::InteractivePharmaceuticalVideoActFour->new
                                                                                                           ->bannerFlashCreativeID( 'banner flash creative id' )
                   ;

    ok( $interactive_pharmaceutical_video_act_four );

    is( $interactive_pharmaceutical_video_act_four->bannerFlashCreativeID, 'banner flash creative id', 'can get banner flash creative id' );

};



1;

