#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw( tempdir );

use WWW::ARDB::Cache;

my $tmpdir = tempdir(CLEANUP => 1);

my $cache = WWW::ARDB::Cache->new(cache_dir => $tmpdir);
isa_ok($cache, 'WWW::ARDB::Cache');

# Test get on empty cache
my $result = $cache->get('items', {});
is($result, undef, 'Empty cache returns undef');

# Test set and get
my $data = { foo => 'bar', items => [1, 2, 3] };
$cache->set('items', {}, $data);

my $cached = $cache->get('items', {});
is_deeply($cached, $data, 'Cached data matches');

# Test with params
my $data2 = { baz => 'qux' };
$cache->set('items', { id => 'test' }, $data2);

my $cached2 = $cache->get('items', { id => 'test' });
is_deeply($cached2, $data2, 'Cached data with params matches');

# Original cache still intact
my $cached_orig = $cache->get('items', {});
is_deeply($cached_orig, $data, 'Original cached data still matches');

# Test clear specific endpoint
$cache->clear('items');
is($cache->get('items', {}), undef, 'Endpoint cleared');

# Test clear all
$cache->set('items', {}, $data);
$cache->set('quests', {}, $data2);
$cache->clear;
is($cache->get('items', {}), undef, 'All cleared - items');
is($cache->get('quests', {}), undef, 'All cleared - quests');

done_testing;
