use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::MockModule;
use WebService::GrowthBook;
use Path::Tiny;
use FindBin qw($Bin);
my $instance;
throws_ok { $instance = WebService::GrowthBook->new } qr/Required parameter 'client_key' is missing/;
my $mock = Test::MockModule->new('HTTP::Tiny');
my $get_result;
my $http_hit = 0;
$mock->mock(
    'get',
    sub {
        $http_hit = 1;
        return $get_result;
    });

$get_result = {
    status  => 200,
    content => path("$Bin/test_data_growthbook.json")->slurp
};

$instance = WebService::GrowthBook->new(client_key => 'key');
$instance->load_features;
ok($http_hit, "fetch data from site");
$http_hit = 0;
$instance->load_features;
ok(!$http_hit,                         "fetch data from cache");
ok($instance->is_on('bool-feature'),   'bool-feature is on');
ok(!$instance->is_off('bool-feature'), 'bool-feature is on');
is($instance->get_feature_value('bool-feature'),   1,          'bool-feature value is 1');
is($instance->get_feature_value('string-feature'), 'A string', 'string-feature value is OFF');
is($instance->get_feature_value('number-feature'), 123,        'number-feature value is 123');
is_deeply(
    $instance->get_feature_value('json-feature'),
    {
        "a" => 1,
        "b" => 2
    },
    'json-feature value is {"a":1,"b":2}'
);
is($instance->get_feature_value('not-exist-feature'), undef, "not-exist-feature value is undef");
is($instance->is_on('not-exist-feature'),             undef, "not-exist-feature is undef");
is($instance->is_off('not-exist-feature'),            undef, "not-exist-feature is undef");
is($instance->is_on('string-feature'),                undef, "is_on string is undef");
is($instance->is_off('string-feature'),               undef, "is_off string is undef");

done_testing();
