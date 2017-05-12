package Yahoo::Marketing::Test::ExcludedWordsService;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/ Yahoo::Marketing::Test::PostTest /;
use Test::More;
use Module::Build;

use Yahoo::Marketing::ExcludedWordsService;
use Yahoo::Marketing::ExcludedWord;

sub SKIP_CLASS {
    my $self = shift;
    # 'not running post tests' is a true value
    return 'not running post tests' unless $self->run_post_tests;
    return;
}

sub test_add_excluded_words_to_ad_group : Test(9) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::ExcludedWordsService->new->parse_config( section => $self->section );

    my $ad_group = $self->common_test_data( 'test_ad_group' );

    my $excluded_word1 = Yahoo::Marketing::ExcludedWord->new
                                                       ->adGroupID( $ad_group->ID )
                                                       ->text( 'some excluded text 1' )
                         ;
    my $excluded_word2 = Yahoo::Marketing::ExcludedWord->new
                                                       ->adGroupID( $ad_group->ID )
                                                       ->text( 'some excluded text 2' )
                         ;

    my @response = $ysm_ws->addExcludedWordsToAdGroup(
        excludedWords => [ $excluded_word1, $excluded_word2 ],
    );

    ok( @response );
    foreach ( @response ) {
        is( $_->operationSucceeded, 'true' );
    }

    like( $response[0]->excludedWord->ID, qr/^\d+$/, 'ID like numberic' );
    like( $response[1]->excludedWord->ID, qr/^\d+$/, 'ID like numberic' );

    # seems returned excluded words are in the same order as in parameters.
    is( $response[0]->excludedWord->adGroupID, $ad_group->ID, 'adGroupID is right' );
    is( $response[1]->excludedWord->adGroupID, $ad_group->ID, 'adGroupID is right' );
    is( $response[0]->excludedWord->text, $excluded_word1->text, 'text is right' );
    is( $response[1]->excludedWord->text, $excluded_word2->text, 'text is right' );

}


sub test_add_excluded_words_to_account : Test(9) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::ExcludedWordsService->new->parse_config( section => $self->section );

    my $excluded_word1 = Yahoo::Marketing::ExcludedWord->new
                                                       ->accountID( $ysm_ws->account )
                                                       ->text( 'some excluded text 3' )
                         ;
    my $excluded_word2 = Yahoo::Marketing::ExcludedWord->new
                                                       ->accountID( $ysm_ws->account )
                                                       ->text( 'some excluded text 4' )
                         ;

    my @response = $ysm_ws->addExcludedWordsToAccount(
        excludedWords => [ $excluded_word1, $excluded_word2, ],
    );

    ok( @response );
    foreach ( @response ) {
        is( $_->operationSucceeded, 'true' );
    }

    like( $response[0]->excludedWord->ID, qr/^\d+$/, 'ID like numberic' );
    like( $response[1]->excludedWord->ID, qr/^\d+$/, 'ID like numberic' );

    is( $response[0]->excludedWord->accountID, $ysm_ws->account, 'accountID is right' );
    is( $response[1]->excludedWord->accountID, $ysm_ws->account, 'accountID is right' );
    is( $response[0]->excludedWord->text, $excluded_word1->text, 'text is right' );
    is( $response[1]->excludedWord->text, $excluded_word2->text, 'text is right' );

}


sub test_add_excluded_word_to_ad_group : Test(5) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::ExcludedWordsService->new->parse_config( section => $self->section );

    my $ad_group = $self->common_test_data( 'test_ad_group' );

    my $excluded_word = Yahoo::Marketing::ExcludedWord->new
                                                      ->adGroupID( $ad_group->ID )
                                                      ->text( 'some excluded text 5' )
                        ;

    my $response = $ysm_ws->addExcludedWordToAdGroup(
        excludedWord => $excluded_word,
    );

    ok( $response );
    is( $response->operationSucceeded, 'true' );
    like( $response->excludedWord->ID, qr/^\d+$/, 'ID like numberic' );
    is( $response->excludedWord->adGroupID, $ad_group->ID, 'adGroupID is right' );
    is( $response->excludedWord->text, $excluded_word->text, 'text is right' );

}


sub test_add_excluded_word_to_account : Test(5) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::ExcludedWordsService->new->parse_config( section => $self->section );

    my $excluded_word = Yahoo::Marketing::ExcludedWord->new
        ->accountID( $ysm_ws->account )
        ->text( 'some excluded text 6' );

    my $response = $ysm_ws->addExcludedWordToAccount(
        excludedWord => $excluded_word,
    );

    ok( $response );
    is( $response->operationSucceeded, 'true' );
    like( $response->excludedWord->ID, qr/^\d+$/, 'ID like numberic' );
    is( $response->excludedWord->accountID, $ysm_ws->account, 'accountID is right' );
    is( $response->excludedWord->text, $excluded_word->text, 'text is right' );

}


