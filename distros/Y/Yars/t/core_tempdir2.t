use strict;
use warnings;
use Test::Clustericious::Config;
use Test::Clustericious::Cluster;
use Test::More tests =>  14;
use Mojo::ByteStream qw( b );

# max size should be smaller than the file
# PUT / GET messages, but larger than the 
# status, etc. messages in this test
# 100 was good enough on twin, but not acpsdev2
# 200 was good on acpsdev2, went with 500
# to be sure
$ENV{MOJO_MAX_MEMORY_SIZE} = 500; # force temp files
my $home = home_directory_ok;
$ENV{MOJO_TMPDIR} = "$home/nosuchdir";
ok !-d $ENV{MOJO_TMPDIR}, "MOJO_TMPDIR is invalid";

my $cluster = Test::Clustericious::Cluster->new;
$cluster->create_cluster_ok(qw( Yars ));
my $t = $cluster->t;
my $url = $cluster->url;

$t->get_ok("$url/status")
  ->json_is('/app_name', 'Yars');

my $content = 'x' x 1_000_000;
my $digest = b($content)->md5_sum->to_string;
my $filename = 'stuff.txt';

chomp(my $b64 = b($content)->md5_bytes->b64_encode);

$t->put_ok("$url/file/$filename", { "Content-MD5" => $b64 }, $content)
  ->status_is(201)
  ->header_like('Location', qr[.*$digest.*]);

$ENV{MOJO_TMPDIR} = create_directory_ok 'tmp';

$t->get_ok("$url/file/$filename/$digest")
  ->status_is(200);

is length($t->tx->res->body), length($content), "content lengths match";

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