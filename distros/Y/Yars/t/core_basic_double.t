use strict;
use warnings;
use 5.010;
use Test::Clustericious::Cluster 0.28;
use Test::Clustericious::Config;
use Test::Clustericious::Log import => 'log_unlike';
use Test::More tests => 29;
use Test::Mojo;
use Mojo::Server::Daemon;
use Yars;
use Yars::Client;
use YAML::XS qw( Dump );

do {
  my @data_dir = map { create_directory_ok "data_$_" } 1..4;
  my $state = create_directory_ok "state";
  
  create_config_helper_ok data_dir => sub { \@data_dir };
  create_config_helper_ok state_dir => sub { $state . '/' . shift };
};

my $cluster = Test::Clustericious::Cluster->new;
$cluster->create_cluster_ok(qw( Yars Yars ));
my $t = $cluster->t;
my @url = @{ $cluster->urls };

$t->get_ok("$url[0]/")
  ->status_is(200)
  ->content_type_like(qr{^text/plain})
  ->content_like(qr{welcome}i);

$t->get_ok("$url[0]/status")
  ->status_is(200)
  ->json_is('/app_name', 'Yars');
$t->get_ok("$url[1]/status")
  ->status_is(200)
  ->json_is('/app_name', 'Yars');

my $client = Yars::Client->new;

my $upload   = create_directory_ok 'up';
my $download = create_directory_ok 'dl';

# first file hello.txt is generated to go to the first Yars server ($url[0])
do {
  use autodie;
  open my $fh, '>', "$upload/hello.txt";
  print $fh 'hello world';
  close $fh;
};

ok $client->upload("$upload/hello.txt"), 'upload hello.txt';
ok $client->download("hello.txt", '5eb63bbbe01eeed093cb22bb8f5acdc3', $download), 'download hello.txt';
ok -r "$download/hello.txt", "file downloaded to correct location";

do {
  use autodie;
  open my $fh, '<', "$download/hello.txt";
  my $data = <$fh>;
  close $fh;
  
  is $data, 'hello world', 'file has correct content';
};


# second file second.txt is generated to go to the second Yars server ($url[1])
do {
  use autodie;
  open my $fh, '>', "$upload/second.txt";
  binmode $fh;
  print $fh "and again \n";
  close $fh;
};

ok $client->upload("$upload/second.txt"), "upload second.txt";
ok $client->download("second.txt", 'b571a4c57d27b581da89285fc6fe9e74', $download), "download second.txt";
ok -r "$download/second.txt", "file downloaded to correct location";

do {
  use autodie;
  open my $fh, '<', "$download/second.txt";
  binmode $fh;
  my $data = <$fh>;
  close $fh;
  
  is $data, "and again \n", 'file has correct content';
};

log_unlike qr{HASH\(0x[a-f0-9]+\)}, 'no hash references in log';

__DATA__

@@ etc/Yars.conf
---
url: <%= cluster->url %>

servers:
  - url: <%= cluster->urls->[0] %>
    disks:
      - root: <%= data_dir->[0] %>
        buckets: [ 0,1,2,3 ]
      - root: <%= data_dir->[1] %>
        buckets: [ 4,5,6,7 ]
  - url: <%= cluster->urls->[0] %>
    disks:
      - root: <%= data_dir->[2] %>
        buckets: [ 8,9,'a','b' ]
      - root: <%= data_dir->[3] %>
        buckets: [ 'c','d','e','f' ]
        
state_file: <%= state_dir(cluster->index) %>
