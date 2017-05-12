package Yahoo::Marketing::APT::Test::TimePeriod;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::TimePeriod;

sub test_can_create_time_period_and_set_all_fields : Test(3) {

    my $time_period = Yahoo::Marketing::APT::TimePeriod->new
                                                  ->period( 'period' )
                                                  ->type( 'type' )
                   ;

    ok( $time_period );

    is( $time_period->period, 'period', 'can get period' );
    is( $time_period->type, 'type', 'can get type' );

};



1;

