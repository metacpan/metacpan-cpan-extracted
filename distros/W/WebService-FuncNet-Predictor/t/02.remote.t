use Test::More;
use strict;
use warnings;

use FindBin;
use URI::file;

if ($ENV{TEST_FUNCNET_REMOTE}) {
    plan tests => 8;
}
else {
    plan skip_all => 'Remote tests. Set $ENV{TEST_FUNCNET_REMOTE} to a true value to run.'
}

use_ok( 'WebService::FuncNet::Predictor' );

my ( $ws, $wsdl, $wsdl_uri );

isa_ok( $ws = WebService::FuncNet::Predictor->new(), 'WebService::FuncNet::Predictor', 'new (default URI)' );

my @proteins1 = qw( A3EXL0 Q8NFN7 O75865 );
my @proteins2 = qw( Q5SR05 Q9H8H3 P22676 );
    
isa_ok( my $response = $ws->score_pairwise_relations( \@proteins1, \@proteins2 ), 
        'WebService::FuncNet::Predictor::Operation::ScorePairwiseRelations::Response' );

isa_ok( my $results_ref = $response->results, 'ARRAY' );

my $first_result = $results_ref->[0];

is( $first_result->protein_1, 'O75865', 'protein_1' );
is( $first_result->protein_2, 'Q9H8H3', 'protein_2' );
is( $first_result->p_value, 0.445814, 'p_value' );
is( $first_result->raw_score, 0, 'raw_score' );
