use strict;
use warnings;
use Test::More;
use Test::MockTime qw(set_relative_time);
use WebService::GrowthBook::InMemoryFeatureCache;

my $cache = WebService::GrowthBook::InMemoryFeatureCache->new();
$cache->set('key', 'value', 10);
is($cache->get('key'), 'value', 'get value');
set_relative_time(11);
is($cache->get('key'), undef, 'get expired value');
$cache->set('key', 'value2', 10);
is($cache->get('key'), 'value2', 'get new value');
$cache->clear;
is($cache->get('key'), undef, 'cleared, now undef');
done_testing();