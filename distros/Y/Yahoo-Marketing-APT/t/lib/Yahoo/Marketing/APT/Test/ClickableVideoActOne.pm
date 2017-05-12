package Yahoo::Marketing::APT::Test::ClickableVideoActOne;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::ClickableVideoActOne;

sub test_can_create_clickable_video_act_one_and_set_all_fields : Test(2) {

    my $clickable_video_act_one = Yahoo::Marketing::APT::ClickableVideoActOne->new
                                                                        ->text( 'text' )
                   ;

    ok( $clickable_video_act_one );

    is( $clickable_video_act_one->text, 'text', 'can get text' );

};



1;

