package Yahoo::Marketing::Test::Keyword;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::Keyword;

sub test_can_create_keyword_and_set_all_fields : Test(23) {

    my $keyword = Yahoo::Marketing::Keyword->new
                                           ->ID( 'id' )
                                           ->accountID( 'account id' )
                                           ->adGroupID( 'ad group id' )
                                           ->advancedMatchON( 'advanced match on' )
                                           ->alternateText( 'alternate text' )
                                           ->canonicalSearchText( 'canonical search text' )
                                           ->carrierConfig( 'carrier config' )
                                           ->editorialStatus( 'editorial status' )
                                           ->participatesInMarketplace( 'participates in marketplace' )
                                           ->phraseSearchText( 'phrase search text' )
                                           ->sponsoredSearchMaxBid( 'sponsored search max bid' )
                                           ->status( 'status' )
                                           ->text( 'text' )
                                           ->update( 'update' )
                                           ->url( 'url' )
                                           ->watchON( 'watch on' )
                                           ->createTimestamp( '2008-01-06T17:51:55' )
                                           ->deleteTimestamp( '2008-01-07T17:51:55' )
                                           ->lastUpdateTimestamp( '2008-01-08T17:51:55' )
                                           ->sponsoredSearchBidStatus( 'sponsored search bid status' )
                                           ->sponsoredSearchMaxBidTimestamp( '2008-01-09T17:51:55' )
                                           ->sponsoredSearchMinBid( 'sponsored search min bid' )
                   ;

    ok( $keyword );

    is( $keyword->ID, 'id', 'can get id' );
    is( $keyword->accountID, 'account id', 'can get account id' );
    is( $keyword->adGroupID, 'ad group id', 'can get ad group id' );
    is( $keyword->advancedMatchON, 'advanced match on', 'can get advanced match on' );
    is( $keyword->alternateText, 'alternate text', 'can get alternate text' );
    is( $keyword->canonicalSearchText, 'canonical search text', 'can get canonical search text' );
    is( $keyword->carrierConfig, 'carrier config', 'can get carrier config' );
    is( $keyword->editorialStatus, 'editorial status', 'can get editorial status' );
    is( $keyword->participatesInMarketplace, 'participates in marketplace', 'can get participates in marketplace' );
    is( $keyword->phraseSearchText, 'phrase search text', 'can get phrase search text' );
    is( $keyword->sponsoredSearchMaxBid, 'sponsored search max bid', 'can get sponsored search max bid' );
    is( $keyword->status, 'status', 'can get status' );
    is( $keyword->text, 'text', 'can get text' );
    is( $keyword->update, 'update', 'can get update' );
    is( $keyword->url, 'url', 'can get url' );
    is( $keyword->watchON, 'watch on', 'can get watch on' );
    is( $keyword->createTimestamp, '2008-01-06T17:51:55', 'can get 2008-01-06T17:51:55' );
    is( $keyword->deleteTimestamp, '2008-01-07T17:51:55', 'can get 2008-01-07T17:51:55' );
    is( $keyword->lastUpdateTimestamp, '2008-01-08T17:51:55', 'can get 2008-01-08T17:51:55' );
    is( $keyword->sponsoredSearchBidStatus, 'sponsored search bid status', 'can get sponsored search bid status' );
    is( $keyword->sponsoredSearchMaxBidTimestamp, '2008-01-09T17:51:55', 'can get 2008-01-09T17:51:55' );
    is( $keyword->sponsoredSearchMinBid, 'sponsored search min bid', 'can get sponsored search min bid' );

};



1;

