use strict;
use warnings;
use 5.010;

use Test::Simple tests => 20;

use Word2vec::Lesk;


my $lesk = Word2vec::Lesk->new();

# Basic Method Testing (Test Accessor Functions)
ok( defined( $lesk ) );
ok( $lesk->GetDebugLog() == 0 );
ok( $lesk->GetWriteLog() == 0 );
ok( !defined( $lesk->GetFileHandle() ) );

# Advanced Method Testing
my $string_a = "patient arrives via hospital wheelchair gait steady history obtained from patient patient appears comfortable patient cooperative alert oriented to person place and time";
my $string_b = "complex assessment performed patient arrives ambulatory gait steady history obtained from parent patient appears comfortable patient cooperative alert oriented to person place and time";

my %overlapped_phrases = %{ $lesk->GetPhraseOverlap( $string_a, $string_b ) };
ok( scalar %overlapped_phrases == 3 );

my %matching_features  = %{ $lesk->GetMatchingFeatures( $string_a, $string_b ) };
ok( scalar %matching_features == 17 );

my $f_score = $lesk->CalculateFScore( $string_a, $string_b );
ok( abs( $f_score - 0.808510638297872 ) < 0.000001 );

my $lesk_score = $lesk->CalculateLeskScore( $string_a, $string_b );
ok( abs( $lesk_score - 0.313405797101449 ) < 0.000001 );

my $cosine_score = $lesk->CalculateCosineScore( $string_a, $string_b );
ok( abs( $cosine_score - 0.808693704220811 ) < 0.000001 );

my %results = %{ $lesk->CalculateAllScores( $string_a, $string_b ) };
ok( scalar %results == 10                       );
ok( $results{ "Raw Lesk"               } == 173 );
ok( $results{ "Matching Feature Count" } == 19  );
ok( $results{ "Matching Phrase Count"  } == 3   );
ok( $results{ "String A Length"        } == 23  );
ok( $results{ "String B Length"        } == 24  );
ok( abs( $results{ "Lesk"      } - 0.313405797101449 ) < 0.000001 );
ok( abs( $results{ "Precision" } - 0.791666666666667 ) < 0.000001 );
ok( abs( $results{ "Recall"    } - 0.826086956521739 ) < 0.000001 );
ok( abs( $results{ "F Score"   } - 0.808510638297872 ) < 0.000001 );
ok( abs( $results{ "Cosine"    } - 0.808693704220811 ) < 0.000001 );


# Clean Up
undef( %overlapped_phrases );
undef( %matching_features );
undef( $lesk );