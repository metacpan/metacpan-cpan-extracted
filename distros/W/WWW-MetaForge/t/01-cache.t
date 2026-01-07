#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Path::Tiny;

use_ok('WWW::MetaForge::Cache');

my $temp_dir = tempdir(CLEANUP => 1);

subtest 'constructor with custom cache_dir' => sub {
  my $cache = WWW::MetaForge::Cache->new(
    cache_dir => $temp_dir,
  );

  isa_ok($cache, 'WWW::MetaForge::Cache');
  ok($cache->cache_dir->is_dir, 'cache_dir exists');
};

subtest 'default namespace' => sub {
  my $cache = WWW::MetaForge::Cache->new(cache_dir => $temp_dir);
  is($cache->namespace, 'metaforge', 'default namespace is metaforge');
};

subtest 'cache_dir coercion from string' => sub {
  my $cache = WWW::MetaForge::Cache->new(
    cache_dir => "$temp_dir",  # string, not Path::Tiny
  );

  isa_ok($cache->cache_dir, 'Path::Tiny', 'coerced to Path::Tiny');
};

subtest 'default TTL is empty (never expire)' => sub {
  my $cache = WWW::MetaForge::Cache->new(cache_dir => $temp_dir);

  is_deeply($cache->ttl, {}, 'default TTL is empty hash');
  ok(!defined $cache->ttl->{items}, 'items has no TTL (never expires)');
  ok(!defined $cache->ttl->{event_timers}, 'event_timers has no TTL (never expires)');
};

subtest 'custom TTL' => sub {
  my $cache = WWW::MetaForge::Cache->new(
    cache_dir => $temp_dir,
    ttl       => { items => 60, traders => 120 },
  );

  is($cache->ttl->{items}, 60, 'custom items TTL');
  is($cache->ttl->{traders}, 120, 'custom traders TTL');
};

subtest 'get/set roundtrip' => sub {
  my $cache = WWW::MetaForge::Cache->new(cache_dir => $temp_dir);
  my $data = { foo => 'bar', list => [1, 2, 3] };

  $cache->set('test_endpoint', { param => 'value' }, $data);

  my $retrieved = $cache->get('test_endpoint', { param => 'value' });
  is_deeply($retrieved, $data, 'data roundtrips correctly');
};

subtest 'get returns undef for missing' => sub {
  my $cache = WWW::MetaForge::Cache->new(cache_dir => $temp_dir);

  my $result = $cache->get('nonexistent', {});
  ok(!defined $result, 'missing cache returns undef');
};

subtest 'different params create different cache entries' => sub {
  my $cache = WWW::MetaForge::Cache->new(cache_dir => $temp_dir);

  $cache->set('items', { search => 'Ferro' }, { name => 'Ferro' });
  $cache->set('items', { search => 'Grip' }, { name => 'Grip' });

  my $ferro = $cache->get('items', { search => 'Ferro' });
  my $grip = $cache->get('items', { search => 'Grip' });

  is($ferro->{name}, 'Ferro', 'first entry');
  is($grip->{name}, 'Grip', 'second entry');
};

subtest 'TTL expiration' => sub {
  my $cache = WWW::MetaForge::Cache->new(
    cache_dir => $temp_dir,
    ttl       => { test => 1 },  # 1 second TTL
  );

  $cache->set('test', {}, { data => 'value' });

  my $immediate = $cache->get('test', {});
  is($immediate->{data}, 'value', 'immediate get works');

  sleep 2;  # Wait for expiration

  my $expired = $cache->get('test', {});
  ok(!defined $expired, 'expired cache returns undef');
};

subtest 'no TTL means never expire' => sub {
  my $cache = WWW::MetaForge::Cache->new(
    cache_dir => $temp_dir,
    ttl       => {},  # empty = never expire
  );

  $cache->set('forever', {}, { data => 'permanent' });

  my $immediate = $cache->get('forever', {});
  is($immediate->{data}, 'permanent', 'immediate get works');

  sleep 2;  # Wait... but it should NOT expire

  my $still_valid = $cache->get('forever', {});
  is($still_valid->{data}, 'permanent', 'cache still valid without TTL');
};

subtest 'clear specific endpoint' => sub {
  my $cache = WWW::MetaForge::Cache->new(cache_dir => $temp_dir);

  $cache->set('endpoint_a', {}, { a => 1 });
  $cache->set('endpoint_b', {}, { b => 2 });

  $cache->clear('endpoint_a');

  ok(!defined $cache->get('endpoint_a', {}), 'endpoint_a cleared');
  is($cache->get('endpoint_b', {})->{b}, 2, 'endpoint_b still exists');
};

subtest 'clear_all' => sub {
  my $cache = WWW::MetaForge::Cache->new(cache_dir => $temp_dir);

  $cache->set('ep1', {}, { x => 1 });
  $cache->set('ep2', {}, { y => 2 });

  $cache->clear_all;

  ok(!defined $cache->get('ep1', {}), 'ep1 cleared');
  ok(!defined $cache->get('ep2', {}), 'ep2 cleared');
};

subtest 'cache file contains metadata' => sub {
  my $cache = WWW::MetaForge::Cache->new(cache_dir => $temp_dir);

  $cache->set('meta_test', { key => 'val' }, { result => 'data' });

  # Find the cache file and read it directly
  my @files = path($temp_dir)->children(qr/^meta_test_/);
  ok(@files == 1, 'cache file created');

  my $content = $cache->json->decode($files[0]->slurp_utf8);
  ok(exists $content->{timestamp}, 'has timestamp');
  ok(exists $content->{endpoint}, 'has endpoint');
  ok(exists $content->{params}, 'has params');
  ok(exists $content->{data}, 'has data');
  is($content->{endpoint}, 'meta_test', 'endpoint stored');
};

done_testing;
