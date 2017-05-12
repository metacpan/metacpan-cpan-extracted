use strict;
use warnings;
use Test::Clustericious::Cluster;
use Test::Clustericious::Config;
use Test::More tests => 5;

my $cluster = Test::Clustericious::Cluster->new;
$cluster->create_cluster_ok(qw( Yars ));
my $t = $cluster->t;
my $url = $cluster->url;

my $content = 'We\'re gonna be late for the lodge meeting Fred.';

$t->get_ok("$url/file/barney/5551212", {}, $content)
  ->status_is(404);

__DATA__

@@ etc/Yars.conf
---
% use Test::Clustericious::Config;
url: <%= cluster->url %>
servers:
  - url: <%= cluster->url %>
    disks:
      - root: <%= create_directory_ok 'data' %>
        buckets: [ 0,1,2,3,4,5,6,7,8,9,'a','b','c','d','e','f' ]

state_file: <%= create_directory_ok("state") . "/state.txt" %>
