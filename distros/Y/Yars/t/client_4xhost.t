use strict;
use warnings;
use 5.010;
use Test::Clustericious::Cluster;
use Test::Clustericious::Config;
use Test::Clustericious::Log import => 'log_unlike';
use Test::More;
use Yars::Client;
use Path::Class qw( file dir );
use Clustericious::Config;
use File::Temp qw( tempdir );
use File::HomeDir;
use File::Path qw( remove_tree );
use File::Copy qw( move );
use YAML::XS qw( Dump );

plan tests => 6;

my $cluster = Test::Clustericious::Cluster->new;

subtest prep => sub {
  plan tests => 7;
  create_directory_ok 'foo1';
  create_directory_ok 'foo2';
  create_directory_ok 'foo3';
  create_directory_ok 'foo4';
  $cluster->create_cluster_ok(qw( Yars Yars Yars Yars ));
  
  #use YAML::XS;
  #use File::HomeDir;
  #use Path::Class qw( file );
  #note "~ config template ~";
  #note file(File::HomeDir->my_home, 'etc', 'Yars.conf')->slurp;
  #note "~ config data ~";
  #note YAML::XS::Dump(Clustericious::Config->new('Yars'));

  my $config = Clustericious::Config->new('Yars');
  is $config->url, $cluster->urls->[3], "primary is @{[ $cluster->urls->[3] ]}";
  is $config->failover_urls->[0], $cluster->urls->[2], "failover is @{[ $cluster->urls->[2] ]}";
  note "url:      ", $_ for map { $_->{url} } $config->servers;
};

my $ua = $cluster->t->ua;
$ua->max_redirects(3);
$_->tools->_set_ua(sub { my $ua = $cluster->create_ua; $ua }) for @{ $cluster->apps };

subtest 'stashed on non-failover, non-primary' => sub {
  plan tests => 3;

  my $data = "\x68\x65\x72\x65\x0a";
  
  my $y = Yars::Client->new;
  
  is $y->upload('stuff', \$data), 'ok', 'uploaded stuff';
  
  subtest 'not stashed' => sub {
    plan tests => 2;
    my $dest = file(tempdir( CLEANUP => 1 ), 'stuff');  
    is $y->download('stuff', 'bc98d84673286ce1447eca1766f28504', $dest->parent), 'ok', 'download is ok';
    is $dest->slurp, $data, 'download content matches';
  };
  
  # remove old
  dir(File::HomeDir->my_home, 'foo2', 'bc')->rmtree(0,0);
  # recreate as stashed file
  my $dir = dir(File::HomeDir->my_home, qw( foo1 bc 98 d8 46 73 28 6c e1 44 7e ca 17 66 f2 85 04 ));
  $dir->mkpath(0,0755);
  $dir->file('stuff')->spew(iomode => '>:raw', $data);
  
  subtest 'stashed' => sub {
    plan tests => 2;
    my $dest = file(tempdir( CLEANUP => 1 ), 'stuff');  
    is $y->download('stuff', 'bc98d84673286ce1447eca1766f28504', $dest->parent), 'ok', 'download is ok';
    is -f "$dest" && $dest->slurp, $data, 'download content matches';
  };

  reset_store(); 
};

