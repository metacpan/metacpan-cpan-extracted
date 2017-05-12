package Yahoo::Marketing::Test::DayPart;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::DayPart;

sub test_can_create_day_part_and_set_all_fields : Test(4) {

    my $day_part = Yahoo::Marketing::DayPart->new
                                            ->dayOfTheWeek( 'day of the week' )
                                            ->endHourOfDay( 'end hour of day' )
                                            ->startHourOfDay( 'start hour of day' )
                   ;

    ok( $day_part );

    is( $day_part->dayOfTheWeek, 'day of the week', 'can get day of the week' );
    is( $day_part->endHourOfDay, 'end hour of day', 'can get end hour of day' );
    is( $day_part->startHourOfDay, 'start hour of day', 'can get start hour of day' );

};



1;

