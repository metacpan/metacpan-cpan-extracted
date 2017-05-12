package Yahoo::Marketing::Test::AdEditorialReasons;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::AdEditorialReasons;

sub test_can_create_ad_editorial_reasons_and_set_all_fields : Test(10) {

    my $ad_editorial_reasons = Yahoo::Marketing::AdEditorialReasons->new
                                                                   ->adEditorialReasons( 'ad editorial reasons' )
                                                                   ->adID( 'ad id' )
                                                                   ->descriptionEditorialReasons( 'description editorial reasons' )
                                                                   ->displayUrlEditorialReasons( 'display url editorial reasons' )
                                                                   ->shortDescriptionEditorialReason( 'short description editorial reason' )
                                                                   ->titleEditorialReasons( 'title editorial reasons' )
                                                                   ->urlContentEditorialReasons( 'url content editorial reasons' )
                                                                   ->urlEditorialReasons( 'url editorial reasons' )
                                                                   ->urlStringEditorialReasons( 'url string editorial reasons' )
                   ;

    ok( $ad_editorial_reasons );

    is( $ad_editorial_reasons->adEditorialReasons, 'ad editorial reasons', 'can get ad editorial reasons' );
    is( $ad_editorial_reasons->adID, 'ad id', 'can get ad id' );
    is( $ad_editorial_reasons->descriptionEditorialReasons, 'description editorial reasons', 'can get description editorial reasons' );
    is( $ad_editorial_reasons->displayUrlEditorialReasons, 'display url editorial reasons', 'can get display url editorial reasons' );
    is( $ad_editorial_reasons->shortDescriptionEditorialReason, 'short description editorial reason', 'can get short description editorial reason' );
    is( $ad_editorial_reasons->titleEditorialReasons, 'title editorial reasons', 'can get title editorial reasons' );
    is( $ad_editorial_reasons->urlContentEditorialReasons, 'url content editorial reasons', 'can get url content editorial reasons' );
    is( $ad_editorial_reasons->urlEditorialReasons, 'url editorial reasons', 'can get url editorial reasons' );
    is( $ad_editorial_reasons->urlStringEditorialReasons, 'url string editorial reasons', 'can get url string editorial reasons' );

};



1;

