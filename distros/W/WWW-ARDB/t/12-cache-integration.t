#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw( tempdir );
use lib 't/lib';

use WWW::ARDB;
use MockUA;

my $tmpdir = tempdir(CLEANUP => 1);
my $mock_ua = MockUA->new(fixtures_dir => 't/fixtures');

# Test with caching enabled
my $api = WWW::ARDB->new(
    ua        => $mock_ua,
    use_cache => 1,
    cache_dir => $tmpdir,
);

# First call - should fetch
my $items1 = $api->items;
is(scalar @$items1, 5, 'first call returns items');

# Second call - should use cache
my $items2 = $api->items;
is(scalar @$items2, 5, 'second call returns same count');

# Verify cache files exist
ok(-d $tmpdir, 'cache dir exists');
my @files = glob("$tmpdir/*.json");
ok(scalar @files > 0, 'cache files created');

# Test clear_cache for specific endpoint
$api->clear_cache('items');
@files = glob("$tmpdir/default_items*.json");
is(scalar @files, 0, 'items cache cleared');

# Fetch quests to create cache
$api->quests;
@files = glob("$tmpdir/*.json");
ok(scalar @files > 0, 'quests cache created');

# Test clear_cache for all
$api->clear_cache;
@files = glob("$tmpdir/*.json");
is(scalar @files, 0, 'all cache cleared');

# Test with caching disabled
my $api_no_cache = WWW::ARDB->new(
    ua        => $mock_ua,
    use_cache => 0,
);

$api_no_cache->items;
@files = glob("$tmpdir/*.json");
is(scalar @files, 0, 'no cache created when disabled');

done_testing;
