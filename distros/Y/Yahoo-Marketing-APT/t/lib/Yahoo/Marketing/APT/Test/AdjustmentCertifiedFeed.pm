package Yahoo::Marketing::APT::Test::AdjustmentCertifiedFeed;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::AdjustmentCertifiedFeed;

sub test_can_create_adjustment_certified_feed_and_set_all_fields : Test(10) {

    my $adjustment_certified_feed = Yahoo::Marketing::APT::AdjustmentCertifiedFeed->new
                                                                             ->ID( 'id' )
                                                                             ->accountID( 'account id' )
                                                                             ->certificationTimestamp( '2009-01-06T17:51:55' )
                                                                             ->certifiedByUserID( 'certified by user id' )
                                                                             ->certifiedByUserName( 'certified by user name' )
                                                                             ->certifiedForMonth( 'certified for month' )
                                                                             ->createTimestamp( '2009-01-07T17:51:55' )
                                                                             ->downloadURL( 'download url' )
                                                                             ->fileName( 'file name' )
                   ;

    ok( $adjustment_certified_feed );

    is( $adjustment_certified_feed->ID, 'id', 'can get id' );
    is( $adjustment_certified_feed->accountID, 'account id', 'can get account id' );
    is( $adjustment_certified_feed->certificationTimestamp, '2009-01-06T17:51:55', 'can get 2009-01-06T17:51:55' );
    is( $adjustment_certified_feed->certifiedByUserID, 'certified by user id', 'can get certified by user id' );
    is( $adjustment_certified_feed->certifiedByUserName, 'certified by user name', 'can get certified by user name' );
    is( $adjustment_certified_feed->certifiedForMonth, 'certified for month', 'can get certified for month' );
    is( $adjustment_certified_feed->createTimestamp, '2009-01-07T17:51:55', 'can get 2009-01-07T17:51:55' );
    is( $adjustment_certified_feed->downloadURL, 'download url', 'can get download url' );
    is( $adjustment_certified_feed->fileName, 'file name', 'can get file name' );

};



1;

