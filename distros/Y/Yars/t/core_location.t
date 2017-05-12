use strict;
use warnings;
BEGIN { $ENV{YARS_CONNECT_TIMEOUT} = $ENV{MOJO_CONNECT_TIMEOUT} = 1 }
use Test::Clustericious::Cluster;
use Test::Clustericious::Config;
use Test::Clustericious::Log import => 'log_unlike', note => 'TRACE..ERROR', diag => 'FATAL..FATAL';
use Test::More;
use File::Path 2.0 qw( remove_tree );
use File::Spec;

plan tests => 6;

my @data_dir;

subtest 'setup helpers' => sub {
  plan tests => 7;
  @data_dir = map { create_directory_ok "data_$_" } 1..4;
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

subtest 'location indirect' => sub {
  
  my $fn      = 'hello2.txt';
  my $content = 'hello there';
  my $md5     = '161bc25962da8fed6d2f59922fb642aa';

  is $c->check( $fn, $md5 ), undef, 'not there yet...';

  note "cluster.urls[0] = ", $cluster->urls->[0];
  note "cluster.urls[1] = ", $cluster->urls->[1];
  is $c->upload($fn, \$content), 'ok', 'upload okay';
  
  my $url = $cluster->urls->[0];
  like $c->res->headers->location, qr{\Q$url\E/};
  
  is $c->check( $fn, $md5 ), 1, 'there...';
  
  reset_yars();
  note "reset yars server";
  
  done_testing();
};

subtest 'location indirect failover' => sub {
  
  my $fn      = 'hello2.txt';
  my $content = 'hello there';
  my $md5     = '161bc25962da8fed6d2f59922fb642aa';

  is $c->check( $fn, $md5 ), undef, 'not there yet...';

  $cluster->stop_ok(1);
  note "cluster.urls[0] = ", $cluster->urls->[0];
  note "cluster.urls[1] = ", $cluster->urls->[1];
  is $c->upload($fn, \$content), 'ok', 'upload okay';
  $cluster->start_ok(1);
  
  my $url = $cluster->urls->[0];
  like $c->res->headers->location, qr{\Q$url\E/};
  
  is $c->check( $fn, $md5 ), 1, 'there...';
  
  reset_yars();
  note "reset yars server";
  
  done_testing();
};

subtest 'failover' => sub {
  
  my $fn      = 'hello2.txt';
  my $content = 'and again';
  my $md5     = 'b3b1bb046d2a7e9fad53b9853fb5dfbd';

  is $c->check( $fn, $md5 ), undef, 'not there yet...';

  $cluster->stop_ok(1);
  note "cluster.urls[0] = ", $cluster->urls->[0];
  note "cluster.urls[1] = ", $cluster->urls->[1];
  is $c->upload($fn, \$content), 'ok', 'upload okay';
  $cluster->start_ok(1);
  
  my $url = $cluster->urls->[0];
  like $c->res->headers->location, qr{\Q$url\E/};
  
  is $c->check( $fn, $md5 ), 1, 'there...';
  
  reset_yars();
  note "reset yars server";
  
  done_testing();
};

log_unlike qr{HASH\(0x[a-f0-9]+\)}, 'no hash references in log';

sub reset_yars {
  remove_tree(
    (map {
      my $base = $_;
      my $dh;
      opendir $dh, $base;
      map { File::Spec->catdir($base, $_) } grep !/^\./, readdir $dh;
    }
  @data_dir), { verbose => 0 });
  
}

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


