package Yahoo::Marketing::APT::Test::Link;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::Link;

sub test_can_create_link_and_set_all_fields : Test(14) {

    my $link = Yahoo::Marketing::APT::Link->new
                                     ->ID( 'id' )
                                     ->activationTimestamp( '2009-01-06T17:51:55' )
                                     ->buyerDetails( 'buyer details' )
                                     ->createTimestamp( '2009-01-07T17:51:55' )
                                     ->currency( 'currency' )
                                     ->guaranteedDeal( 'guaranteed deal' )
                                     ->lastUpdateTimestamp( '2009-01-08T17:51:55' )
                                     ->nonGuaranteedDeal( 'non guaranteed deal' )
                                     ->paymentTermsInDays( 'payment terms in days' )
                                     ->sellerDetails( 'seller details' )
                                     ->status( 'status' )
                                     ->timezone( 'timezone' )
                                     ->type( 'type' )
                   ;

    ok( $link );

    is( $link->ID, 'id', 'can get id' );
    is( $link->activationTimestamp, '2009-01-06T17:51:55', 'can get 2009-01-06T17:51:55' );
    is( $link->buyerDetails, 'buyer details', 'can get buyer details' );
    is( $link->createTimestamp, '2009-01-07T17:51:55', 'can get 2009-01-07T17:51:55' );
    is( $link->currency, 'currency', 'can get currency' );
    is( $link->guaranteedDeal, 'guaranteed deal', 'can get guaranteed deal' );
    is( $link->lastUpdateTimestamp, '2009-01-08T17:51:55', 'can get 2009-01-08T17:51:55' );
    is( $link->nonGuaranteedDeal, 'non guaranteed deal', 'can get non guaranteed deal' );
    is( $link->paymentTermsInDays, 'payment terms in days', 'can get payment terms in days' );
    is( $link->sellerDetails, 'seller details', 'can get seller details' );
    is( $link->status, 'status', 'can get status' );
    is( $link->timezone, 'timezone', 'can get timezone' );
    is( $link->type, 'type', 'can get type' );

};



1;

