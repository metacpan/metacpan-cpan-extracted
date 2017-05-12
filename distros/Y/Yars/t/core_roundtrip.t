use strict;
use warnings;
use Test::Clustericious::Config;
use Test::Clustericious::Cluster;
use Test::More tests => 4;
use Mojo::ByteStream qw( b );
use File::stat;

my $root;
my $t;
my $url;

subtest 'prep' => sub {
  plan tests => 4;
  $root = create_directory_ok "data";
  create_config_helper_ok data_dir => sub { $root };
  my $cluster = Test::Clustericious::Cluster->new;
  $cluster->create_cluster_ok(qw( Yars ));
  $t = $cluster->t;
  $url = $cluster->url;
};

subtest 'basic' => sub {
  plan tests => 29;
  my $content = 'Yabba Dabba Dooo!';
  my $digest = b($content)->md5_sum->to_string;
  my $file = 'fred.txt';

  $t->put_ok("$url/file/$file", {}, $content)
    ->status_is(201);
  my $location = $t->tx->res->headers->location;
  ok $location, "got location header";
  $t->get_ok("$url/file/$file/$digest")
    ->status_is(200)
    ->content_is($content);
  chomp (my $b64 = b(pack 'H*',$digest)->b64_encode);
  is $t->tx->res->headers->header("Content-MD5"), $b64;
  $t->get_ok("$url/file/$digest/$file")
    ->status_is(200)
    ->content_is($content);
  $t->get_ok($location)
    ->status_is(200)
    ->content_is($content);
  $t->get_ok("$url/disk/usage?count=1")
    ->status_is(200);
  is $t->tx->res->json->{$root}{count}, 1;

  # Idempotent PUT
  $t->put_ok("$url/file/$file", {}, $content)
    ->status_is(200);
  my $location2 = $t->tx->res->headers->location;
  is $location, $location2, "same location header";
  is $t->get_ok("$url/disk/usage?count=1")->status_is(200)->tx->res->json->{$root}{count}, 1;
  $t->head_ok($location)
    ->status_is(200);
  is $t->tx->res->headers->content_length, b($content)->size, "Right content-length in HEAD";
  like $t->tx->res->headers->content_type, qr{^text/plain(;.*)?$}, "Right content-type in HEAD";
  ok $t->tx->res->headers->last_modified, "last-modified is set";
  $t->delete_ok("$url/file/$file/$digest")
    ->status_is(200);
};

subtest 'Same filename, different content' => sub {
  plan tests => 11;
  $t->put_ok("$url/file/houston", {}, "a street in nyc")
    ->status_is(201);
  my $nyc = $t->tx->res->headers->location;
  $t->put_ok("$url/file/houston", {}, "we have a problem")
    ->status_is(201);
  my $tx = $t->tx->res->headers->location;
  ok $nyc ne $tx, "Two locations";
  $t->get_ok($nyc)
    ->content_is("a street in nyc");
  $t->get_ok($tx)
    ->content_is("we have a problem");
  $t->delete_ok($nyc);
  $t->delete_ok($tx);
};

subtest 'Same content, different filename' => sub {
  plan tests => 15;
  my $content = "sugar filled soft drink that is bad for your teeth";
  my $md5 = b($content)->md5_sum;
  $t->put_ok("$url/file/coke", {}, $content)
    ->status_is(201);
  my $coke = $t->tx->res->headers->location;
  $t->put_ok("$url/file/pepsi", {}, $content)
    ->status_is(201);
  my $pepsi = $t->tx->res->headers->location;
  ok $coke ne $pepsi, "Two locations";
  $t->get_ok($coke)
    ->content_is($content);
  $t->get_ok($pepsi)
    ->content_is($content);
  my $coke_file = join '/', $root, ($md5 =~ /(..)/g), 'coke';
  ok -e $coke_file, "wrote $coke_file";
  my $pepsi_file = join '/', $root, ($md5 =~ /(..)/g), 'pepsi';
  ok -e $pepsi_file, "wrote $pepsi_file";
  my $coke_stat  = stat($coke_file);
  my $pepsi_stat = stat($pepsi_file);
  like $coke_stat->ino, qr/^\d+$/, "found inode number " . $coke_stat->ino;
  is $coke_stat->ino, $pepsi_stat->ino, 'inode numbers are the same';
  $t->delete_ok($coke);
  $t->delete_ok($pepsi);
};

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
