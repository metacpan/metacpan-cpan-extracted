package Yahoo::Marketing::APT::Test::Discount;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::Discount;

sub test_can_create_discount_and_set_all_fields : Test(4) {

    my $discount = Yahoo::Marketing::APT::Discount->new
                                             ->discount( 'discount' )
                                             ->format( 'format' )
                                             ->type( 'type' )
                   ;

    ok( $discount );

    is( $discount->discount, 'discount', 'can get discount' );
    is( $discount->format, 'format', 'can get format' );
    is( $discount->type, 'type', 'can get type' );

};



1;

