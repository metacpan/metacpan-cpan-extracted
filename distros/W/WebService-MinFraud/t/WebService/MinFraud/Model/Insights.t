use strict;
use warnings;

use lib 't/lib';

use Test::More 0.88;
use Test::WebService::MinFraud qw( decode_json_file test_insights );
use WebService::MinFraud::Model::Insights;

my $response = decode_json_file('insights-response.json');
my $class    = 'WebService::MinFraud::Model::Insights';
my $model    = $class->new($response);

test_insights( $model, $class, $response );

done_testing;
