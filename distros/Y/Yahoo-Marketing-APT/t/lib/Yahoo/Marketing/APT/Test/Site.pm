package Yahoo::Marketing::APT::Test::Site;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::Site;

sub test_can_create_site_and_set_all_fields : Test(10) {

    my $site = Yahoo::Marketing::APT::Site->new
                                     ->ID( 'id' )
                                     ->accountID( 'account id' )
                                     ->createTimestamp( '2009-01-06T17:51:55' )
                                     ->description( 'description' )
                                     ->language( 'language' )
                                     ->lastUpdateTimestamp( '2009-01-07T17:51:55' )
                                     ->name( 'name' )
                                     ->status( 'status' )
                                     ->url( 'url' )
                   ;

    ok( $site );

    is( $site->ID, 'id', 'can get id' );
    is( $site->accountID, 'account id', 'can get account id' );
    is( $site->createTimestamp, '2009-01-06T17:51:55', 'can get 2009-01-06T17:51:55' );
    is( $site->description, 'description', 'can get description' );
    is( $site->language, 'language', 'can get language' );
    is( $site->lastUpdateTimestamp, '2009-01-07T17:51:55', 'can get 2009-01-07T17:51:55' );
    is( $site->name, 'name', 'can get name' );
    is( $site->status, 'status', 'can get status' );
    is( $site->url, 'url', 'can get url' );

};



1;

