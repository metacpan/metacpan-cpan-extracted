package Yahoo::Marketing::Test::Address;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::Address;

sub test_can_create_address_and_set_all_fields : Test(11) {

    my $address = Yahoo::Marketing::Address->new
                                           ->address1( 'address1' )
                                           ->address2( 'address2' )
                                           ->address3( 'address3' )
                                           ->city( 'city' )
                                           ->country( 'country' )
                                           ->county( 'county' )
                                           ->postalCode( 'postal code' )
                                           ->province( 'province' )
                                           ->state( 'state' )
                                           ->todofuken( 'todofuken' )
                   ;

    ok( $address );

    is( $address->address1, 'address1', 'can get address1' );
    is( $address->address2, 'address2', 'can get address2' );
    is( $address->address3, 'address3', 'can get address3' );
    is( $address->city, 'city', 'can get city' );
    is( $address->country, 'country', 'can get country' );
    is( $address->county, 'county', 'can get county' );
    is( $address->postalCode, 'postal code', 'can get postal code' );
    is( $address->province, 'province', 'can get province' );
    is( $address->state, 'state', 'can get state' );
    is( $address->todofuken, 'todofuken', 'can get todofuken' );

};



1;

