use strict;
use warnings;

use lib 't/lib';

use JSON::MaybeXS;
use Test::More 0.88;
use Test::WebService::MinFraud qw( decode_json_file test_common_attributes );
use WebService::MinFraud::Model::Score;

my $response    = decode_json_file('score-response.json');
my $model_class = 'WebService::MinFraud::Model::Score';
my $score_model = $model_class->new($response);
test_common_attributes( $score_model, $model_class, $response );

done_testing;
