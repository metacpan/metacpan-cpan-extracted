package Yahoo::Marketing::Test::TargetingPremium;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::TargetingPremium;

sub test_can_create_targeting_premium_and_set_all_fields : Test(3) {

    my $targeting_premium = Yahoo::Marketing::TargetingPremium->new
                                                              ->type( 'type' )
                                                              ->value( 'value' )
                   ;

    ok( $targeting_premium );

    is( $targeting_premium->type, 'type', 'can get type' );
    is( $targeting_premium->value, 'value', 'can get value' );

};



1;

