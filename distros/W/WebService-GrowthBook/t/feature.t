use strict;
use warnings;
use Test::More;
use_ok('WebService::GrowthBook::Feature');
my $feature = WebService::GrowthBook::Feature->new(id => 'feature_id', default_value => 'default_value', rules =>[{condition => {'id' => 123}}] );
isa_ok($feature, 'WebService::GrowthBook::Feature');
isa_ok($feature->rules->[0], 'WebService::GrowthBook::FeatureRule' );
is($feature->rules->[0]->condition->{id}, 123, 'condition id is 123');
done_testing();