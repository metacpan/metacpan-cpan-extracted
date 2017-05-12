#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Data::Dump qw( dump );

eval "use Text::Aspell";
plan skip_all => "Text::Aspell unavailable" if $@; 

use_ok('Text::IQ::EN');

ok( my $iq = Text::IQ::EN->new('t/doc/us-constitution.txt'), "new IQ" );
diag sprintf( "Number of words: %d\n",        $iq->num_words );
diag sprintf( "Avg word length: %0.4f\n",     $iq->avg_word_length );
diag sprintf( "Number of sentences: %d\n",    $iq->num_sentences );
diag sprintf( "Avg sentence length: %0.4f\n", $iq->avg_sentence_length );
diag sprintf( "Misspellings: %d\n",           $iq->num_misspellings );
diag sprintf( "Unique misspellings: %d\n",    $iq->num_uniq_misspellings );
diag sprintf( "Flesch: %0.4f\n",              $iq->flesch );
diag sprintf( "Fog: %0.4f\n",                 $iq->fog );
diag sprintf( "Kincaid: %0.4f\n",             $iq->kincaid );

is( $iq->num_words, 7639, "num_words" );
is( sprintf( "%0.1f", $iq->avg_word_length ), "4.8", "avg_word_length" );
is( $iq->num_sentences, 199, "num_sentences" );
is( sprintf( "%0.1f", $iq->avg_sentence_length ),
    "38.3", "avg_sentence_length" );
is( $iq->num_misspellings,      88, "num_misspellings" );
is( $iq->num_uniq_misspellings, 60, "num_uniq_misspellings" );
is( sprintf( "%0.1f", $iq->flesch ),  "31.8", "flesch" );
is( sprintf( "%0.1f", $iq->fog ),     "21.8", "fog" );
is( sprintf( "%0.1f", $iq->kincaid ), "18.4", "kincaid" );

#diag( dump $iq->misspelled );
#printf( "Grammar errors: %d\n",      $iq->num_grammar_errors );
#diag( dump $iq->get_sentences(1) );

done_testing();
