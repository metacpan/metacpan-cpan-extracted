use strict;
use warnings;
BEGIN { $ENV{YARS_CONNECT_TIMEOUT} = $ENV{MOJO_CONNECT_TIMEOUT} = 1 }
use Test::Clustericious::Config;
use Test::Clustericious::Cluster;
use Test::Clustericious::Log import => 'log_unlike', note => 'TRACE..ERROR', diag => 'FATAL..FATAL';
use Test::More;

plan tests => 8;

subtest 'setup helpers' => sub {
  plan tests => 7;
  my @data_dir = map { create_directory_ok "data_$_" } 1..4;
  my $state = create_directory_ok "state";
  
  create_config_helper_ok data_dir => sub { \@data_dir };
  create_config_helper_ok state_dir => sub { $state . '/' . shift };
};

my $cluster = Test::Clustericious::Cluster->new;
$cluster->create_cluster_ok(qw( Yars Yars ));

my $t = $cluster->t;
my @url = @{ $cluster->urls };

require Yars::Client;
my $c = Yars::Client->new;

$_->tools->_set_ua(sub { $cluster->create_ua }) for @{ $cluster->apps };

subtest 'delete indirect' => sub {
  plan tests => 5;
  
  my $fn      = 'hello.txt';
  my $content = 'hello there';
  my $md5     = '161bc25962da8fed6d2f59922fb642aa';
  
  is $c->check( $fn, $md5 ), undef, 'not there yet...';
  is $c->upload($fn, \$content), 'ok', 'uploaded';
  is $c->check( $fn, $md5 ), 1, 'there...';
  is $c->remove($fn, $md5), '1', 'removed';
  is $c->check( $fn, $md5 ), undef, 'gone';
};

subtest 'delete direct' => sub {
  plan tests => 5;
  
  my $fn      = 'hello2.txt';
  my $content = 'and again';
  my $md5     = 'b3b1bb046d2a7e9fad53b9853fb5dfbd';
  
  is $c->check( $fn, $md5 ), undef, 'not there yet...';
  is $c->upload($fn, \$content), 'ok', 'uploaded';
  is $c->check( $fn, $md5 ), 1, 'there...';
  is $c->remove($fn, $md5), '1', 'removed';
  is $c->check( $fn, $md5 ), undef, 'gone';
};

subtest 'delete from stash (1)' => sub {
  plan tests => 6;

  my $fn      = 'hello.txt';
  my $content = 'hello there';
  my $md5     = '161bc25962da8fed6d2f59922fb642aa';

  $cluster->stop_ok(0);

  is $c->upload($fn, \$content), 'ok', 'uploaded';

  $cluster->start_ok(0);


  is $c->check( $fn, $md5 ), 1, 'there...';
  is $c->remove($fn, $md5), '1', 'removed';
  is $c->check( $fn, $md5 ), undef, 'gone';

};

subtest 'delete from stash (2)' => sub {
  plan tests => 6;

  my $fn      = 'hello2.txt';
  my $content = 'and again';
  my $md5     = 'b3b1bb046d2a7e9fad53b9853fb5dfbd';

  $cluster->stop_ok(1);

  is $c->upload($fn, \$content), 'ok', 'uploaded';

  $cluster->start_ok(1);


  is $c->check( $fn, $md5 ), 1, 'there...';
  is $c->remove($fn, $md5), '1', 'removed';
  is $c->check( $fn, $md5 ), undef, 'gone';

};

subtest 'delete failover' => sub {
  plan skip_all => 'TODO';
  plan tests => 7;
  my $fn      = 'hello.txt';
  my $content = 'hello there';
  my $md5     = '161bc25962da8fed6d2f59922fb642aa';
  
  is $c->check( $fn, $md5 ), undef, 'not there yet...';
  is $c->upload($fn, \$content), 'ok', 'uploaded';
  is $c->check( $fn, $md5 ), 1, 'there...';
  
  $cluster->stop_ok(1);
  
  is $c->remove($fn, $md5), '1', 'removed';
  
  $cluster->start_ok(1);
  
  is $c->check( $fn, $md5 ), undef, 'gone';

};

log_unlike qr{HASH\(0x[a-f0-9]+\)}, 'no hash references in log';

__DATA__

@@ etc/Yars.conf
---
url: <%= cluster->url %>

failover_urls:
  - <%= cluster->urls->[0] %>

servers:
  - url: <%= cluster->urls->[0] %>
    disks:
      - root: <%= data_dir->[0] %>
        buckets: [ 0,1,2,3 ]
      - root: <%= data_dir->[1] %>
        buckets: [ 4,5,6,7 ]
  - url: <%= cluster->urls->[1] %>
    disks:
      - root: <%= data_dir->[2] %>
        buckets: [ 8,9,'a','b' ]
      - root: <%= data_dir->[3] %>
        buckets: [ 'c','d','e','f' ]

state_file: <%= state_dir(cluster->index) %>


