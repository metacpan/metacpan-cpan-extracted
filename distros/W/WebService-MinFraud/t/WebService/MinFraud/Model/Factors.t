use strict;
use warnings;

use lib 't/lib';

use Test::More 0.88;
use Test::WebService::MinFraud qw( decode_json_file test_insights );
use WebService::MinFraud::Model::Factors;

my $response = decode_json_file('factors-response.json');
my $class    = 'WebService::MinFraud::Model::Factors';
my $model    = $class->new($response);

test_insights( $model, $class, $response );

subtest 'subscores' => sub {
    for my $subscore ( sort keys %{ $response->{subscores} } ) {
        is(
            $model->subscores->$subscore, $response->{subscores}{$subscore},
            $subscore
        );
    }
};

done_testing;
