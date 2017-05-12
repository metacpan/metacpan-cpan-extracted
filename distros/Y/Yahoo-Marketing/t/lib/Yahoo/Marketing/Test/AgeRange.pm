package Yahoo::Marketing::Test::AgeRange;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::AgeRange;

sub test_can_create_age_range_and_set_all_fields : Test(3) {

    my $age_range = Yahoo::Marketing::AgeRange->new
                                              ->maxAge( 'max age' )
                                              ->minAge( 'min age' )
                   ;

    ok( $age_range );

    is( $age_range->maxAge, 'max age', 'can get max age' );
    is( $age_range->minAge, 'min age', 'can get min age' );

};



1;

