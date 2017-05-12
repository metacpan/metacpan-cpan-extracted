package Yahoo::Marketing::APT::Test::ROITarget;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::ROITarget;

sub test_can_create_r_oitarget_and_set_all_fields : Test(3) {

    my $r_oitarget = Yahoo::Marketing::APT::ROITarget->new
                                                ->optimizationMetric( 'optimization metric' )
                                                ->value( 'value' )
                   ;

    ok( $r_oitarget );

    is( $r_oitarget->optimizationMetric, 'optimization metric', 'can get optimization metric' );
    is( $r_oitarget->value, 'value', 'can get value' );

};



1;

