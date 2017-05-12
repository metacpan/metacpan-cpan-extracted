package Yahoo::Marketing::APT::Test::ClickableVideoActTwo;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::ClickableVideoActTwo;

sub test_can_create_clickable_video_act_two_and_set_all_fields : Test(4) {

    my $clickable_video_act_two = Yahoo::Marketing::APT::ClickableVideoActTwo->new
                                                                        ->flashCreativeID( 'flash creative id' )
                                                                        ->imageCreativeID( 'image creative id' )
                                                                        ->text( 'text' )
                   ;

    ok( $clickable_video_act_two );

    is( $clickable_video_act_two->flashCreativeID, 'flash creative id', 'can get flash creative id' );
    is( $clickable_video_act_two->imageCreativeID, 'image creative id', 'can get image creative id' );
    is( $clickable_video_act_two->text, 'text', 'can get text' );

};



1;