sub test_get_excluded_word : Test(4) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::ExcludedWordsService->new->parse_config( section => $self->section );

    my $ad_group = $self->common_test_data( 'test_ad_group' );

    my $excluded_word = Yahoo::Marketing::ExcludedWord->new
        ->adGroupID( $ad_group->ID )
        ->text( 'some excluded text 7' );

    my $returned_excluded_word = $ysm_ws->addExcludedWordToAdGroup(
        excludedWord => $excluded_word,
    )->excludedWord;

    ok( $returned_excluded_word );

    my $fetched_excluded_word = $ysm_ws->getExcludedWord(
                                             excludedWordID => $returned_excluded_word->ID,
                                         );
    ok( $fetched_excluded_word );
    is( $fetched_excluded_word->ID, $returned_excluded_word->ID, 'ID is right' );
    is( $fetched_excluded_word->text, $returned_excluded_word->text, 'text is right' );

}


sub test_get_excluded_words : Test(6) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::ExcludedWordsService->new->parse_config( section => $self->section );

    my $ad_group = $self->common_test_data( 'test_ad_group' );

    my $excluded_word1 = Yahoo::Marketing::ExcludedWord->new
                                                       ->adGroupID( $ad_group->ID )
                                                       ->text( 'some excluded text 8' )
                         ;
    my $excluded_word2 = Yahoo::Marketing::ExcludedWord->new
                                                       ->adGroupID( $ad_group->ID )
                                                       ->text( 'some excluded text 9' )
                         ;

    my @returned_excluded_words = $ysm_ws->addExcludedWordsToAdGroup(
                                               excludedWords => [ $excluded_word1, $excluded_word2 ],
                                           );

    ok( @returned_excluded_words );

    my @fetched_excluded_words = $ysm_ws->getExcludedWords(
                                              excludedWordIDs => [ $returned_excluded_words[0]->excludedWord->ID,
                                                                   $returned_excluded_words[1]->excludedWord->ID,
                                                                 ]
                                          );

    ok( @fetched_excluded_words );

    is( $fetched_excluded_words[0]->ID, $returned_excluded_words[0]->excludedWord->ID, 'ID is right' );
    is( $fetched_excluded_words[1]->ID, $returned_excluded_words[1]->excludedWord->ID, 'ID is right' );
    is( $fetched_excluded_words[0]->text, $returned_excluded_words[0]->excludedWord->text, 'text is right' );
    is( $fetched_excluded_words[1]->text, $returned_excluded_words[1]->excludedWord->text, 'text is right' );
}


sub test_get_excluded_words_by_ad_group_id : Test(3) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::ExcludedWordsService->new->parse_config( section => $self->section );

    my $ad_group = $self->common_test_data( 'test_ad_group' );

    my $excluded_word = Yahoo::Marketing::ExcludedWord->new
                                                      ->adGroupID( $ad_group->ID )
                                                      ->text( 'some excluded text 10' )
                        ;

    my $returned_excluded_word = $ysm_ws->addExcludedWordToAdGroup(
                                              excludedWord => $excluded_word,
                                          )->excludedWord;

    ok( $returned_excluded_word );

    my @fetched_excluded_words = $ysm_ws->getExcludedWordsByAdGroupID(
                                              adGroupID => $ad_group->ID,
                                          );

    ok( @fetched_excluded_words );

    my $found = 0;
    foreach my $word ( @fetched_excluded_words ) {
        if ( $word->ID == $returned_excluded_word->ID ) {
            $found = 1;
            last;
        }
    }

    is( $found, 1, 'found newly added excluded word' );
}


sub test_get_excluded_words_by_account : Test(3) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::ExcludedWordsService->new->parse_config( section => $self->section );

    my $excluded_word = Yahoo::Marketing::ExcludedWord->new
                                                      ->accountID( $ysm_ws->account )
                                                      ->text( 'some excluded text 11' )
                        ;

    my $returned_excluded_word = $ysm_ws->addExcludedWordToAccount(
                                              excludedWord => $excluded_word,
                                          )->excludedWord;

    ok( $returned_excluded_word );

    my @fetched_excluded_words = $ysm_ws->getExcludedWordsByAccountID(
                                              accountID => $ysm_ws->account,
                                          );

    ok( @fetched_excluded_words );

    ok( ( grep { $_->ID == $returned_excluded_word->ID } @fetched_excluded_words ), 'found newly added excluded word' );
}


