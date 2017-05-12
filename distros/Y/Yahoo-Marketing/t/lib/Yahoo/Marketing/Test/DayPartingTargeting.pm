package Yahoo::Marketing::Test::DayPartingTargeting;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::DayPartingTargeting;

sub test_can_create_day_parting_targeting_and_set_all_fields : Test(4) {

    my $day_parting_targeting = Yahoo::Marketing::DayPartingTargeting->new
                                                                     ->dayPartingTargets( 'day parting targets' )
                                                                     ->timeZone( 'time zone' )
                                                                     ->userTimeZone( 'user time zone' )
                   ;

    ok( $day_parting_targeting );

    is( $day_parting_targeting->dayPartingTargets, 'day parting targets', 'can get day parting targets' );
    is( $day_parting_targeting->timeZone, 'time zone', 'can get time zone' );
    is( $day_parting_targeting->userTimeZone, 'user time zone', 'can get user time zone' );

};



1;

