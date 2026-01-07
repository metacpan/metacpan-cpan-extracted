#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('WWW::MetaForge::ArcRaiders::Request');

my $req_factory = WWW::MetaForge::ArcRaiders::Request->new;

subtest 'default base URLs' => sub {
  is($req_factory->base_url, 'https://metaforge.app/api/arc-raiders', 'base_url');
  is($req_factory->map_data_url, 'https://metaforge.app/api/game-map-data', 'map_data_url');
};

subtest 'custom base URL' => sub {
  my $custom = WWW::MetaForge::ArcRaiders::Request->new(
    base_url => 'https://custom.api/v1',
  );
  is($custom->base_url, 'https://custom.api/v1', 'custom base_url');
};

subtest 'items request' => sub {
  my $req = $req_factory->items;
  isa_ok($req, 'HTTP::Request');
  is($req->method, 'GET', 'method is GET');
  like($req->uri, qr{/items$}, 'URI ends with /items');
};

subtest 'items request with params' => sub {
  my $req = $req_factory->items(
    search => 'Ferro',
    page   => 2,
    limit  => 10,
  );
  my $uri = $req->uri;

  like($uri, qr/search=Ferro/, 'has search param');
  like($uri, qr/page=2/, 'has page param');
  like($uri, qr/limit=10/, 'has limit param');
};

subtest 'arcs request' => sub {
  my $req = $req_factory->arcs(includeLoot => 'true');
  like($req->uri, qr{/arcs}, 'URI contains /arcs');
  like($req->uri, qr/includeLoot=true/, 'has param');
};

subtest 'quests request' => sub {
  my $req = $req_factory->quests(type => 'StoryQuest');
  like($req->uri, qr{/quests}, 'URI contains /quests');
  like($req->uri, qr/type=StoryQuest/, 'has param');
};

subtest 'traders request' => sub {
  my $req = $req_factory->traders(name => 'TianWen');
  like($req->uri, qr{/traders}, 'URI contains /traders');
  like($req->uri, qr/name=TianWen/, 'has param');
};

subtest 'event_timers request' => sub {
  my $req = $req_factory->event_timers(map => 'Dam');
  like($req->uri, qr{/events-schedule}, 'URI contains /events-schedule');
  like($req->uri, qr/map=Dam/, 'has param');
};

subtest 'map_data request uses different base URL' => sub {
  my $req = $req_factory->map_data(map => 'Spaceport');
  like($req->uri, qr{game-map-data}, 'uses game-map-data URL');
  like($req->uri, qr/map=Spaceport/, 'has param');
};

subtest 'empty params produce clean URL' => sub {
  my $req = $req_factory->items();
  my $uri = $req->uri->as_string;
  unlike($uri, qr/\?/, 'no query string without params');
};

subtest 'special characters in params are encoded' => sub {
  my $req = $req_factory->items(search => 'Ferro I');
  my $uri = $req->uri->as_string;
  like($uri, qr/Ferro(%20|\+)I/, 'space is encoded');
};

subtest 'all methods return HTTP::Request' => sub {
  for my $method (qw(items arcs quests traders event_timers map_data)) {
    my $req = $req_factory->$method();
    isa_ok($req, 'HTTP::Request', "$method returns HTTP::Request");
  }
};

done_testing;
