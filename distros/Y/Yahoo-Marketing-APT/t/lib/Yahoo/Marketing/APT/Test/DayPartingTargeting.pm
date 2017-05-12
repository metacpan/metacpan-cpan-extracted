package Yahoo::Marketing::APT::Test::DayPartingTargeting;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::DayPartingTargeting;

sub test_can_create_day_parting_targeting_and_set_all_fields : Test(3) {

    my $day_parting_targeting = Yahoo::Marketing::APT::DayPartingTargeting->new
                                                                     ->dayOfTheWeek( 'day of the week' )
                                                                     ->timeRange( 'time range' )
                   ;

    ok( $day_parting_targeting );

    is( $day_parting_targeting->dayOfTheWeek, 'day of the week', 'can get day of the week' );
    is( $day_parting_targeting->timeRange, 'time range', 'can get time range' );

};



1;

