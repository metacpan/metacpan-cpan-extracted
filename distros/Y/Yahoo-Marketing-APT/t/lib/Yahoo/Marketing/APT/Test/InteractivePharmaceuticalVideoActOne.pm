package Yahoo::Marketing::APT::Test::InteractivePharmaceuticalVideoActOne;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::InteractivePharmaceuticalVideoActOne;

sub test_can_create_interactive_pharmaceutical_video_act_one_and_set_all_fields : Test(2) {

    my $interactive_pharmaceutical_video_act_one = Yahoo::Marketing::APT::InteractivePharmaceuticalVideoActOne->new
                                                                                                         ->bumperFlashCreativeID( 'bumper flash creative id' )
                   ;

    ok( $interactive_pharmaceutical_video_act_one );

    is( $interactive_pharmaceutical_video_act_one->bumperFlashCreativeID, 'bumper flash creative id', 'can get bumper flash creative id' );

};



1;

