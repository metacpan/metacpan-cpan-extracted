package Yahoo::Marketing::APT::Test::OrderAgency;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::OrderAgency;

sub test_can_create_order_agency_and_set_all_fields : Test(3) {

    my $order_agency = Yahoo::Marketing::APT::OrderAgency->new
                                                    ->accountID( 'account id' )
                                                    ->billToCompany( 'bill to company' )
                   ;

    ok( $order_agency );

    is( $order_agency->accountID, 'account id', 'can get account id' );
    is( $order_agency->billToCompany, 'bill to company', 'can get bill to company' );

};



1;

