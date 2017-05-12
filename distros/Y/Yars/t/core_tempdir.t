use strict;
use warnings;
use Test::Clustericious::Config;
use Test::Clustericious::Cluster;
use Mojo::ByteStream qw( b );
use Test::More tests => 17;

$ENV{MOJO_MAX_MEMORY_SIZE} = 100; # Force temp files.
#$ENV{MOJO_TMPDIR} = "/dev/null"; # should be computed during request
$ENV{MOJO_TMPDIR} = create_directory_ok 'nosuchdir';

my $cluster = Test::Clustericious::Cluster->new;
$cluster->create_cluster_ok(qw( Yars ));
my $t = $cluster->t;
my $url = $cluster->url;

$t->get_ok("$url/")
  ->status_is(200);

my $content = 'x' x 1_000_000;
my $digest = b($content)->md5_sum->to_string;
my $filename = 'stuff.txt';

chomp (my $b64 = b($content)->md5_bytes->b64_encode);
$t->put_ok("$url/file/$filename", {"Content-MD5" => $b64 }, $content)
  ->status_is(201);

my $location = $t->tx->res->headers->location;
ok $location, "got location header";
like $location, qr[.*$digest.*], "location had digest";

$ENV{MOJO_TMPDIR} = create_directory_ok 'tmp';
$t->get_ok("$url/file/$filename/$digest")
  ->status_is(200);

my $got = $t->tx->success->body;
            
ok $got eq $content, "got content";
chomp (my $header = b($content)->md5_bytes->b64_encode);
is $t->tx->res->headers->header("Content-MD5"), $header;

$t->delete_ok("$url/file/$filename/$digest")->status_is(200);

__DATA__

@@ etc/Yars.conf
---
% use Test::Clustericious::Config;
url : <%= cluster->url %>

servers :
    - url : <%= cluster->urls->[0] %>
      disks :
        - root : <%= create_directory_ok 'data' %>
          buckets : [0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F]

state_file: <%= create_directory_ok('state') . "/state" %>
