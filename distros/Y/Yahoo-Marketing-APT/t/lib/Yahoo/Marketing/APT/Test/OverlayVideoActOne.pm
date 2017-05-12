package Yahoo::Marketing::APT::Test::OverlayVideoActOne;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::OverlayVideoActOne;

sub test_can_create_overlay_video_act_one_and_set_all_fields : Test(2) {

    my $overlay_video_act_one = Yahoo::Marketing::APT::OverlayVideoActOne->new
                                                                    ->text( 'text' )
                   ;

    ok( $overlay_video_act_one );

    is( $overlay_video_act_one->text, 'text', 'can get text' );

};



1;

