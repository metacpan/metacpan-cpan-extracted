package Yahoo::Marketing::Test::RangeValueType;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::RangeValueType;

sub test_can_create_range_value_type_and_set_all_fields : Test(3) {

    my $range_value_type = Yahoo::Marketing::RangeValueType->new
                                                           ->bucketID( 'bucket id' )
                                                           ->rangeName( 'range name' )
                   ;

    ok( $range_value_type );

    is( $range_value_type->bucketID, 'bucket id', 'can get bucket id' );
    is( $range_value_type->rangeName, 'range name', 'can get range name' );

};



1;

