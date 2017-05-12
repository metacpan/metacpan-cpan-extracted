package Yahoo::Marketing::APT::Test::AgencyContract;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::AgencyContract;

sub test_can_create_agency_contract_and_set_all_fields : Test(14) {

    my $agency_contract = Yahoo::Marketing::APT::AgencyContract->new
                                                          ->ID( 'id' )
                                                          ->activationTimestamp( '2009-01-06T17:51:55' )
                                                          ->agencyAccountID( 'agency account id' )
                                                          ->agencyRevenueSharePercentage( 'agency revenue share percentage' )
                                                          ->clientAccountID( 'client account id' )
                                                          ->clientRevenueSharePercentage( 'client revenue share percentage' )
                                                          ->createTimestamp( '2009-01-07T17:51:55' )
                                                          ->endDate( '2009-01-08T17:51:55' )
                                                          ->lastUpdateTimestamp( '2009-01-09T17:51:55' )
                                                          ->linkID( 'link id' )
                                                          ->name( 'name' )
                                                          ->startDate( '2009-01-10T17:51:55' )
                                                          ->status( 'status' )
                   ;

    ok( $agency_contract );

    is( $agency_contract->ID, 'id', 'can get id' );
    is( $agency_contract->activationTimestamp, '2009-01-06T17:51:55', 'can get 2009-01-06T17:51:55' );
    is( $agency_contract->agencyAccountID, 'agency account id', 'can get agency account id' );
    is( $agency_contract->agencyRevenueSharePercentage, 'agency revenue share percentage', 'can get agency revenue share percentage' );
    is( $agency_contract->clientAccountID, 'client account id', 'can get client account id' );
    is( $agency_contract->clientRevenueSharePercentage, 'client revenue share percentage', 'can get client revenue share percentage' );
    is( $agency_contract->createTimestamp, '2009-01-07T17:51:55', 'can get 2009-01-07T17:51:55' );
    is( $agency_contract->endDate, '2009-01-08T17:51:55', 'can get 2009-01-08T17:51:55' );
    is( $agency_contract->lastUpdateTimestamp, '2009-01-09T17:51:55', 'can get 2009-01-09T17:51:55' );
    is( $agency_contract->linkID, 'link id', 'can get link id' );
    is( $agency_contract->name, 'name', 'can get name' );
    is( $agency_contract->startDate, '2009-01-10T17:51:55', 'can get 2009-01-10T17:51:55' );
    is( $agency_contract->status, 'status', 'can get status' );

};



1;

