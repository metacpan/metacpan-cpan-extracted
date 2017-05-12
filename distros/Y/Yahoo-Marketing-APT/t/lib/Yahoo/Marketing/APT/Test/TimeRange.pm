package Yahoo::Marketing::APT::Test::TimeRange;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::TimeRange;

sub test_can_create_time_range_and_set_all_fields : Test(3) {

    my $time_range = Yahoo::Marketing::APT::TimeRange->new
                                                ->endHour( 'end hour' )
                                                ->startHour( 'start hour' )
                   ;

    ok( $time_range );

    is( $time_range->endHour, 'end hour', 'can get end hour' );
    is( $time_range->startHour, 'start hour', 'can get start hour' );

};



1;

