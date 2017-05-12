use strict;
use warnings;
use Test::Clustericious::Log;
use Test::Clustericious::Cluster;
use Test::Clustericious::Config;
use Test::More tests => 9;
use Mojo::ByteStream qw( b );

my $cluster = Test::Clustericious::Cluster->new;
$cluster->create_cluster_ok(qw( Yars ));
my $t = $cluster->t;
my $url = $cluster->url;

my $one = <<ONE;
d131dd02c5e6eec4693d9a0698aff95c 2fcab58712467eab4004583eb8fb7f89
55ad340609f4b30283e488832571415a 085125e8f7cdc99fd91dbdf280373c5b
d8823e3156348f5bae6dacd436c919c6 dd53e2b487da03fd02396306d248cda0
e99f33420f577ee8ce54b67080a80d1e c69821bcb6a8839396f9652b6ff72a70
ONE

my $two = <<TWO;
d131dd02c5e6eec4693d9a0698aff95c 2fcab50712467eab4004583eb8fb7f89
55ad340609f4b30283e4888325f1415a 085125e8f7cdc99fd91dbd7280373c5b
d8823e3156348f5bae6dacd436c919c6 dd53e23487da03fd02396306d248cda0
e99f33420f577ee8ce54b67080280d1e c69821bcb6a8839396f965ab6ff72a70
TWO

$one =~ tr/0-9a-f//dc;
$two =~ tr/0-9a-f//dc;
$one = pack('H*',$one);
$two = pack('H*',$two);

ok $one ne $two, "Strings differ";
is b($one)->md5_sum->to_string, b($two)->md5_sum->to_string, "MD5s the same";

$t->put_ok("$url/file/one", {}, $one)->status_is(201);  # created
$t->put_ok("$url/file/one", {}, $two)->status_is(409);  # conflict

1;

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

