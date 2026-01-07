#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use FindBin;
use lib "$FindBin::Bin/lib";

use_ok('WWW::MetaForge::ArcRaiders');

my $cache_dir = tempdir(CLEANUP => 1);

diag("Using MockUA for pagination tests");
require MockUA;
my $api = WWW::MetaForge::ArcRaiders->new(
  ua        => MockUA->new(fixtures_dir => "$FindBin::Bin/fixtures"),
  cache_dir => $cache_dir,
  use_cache => 0,
);

subtest 'items_paginated returns data and pagination' => sub {
  my $result = $api->items_paginated();

  ok(ref $result eq 'HASH', 'returns hashref');
  ok(exists $result->{data}, 'has data key');
  ok(exists $result->{pagination}, 'has pagination key');

  ok(ref $result->{data} eq 'ARRAY', 'data is arrayref');
  ok(scalar @{$result->{data}} > 0, 'data is not empty');

  my $pagination = $result->{pagination};
  ok(defined $pagination, 'pagination exists');
  is($pagination->{page}, 1, 'page is 1');
  ok(defined $pagination->{total}, 'has total');
  ok(defined $pagination->{totalPages}, 'has totalPages');
  ok(defined $pagination->{hasNextPage}, 'has hasNextPage');
};

subtest 'items vs items_paginated' => sub {
  my $items = $api->items();
  my $result = $api->items_paginated();

  ok(ref $items eq 'ARRAY', 'items() returns arrayref');
  is(scalar @$items, scalar @{$result->{data}}, 'same count as items_paginated data');
};

subtest 'items_all returns all items' => sub {
  my $all = $api->items_all();

  ok(ref $all eq 'ARRAY', 'returns arrayref');
  ok(scalar @$all > 0, 'not empty');

  # Since fixture has hasNextPage: false, should be same as single page
  my $result = $api->items_paginated();
  is(scalar @$all, scalar @{$result->{data}}, 'same count (single page)');
};

subtest 'items_paginated with search' => sub {
  my $result = $api->items_paginated(search => 'Ferro');

  ok(ref $result->{data} eq 'ARRAY', 'returns data array');
  # MockUA doesn't filter, but test that params pass through
};

subtest 'arcs_paginated returns data and pagination' => sub {
  my $result = $api->arcs_paginated();

  ok(ref $result eq 'HASH', 'returns hashref');
  ok(exists $result->{data}, 'has data key');
  ok(ref $result->{data} eq 'ARRAY', 'data is arrayref');

  if (@{$result->{data}}) {
    my $arc = $result->{data}[0];
    isa_ok($arc, 'WWW::MetaForge::ArcRaiders::Result::Arc');
    ok($arc->can('name'), 'has name accessor');
  }
};

subtest 'arcs vs arcs_paginated' => sub {
  my $arcs = $api->arcs();
  my $result = $api->arcs_paginated();

  ok(ref $arcs eq 'ARRAY', 'arcs() returns arrayref');
  is(scalar @$arcs, scalar @{$result->{data}}, 'same count');
};

subtest 'arcs_all returns all arcs' => sub {
  my $all = $api->arcs_all();
  ok(ref $all eq 'ARRAY', 'returns arrayref');
};

subtest 'quests_paginated returns data and pagination' => sub {
  my $result = $api->quests_paginated();

  ok(ref $result eq 'HASH', 'returns hashref');
  ok(exists $result->{data}, 'has data key');
  ok(ref $result->{data} eq 'ARRAY', 'data is arrayref');

  if (@{$result->{data}}) {
    my $quest = $result->{data}[0];
    isa_ok($quest, 'WWW::MetaForge::ArcRaiders::Result::Quest');
    ok($quest->can('name'), 'has name accessor');
  }
};

subtest 'quests vs quests_paginated' => sub {
  my $quests = $api->quests();
  my $result = $api->quests_paginated();

  ok(ref $quests eq 'ARRAY', 'quests() returns arrayref');
  is(scalar @$quests, scalar @{$result->{data}}, 'same count');
};

subtest 'quests_all returns all quests' => sub {
  my $all = $api->quests_all();
  ok(ref $all eq 'ARRAY', 'returns arrayref');
};

subtest 'quests_with_pagination legacy alias' => sub {
  my $result = $api->quests_with_pagination();

  ok(ref $result eq 'HASH', 'returns hashref');
  ok(exists $result->{quests}, 'has quests key (legacy)');
  ok(exists $result->{pagination}, 'has pagination key');
  ok(ref $result->{quests} eq 'ARRAY', 'quests is arrayref');
};

subtest 'items_with_pagination legacy alias' => sub {
  my $result = $api->items_with_pagination();

  ok(ref $result eq 'HASH', 'returns hashref');
  ok(exists $result->{data}, 'has data key');
  ok(exists $result->{pagination}, 'has pagination key');
};

done_testing;
