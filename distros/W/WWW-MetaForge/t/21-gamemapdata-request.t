#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use WWW::MetaForge::GameMapData::Request;

my $req = WWW::MetaForge::GameMapData::Request->new;

subtest 'base_url' => sub {
  is($req->base_url, 'https://metaforge.app/api/game-map-data', 'default base_url');
};

subtest 'map_data request' => sub {
  my $http_req = $req->map_data(map => 'dam');
  isa_ok($http_req, 'HTTP::Request');
  is($http_req->method, 'GET', 'GET method');
  like($http_req->uri, qr{game-map-data}, 'contains endpoint');
  like($http_req->uri, qr{mapID=dam}, 'contains mapID parameter (mapped from map)');
  like($http_req->uri, qr{tableID=arc_map_data}, 'contains default tableID');
};

subtest 'map_data with type filter' => sub {
  my $http_req = $req->map_data(map => 'dam', type => 'loot');
  like($http_req->uri, qr{mapID=dam}, 'contains mapID parameter');
  like($http_req->uri, qr{type=loot}, 'contains type parameter');
};

subtest 'map_data with mapID directly' => sub {
  my $http_req = $req->map_data(mapID => 'spaceport');
  like($http_req->uri, qr{mapID=spaceport}, 'accepts mapID directly');
};

subtest 'custom base_url' => sub {
  my $custom = WWW::MetaForge::GameMapData::Request->new(
    base_url => 'https://example.com/api/maps'
  );
  my $http_req = $custom->map_data(mapID => 'test');
  like($http_req->uri, qr{example\.com}, 'uses custom base_url');
};

done_testing;
