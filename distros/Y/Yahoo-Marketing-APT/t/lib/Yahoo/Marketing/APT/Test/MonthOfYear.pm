package Yahoo::Marketing::APT::Test::MonthOfYear;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::MonthOfYear;

sub test_can_create_month_of_year_and_set_all_fields : Test(3) {

    my $month_of_year = Yahoo::Marketing::APT::MonthOfYear->new
                                                     ->month( 'month' )
                                                     ->year( 'year' )
                   ;

    ok( $month_of_year );

    is( $month_of_year->month, 'month', 'can get month' );
    is( $month_of_year->year, 'year', 'can get year' );

};



1;

