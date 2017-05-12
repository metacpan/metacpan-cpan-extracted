package Yahoo::Marketing::Test::Carrier;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::Carrier;

sub test_can_create_carrier_and_set_all_fields : Test(4) {

    my $carrier = Yahoo::Marketing::Carrier->new
                                           ->id( 'id' )
                                           ->market( 'market' )
                                           ->name( 'name' )
                   ;

    ok( $carrier );

    is( $carrier->id, 'id', 'can get id' );
    is( $carrier->market, 'market', 'can get market' );
    is( $carrier->name, 'name', 'can get name' );

};



1;

