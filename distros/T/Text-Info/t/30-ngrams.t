use Test::More;
use utf8;

use Text::Info;

my $text = Text::Info->new( "Dette er en test på at ngrams fungerer. Fordelt over. Flere setninger, selvfølgelig..." );

#
# Unigrams
#
my $unigrams = $text->unigrams;

is( $unigrams->[ 0], 'Dette'           , "Unigram sequence is correct" );
is( $unigrams->[ 1], 'er'              , "Unigram sequence is correct" );
is( $unigrams->[ 2], 'en'              , "Unigram sequence is correct" );
is( $unigrams->[ 3], 'test'            , "Unigram sequence is correct" );
is( $unigrams->[ 4], 'på'              , "Unigram sequence is correct" );
is( $unigrams->[ 5], 'at'              , "Unigram sequence is correct" );
is( $unigrams->[ 6], 'ngrams'          , "Unigram sequence is correct" );
is( $unigrams->[ 7], 'fungerer'        , "Unigram sequence is correct" );
is( $unigrams->[ 8], 'Fordelt'         , "Unigram sequence is correct" );
is( $unigrams->[ 9], 'over'            , "Unigram sequence is correct" );
is( $unigrams->[10], 'Flere'           , "Unigram sequence is correct" );
is( $unigrams->[11], 'setninger'       , "Unigram sequence is correct" );
is( $unigrams->[12], 'selvfølgelig'    , "Unigram sequence is correct" );

is( $unigrams->[13], undef, "Unigram sequence ends correctly");

#
# Bigrams
#
my $bigrams = $text->bigrams;

is( $bigrams->[0], 'Dette er'               , "Bigram sequence is correct" );
is( $bigrams->[1], 'er en'                  , "Bigram sequence is correct" );
is( $bigrams->[2], 'en test'                , "Bigram sequence is correct" );
is( $bigrams->[3], 'test på'                , "Bigram sequence is correct" );
is( $bigrams->[4], 'på at'                  , "Bigram sequence is correct" );
is( $bigrams->[5], 'at ngrams'              , "Bigram sequence is correct" );
is( $bigrams->[6], 'ngrams fungerer'        , "Bigram sequence is correct" );
is( $bigrams->[7], 'Fordelt over'           , "Bigram sequence is correct" );
is( $bigrams->[8], 'Flere setninger'        , "Bigram sequence is correct" );
is( $bigrams->[9], 'setninger selvfølgelig' , "Bigram sequence is correct" );

is( $trigrams->[10], undef, "Bigram sequence ends correctly" );

#
# Trigrams
#
my $trigrams = $text->trigrams;

is( $trigrams->[0], 'Dette er en'                  , "Trigram sequence is correct" );
is( $trigrams->[1], 'er en test'                   , "Trigram sequence is correct" );
is( $trigrams->[2], 'en test på'                   , "Trigram sequence is correct" );
is( $trigrams->[3], 'test på at'                   , "Trigram sequence is correct" );
is( $trigrams->[4], 'på at ngrams'                 , "Trigram sequence is correct" );
is( $trigrams->[5], 'at ngrams fungerer'           , "Trigram sequence is correct" );
is( $trigrams->[6], 'Flere setninger selvfølgelig' , "Trigram sequence is correct" );

is( $trigrams->[7], undef, "Trigram sequence ends correctly" );

#
# Quadgrams
#
my $quadgrams = $text->quadgrams;

is( $quadgrams->[0], 'Dette er en test'      , "Quadgram sequence is correct" );
is( $quadgrams->[1], 'er en test på'         , "Quadgram sequence is correct" );
is( $quadgrams->[2], 'en test på at'         , "Quadgram sequence is correct" );
is( $quadgrams->[3], 'test på at ngrams'     , "Quadgram sequence is correct" );
is( $quadgrams->[4], 'på at ngrams fungerer' , "Quadgram sequence is correct" );

is( $quadgrams->[5], undef, "Quadgram sequence ends correctly" );

#
# Trigrams #2
#
$text = Text::Info->new( "Den gang ble Petter Northug jr. den ubestridte VM-kongen med intet mindre enn fem medaljer, hvorav tre kom i den edleste valøren." );

$trigrams = $text->trigrams;

is( $trigrams->[ 0], 'Den gang ble'        , "Trigram sequence is correct" );
is( $trigrams->[ 1], 'gang ble Petter'     , "Trigram sequence is correct" );
is( $trigrams->[ 2], 'ble Petter Northug'  , "Trigram sequence is correct" );
is( $trigrams->[ 3], 'Petter Northug jr'   , "Trigram sequence is correct" );
is( $trigrams->[ 4], 'Northug jr den'      , "Trigram sequence is correct" );
is( $trigrams->[ 5], 'jr den ubestridte'   , "Trigram sequence is correct" );
is( $trigrams->[ 6], 'den ubestridte VM'   , "Trigram sequence is correct" );
is( $trigrams->[ 7], 'ubestridte VM kongen', "Trigram sequence is correct" );
is( $trigrams->[ 8], 'VM kongen med'       , "Trigram sequence is correct" );
is( $trigrams->[ 9], 'kongen med intet'    , "Trigram sequence is correct" );
is( $trigrams->[10], 'med intet mindre'    , "Trigram sequence is correct" );
is( $trigrams->[11], 'intet mindre enn'    , "Trigram sequence is correct" );
is( $trigrams->[12], 'mindre enn fem'      , "Trigram sequence is correct" );
is( $trigrams->[13], 'enn fem medaljer'    , "Trigram sequence is correct" );
is( $trigrams->[14], 'fem medaljer hvorav' , "Trigram sequence is correct" );

#
# The End
#
done_testing;
