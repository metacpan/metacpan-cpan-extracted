package Yahoo::Marketing::APT::Test::DateRange;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::DateRange;

sub test_can_create_date_range_and_set_all_fields : Test(3) {

    my $date_range = Yahoo::Marketing::APT::DateRange->new
                                                ->endDate( '2009-01-06T17:51:55' )
                                                ->startDate( '2009-01-07T17:51:55' )
                   ;

    ok( $date_range );

    is( $date_range->endDate, '2009-01-06T17:51:55', 'can get 2009-01-06T17:51:55' );
    is( $date_range->startDate, '2009-01-07T17:51:55', 'can get 2009-01-07T17:51:55' );

};



1;

