use strict;
use warnings;
use Test::Clustericious::Log;
use Test::Clustericious::Config;
use Test::Clustericious::Cluster;
use Test::More tests => 16;
use Mojo::ByteStream qw( b );

my $root = create_directory_ok 'data';
create_config_helper_ok data_dir => sub { $root };

my $cluster = Test::Clustericious::Cluster->new;
$cluster->create_cluster_ok(qw( Yars ));
my $t = $cluster->t;
my $url = $cluster->url;

my $content = 'Yabba Dabba Dooo!';
my $digest = b($content)->md5_sum->to_string;
my $bad_digest = '5551212';

$t->put_ok("$url/file/fred/$digest", {}, $content)
  ->status_is(201)
  ->content_is('ok');
  
my $location = $t->tx->res->headers->location;
$t->put_ok("$url/file/fred/$bad_digest", {}, $content)
  ->status_is(400);

$t->get_ok($location)
  ->status_is(200)
  ->content_is($content);

# Corrupt it
my $filename = join '/', $root, grep length, (split /(..)/,$digest),'fred';
ok -e $filename, "found file on filesystem";
open my $fp, ">$filename" or die "can't write to $root/$filename : $!";
ok ( (print $fp "drink more coffee"), "wrote more data to file");
close $fp or die $!;

$t->get_ok($location)
  ->status_isnt(200);

__DATA__

@@ etc/Yars.conf
---
% use Test::Clustericious::Config;
url: <%= cluster->url %>
servers:
  - url: <%= cluster->url %>
    disks:
      - root: <%= data_dir %>
        buckets: [ 0,1,2,3,4,5,6,7,8,9,'a','b','c','d','e','f' ]

state_file: <%= create_directory_ok("state") . "/state.txt" %>

