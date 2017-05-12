package Yahoo::Marketing::APT::Test::OverlayVideoActTwo;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::OverlayVideoActTwo;

sub test_can_create_overlay_video_act_two_and_set_all_fields : Test(4) {

    my $overlay_video_act_two = Yahoo::Marketing::APT::OverlayVideoActTwo->new
                                                                    ->flashCreativeID( 'flash creative id' )
                                                                    ->imageCreativeID( 'image creative id' )
                                                                    ->text( 'text' )
                   ;

    ok( $overlay_video_act_two );

    is( $overlay_video_act_two->flashCreativeID, 'flash creative id', 'can get flash creative id' );
    is( $overlay_video_act_two->imageCreativeID, 'image creative id', 'can get image creative id' );
    is( $overlay_video_act_two->text, 'text', 'can get text' );

};



1;

