use strict;
use warnings;
use Test::Clustericious::Cluster 0.28;
use Test::Clustericious::Config;
use Test::More;

my $cluster = Test::Clustericious::Cluster->new;
$cluster->create_cluster_ok(qw( Yars ));

my $t = $cluster->t;

$t->get_ok($cluster->url)
  ->status_is(200)
  ->content_like(qr/welcome/i)
  ->content_type_like(qr{^text/plain(;.*)?$});

$t->post_ok("@{[ $cluster->url ]}/disk/status")
  ->status_is(500)
  ->content_is("ERROR: no state found in request\n");

note $t->tx->res->to_string;

done_testing;

__DATA__

@@ etc/Yars.conf
---
% use Test::Clustericious::Config;
url: <%= cluster->url %>
servers:
  - url: <%= cluster->url %>
    disks:
      - root: <%= create_directory_ok "data" %>
        buckets: [ 0,1,2,3,4,5,6,7,8,9,'a','b','c','d','e','f' ]

state_file: <%= create_directory_ok("state") . "/state.txt" %>
