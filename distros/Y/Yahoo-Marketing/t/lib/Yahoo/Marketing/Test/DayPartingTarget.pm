package Yahoo::Marketing::Test::DayPartingTarget;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::DayPartingTarget;

sub test_can_create_day_parting_target_and_set_all_fields : Test(3) {

    my $day_parting_target = Yahoo::Marketing::DayPartingTarget->new
                                                               ->dayPart( 'day part' )
                                                               ->premium( 'premium' )
                   ;

    ok( $day_parting_target );

    is( $day_parting_target->dayPart, 'day part', 'can get day part' );
    is( $day_parting_target->premium, 'premium', 'can get premium' );

};



1;

