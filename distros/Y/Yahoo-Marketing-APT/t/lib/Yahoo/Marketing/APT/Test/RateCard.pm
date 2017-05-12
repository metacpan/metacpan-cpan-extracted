package Yahoo::Marketing::APT::Test::RateCard;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::RateCard;

sub test_can_create_rate_card_and_set_all_fields : Test(8) {

    my $rate_card = Yahoo::Marketing::APT::RateCard->new
                                              ->ID( 'id' )
                                              ->currency( 'currency' )
                                              ->editable( 'editable' )
                                              ->published( 'published' )
                                              ->siteID( 'site id' )
                                              ->startDate( '2009-01-06T17:51:55' )
                                              ->status( 'status' )
                   ;

    ok( $rate_card );

    is( $rate_card->ID, 'id', 'can get id' );
    is( $rate_card->currency, 'currency', 'can get currency' );
    is( $rate_card->editable, 'editable', 'can get editable' );
    is( $rate_card->published, 'published', 'can get published' );
    is( $rate_card->siteID, 'site id', 'can get site id' );
    is( $rate_card->startDate, '2009-01-06T17:51:55', 'can get 2009-01-06T17:51:55' );
    is( $rate_card->status, 'status', 'can get status' );

};



1;