subtest 'bucket cache' => sub {
  plan tests => 2;

  my $y = Yars::Client->new;
  my $good_bucket_map = $y->bucket_map_cached;
  my $bad_bucket_map  = { map { sprintf('%x', $_) => $good_bucket_map->{sprintf '%x', ($_+4)%16} } 0..15 };

  subtest 'download' => sub {
    plan tests => 4;
    
    subtest 'download not stashed with invalid cache'=> sub {
      plan tests => 4;
      $y->upload('stuff', \"\x68\x65\x72\x65\x0a");
      $y->bucket_map_cached($bad_bucket_map);
      is $y->bucket_map_cached, $bad_bucket_map, 'preload with incorrect bucket map';  
      is $y->download('stuff', 'bc98d84673286ce1447eca1766f28504', \my $data), 'ok', 'download is ok';
      is $data, "\x68\x65\x72\x65\x0a", "data matches";
      is $y->bucket_map_cached, 0, 'cache has been cleared';
      reset_store();
    };
  
    subtest 'download stashed with invalid cache' => sub {
      plan tests => 4;
      $y->upload('stuff', \"\x68\x65\x72\x65\x0a");
      $y->bucket_map_cached($bad_bucket_map);
      is $y->bucket_map_cached, $bad_bucket_map, 'preload with incorrect bucket map';
    
      my $from = file(File::HomeDir->my_home, qw( foo2 bc 98 d8 46 73 28 6c e1 44 7e ca 17 66 f2 85 04 stuff ));
      my $to   = file(File::HomeDir->my_home, qw( foo4 bc 98 d8 46 73 28 6c e1 44 7e ca 17 66 f2 85 04 stuff ));
      note "move $from => $to";
      $to->parent->mkpath(0, 0700);
      move("$from", "$to") || die "copy $from => $to failed: $!";
    
      is $y->download('stuff', 'bc98d84673286ce1447eca1766f28504', \my $data), 'ok', 'download is ok';
      is $data, "\x68\x65\x72\x65\x0a", "data matches";
      is $y->bucket_map_cached, 0, 'cache has been cleared';
      reset_store();
    };

    subtest 'download not stashed with valid cache'=> sub {
      plan tests => 4;
      $y->upload('stuff', \"\x68\x65\x72\x65\x0a");
      $y->bucket_map_cached($good_bucket_map);
      is $y->bucket_map_cached, $good_bucket_map, 'preload with correct bucket map';  
      is $y->download('stuff', 'bc98d84673286ce1447eca1766f28504', \my $data), 'ok', 'download is ok';
      is $data, "\x68\x65\x72\x65\x0a", "data matches";
      isnt $y->bucket_map_cached, 0, 'cache has been cleared';
      reset_store();
    };
  
    subtest 'download stashed with valid cache' => sub {
      plan tests => 4;
      $y->bucket_map_cached($good_bucket_map);
      $y->upload('stuff', \"\x68\x65\x72\x65\x0a");
      is $y->bucket_map_cached, $good_bucket_map, 'preload with correct bucket map';
    
      my $from = file(File::HomeDir->my_home, qw( foo2 bc 98 d8 46 73 28 6c e1 44 7e ca 17 66 f2 85 04 stuff ));
      my $to   = file(File::HomeDir->my_home, qw( foo4 bc 98 d8 46 73 28 6c e1 44 7e ca 17 66 f2 85 04 stuff ));
      note "move $from => $to";
      $to->parent->mkpath(0, 0700);
      move("$from", "$to") || die "copy $from => $to failed: $!";
    
      is $y->download('stuff', 'bc98d84673286ce1447eca1766f28504', \my $data), 'ok', 'download is ok';
      is $data, "\x68\x65\x72\x65\x0a", "data matches";
      isnt $y->bucket_map_cached, 0, 'cache has been cleared';
      reset_store();
    };

  };

  subtest 'upload' => sub {
    plan tests => 2;

    subtest 'upload with invalid cache' => sub {
      plan tests => 3;
      $y->bucket_map_cached($bad_bucket_map);
      is $y->bucket_map_cached, $bad_bucket_map, 'preload with incorrect bucket map';
      is $y->upload('stuff', \"\x68\x65\x72\x65\x0a"), 'ok';
      is $y->bucket_map_cached, 0, 'cache has been cleared';
      reset_store();
    };

    subtest 'upload with valid cache' => sub {
      plan tests => 3;
      $y->bucket_map_cached($good_bucket_map);
      is $y->bucket_map_cached, $good_bucket_map, 'preload with incorrect bucket map';
      is $y->upload('stuff', \"\x68\x65\x72\x65\x0a"), 'ok';
      isnt $y->bucket_map_cached, 0, 'cache has been cleared';
      reset_store();
    };

  };

};

subtest 'persistent cache ignored if config has changed' => sub {
  plan tests => 1;
  Yars::Client->new->_server_for('bc98d84673286ce1447eca1766f28504');
  my $bad_bucket_map = Yars::Client->new->bucket_map_cached;
  $bad_bucket_map->{$_} = 'http://1.2.3.4:1234' for 0..9, 'a'..'f';
  Yars::Client->new->bucket_map_cached($bad_bucket_map);
  my $y = Yars::Client->new;
  is $y->bucket_map_cached, 0, 'ignored';
  note Dump($bad_bucket_map);  
};

subtest 'persistent cache not ignoredif config has not changed' => sub {
  plan tests => 1;
  Yars::Client->new->_server_for('bc98d84673286ce1447eca1766f28504');
  my $y = Yars::Client->new;
  isnt $y->bucket_map_cached, 0, 'not ignored';
  note Dump($y->bucket_map_cached);
};

sub reset_store
{
  foreach my $dir (grep { $_->basename ne 'tmp' } map { dir($_)->children } map { $_->{root} } map { @{ $_->{disks} } } Clustericious::Config->new('Yars')->servers)
  {
    remove_tree("$dir", { verbose => 0 });
  }
}

log_unlike qr{HASH\(0x[a-f0-9]+\)}, 'no hash references in log';

__DATA__

@@ etc/Yars.conf
---
url: <%= cluster->url %>
failover_urls:
  - <%= cluster->urls->[2] %>

servers:
  - url: <%= cluster->urls->[0] %>
    disks:
      - root: <%= dir home, 'foo1' %>
        buckets: [ c, d, e, f ]

  - url: <%= cluster->urls->[1] %>
    disks:
      - root: <%= dir home, 'foo2' %>
        buckets: [ 8, 9, a, b ]

  # failover
  - url: <%= cluster->urls->[2] %>
    disks:
      - root: <%= dir home, 'foo3' %>
        buckets: [ 4, 5, 6, 7 ]

  # primary
  - url: <%= cluster->urls->[3] %>
    disks:
      - root: <%= dir home, 'foo4' %>
        buckets: [ 0, 1, 2, 3 ]

state_file: <%= dir home, 'state' . cluster->index %>


