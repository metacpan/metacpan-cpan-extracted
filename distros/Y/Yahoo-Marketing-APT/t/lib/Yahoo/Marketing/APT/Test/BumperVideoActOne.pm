package Yahoo::Marketing::APT::Test::BumperVideoActOne;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::BumperVideoActOne;

sub test_can_create_bumper_video_act_one_and_set_all_fields : Test(4) {

    my $bumper_video_act_one = Yahoo::Marketing::APT::BumperVideoActOne->new
                                                                  ->flashCreativeID( 'flash creative id' )
                                                                  ->imageCreativeID( 'image creative id' )
                                                                  ->videoCreativeID( 'video creative id' )
                   ;

    ok( $bumper_video_act_one );

    is( $bumper_video_act_one->flashCreativeID, 'flash creative id', 'can get flash creative id' );
    is( $bumper_video_act_one->imageCreativeID, 'image creative id', 'can get image creative id' );
    is( $bumper_video_act_one->videoCreativeID, 'video creative id', 'can get video creative id' );

};



1;