sub test_delete_excluded_word : Test(5) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::ExcludedWordsService->new->parse_config( section => $self->section );

    my $ad_group = $self->common_test_data( 'test_ad_group' );

    my $excluded_word1 = Yahoo::Marketing::ExcludedWord->new
                                                       ->adGroupID( $ad_group->ID )
                                                       ->text( 'some excluded text 12' )
                         ;
    my $excluded_word2 = Yahoo::Marketing::ExcludedWord->new
                                                       ->adGroupID( $ad_group->ID )
                                                       ->text( 'some excluded text 13' )
                         ;

    # add two words.
    my @returned_excluded_words = $ysm_ws->addExcludedWordsToAdGroup(
                                               excludedWords => [ $excluded_word1, $excluded_word2 ],
                                           );

    ok( @returned_excluded_words );

    # get two words.
    my @fetched_excluded_words = $ysm_ws->getExcludedWordsByAdGroupID(
                                              adGroupID => $ad_group->ID,
                                          );

    ok( @fetched_excluded_words );

    # confirm we can find one of the newly added words.

    ok( ( grep { $_->ID == $returned_excluded_words[0]->excludedWord->ID } @fetched_excluded_words ), 'found newly added excluded word' );

    # now delete it.
    $ysm_ws->deleteExcludedWord(
        excludedWordID => $returned_excluded_words[0]->excludedWord->ID,
    );

    # fetch again.
    @fetched_excluded_words = $ysm_ws->getExcludedWordsByAdGroupID(
        adGroupID => $ad_group->ID,
    );

    ok( @fetched_excluded_words );

    # confirm it's deleted.
    ok( ( not grep { $_->ID == $returned_excluded_words[0]->excludedWord->ID } @fetched_excluded_words ), 'found newly added excluded word' );
}


sub test_delete_excluded_words : Test(9) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::ExcludedWordsService->new->parse_config( section => $self->section );

    my $ad_group = $self->common_test_data( 'test_ad_group' );

    my @excluded_words = (
        Yahoo::Marketing::ExcludedWord->new
                                      ->adGroupID( $ad_group->ID )
                                      ->text( 'some excluded text 14' ),
        Yahoo::Marketing::ExcludedWord->new
                                      ->adGroupID( $ad_group->ID )
                                      ->text( 'some excluded text 15' ),
        Yahoo::Marketing::ExcludedWord->new
                                      ->adGroupID( $ad_group->ID )
                                      ->text( 'some excluded text 16' ),
    );

    # add three words.
    my @returned_excluded_words = $ysm_ws->addExcludedWordsToAdGroup(
                                               excludedWords => \@excluded_words,
                                           );

    ok( @returned_excluded_words );

    # get three words.
    my @fetched_excluded_words = $ysm_ws->getExcludedWordsByAdGroupID(
                                              adGroupID => $ad_group->ID,
                                          );

    ok( @fetched_excluded_words );

    # confirm we can find each one of the newly added words.
    foreach my $returned_word ( @returned_excluded_words ){
        ok( ( grep { $_->ID == $returned_word->excludedWord->ID } @fetched_excluded_words ), 'found newly added excluded word' );
    }

    # now delete two of them
    $ysm_ws->deleteExcludedWords(
                 excludedWordIDs => [ $returned_excluded_words[0]->excludedWord->ID,  $returned_excluded_words[1]->excludedWord->ID ],
             );

    # fetch again.
    @fetched_excluded_words = $ysm_ws->getExcludedWordsByAdGroupID(
                                           adGroupID => $ad_group->ID,
                                       );

    ok( scalar @fetched_excluded_words );

    # confirm those two were deleted (are no longer in the fetched excluded words).
    foreach my $returned_word ( @returned_excluded_words[0..1] ){
        ok( not ( grep { $_->ID == $returned_word->excludedWord->ID } @fetched_excluded_words ), 
            "excluded word has been deleted" 
        );
    }

    # third returned word should still be around
    ok( ( grep { $_->ID == $returned_excluded_words[2]->excludedWord->ID } @fetched_excluded_words ), 
        "third excluded word has NOT been deleted" 
    );
}



sub startup_test_excluded_words_service : Test(startup) {
    my ( $self ) = @_;

    $self->common_test_data( 'test_campaign', $self->create_campaign ) unless defined $self->common_test_data( 'test_campaign' );
    $self->common_test_data( 'test_ad_group', $self->create_ad_group ) unless defined $self->common_test_data( 'test_ad_group' );

}


sub shutdown_test_excluded_words_service : Test(shutdown) {
    my ( $self ) = @_;

    $self->cleanup_ad_group;
    $self->cleanup_campaign;

    # clean up excluded words in account.
    # if excluded word to be added already exists in account, the add action will fail.
    my $ysm_ws = Yahoo::Marketing::ExcludedWordsService->new->parse_config( section => $self->section );
    my @fetched_excluded_words = $ysm_ws->getExcludedWordsByAccountID(
                                              accountID => $ysm_ws->account,
                                          );
    $ysm_ws->deleteExcludedWords(
                 excludedWordIDs => [ map { $_->ID } @fetched_excluded_words ],
             ) 
        if @fetched_excluded_words;

}


1;

__END__

# addExcludedWordsToAdGroup
# addExcludedWordsToAccount
# addExcludedWordToAdGroup
# addExcludedWordToAccount
# deleteExcludedWord
# deleteExcludedWords
# getExcludedWord
# getExcludedWords
# getExcludedWordsByAdGroupID
# getExcludedWordsByAccountID
