package Yahoo::Marketing::Test::ExcludedWord;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::ExcludedWord;

sub test_can_create_excluded_word_and_set_all_fields : Test(9) {

    my $excluded_word = Yahoo::Marketing::ExcludedWord->new
                                                      ->ID( 'id' )
                                                      ->accountID( 'account id' )
                                                      ->adGroupID( 'ad group id' )
                                                      ->campaignID( 'campaign id' )
                                                      ->phraseSearchText( 'phrase search text' )
                                                      ->text( 'text' )
                                                      ->createTimestamp( '2008-01-06T17:51:55' )
                                                      ->deleteTimestamp( '2008-01-07T17:51:55' )
                   ;

    ok( $excluded_word );

    is( $excluded_word->ID, 'id', 'can get id' );
    is( $excluded_word->accountID, 'account id', 'can get account id' );
    is( $excluded_word->adGroupID, 'ad group id', 'can get ad group id' );
    is( $excluded_word->campaignID, 'campaign id', 'can get campaign id' );
    is( $excluded_word->phraseSearchText, 'phrase search text', 'can get phrase search text' );
    is( $excluded_word->text, 'text', 'can get text' );
    is( $excluded_word->createTimestamp, '2008-01-06T17:51:55', 'can get 2008-01-06T17:51:55' );
    is( $excluded_word->deleteTimestamp, '2008-01-07T17:51:55', 'can get 2008-01-07T17:51:55' );

};



1;

