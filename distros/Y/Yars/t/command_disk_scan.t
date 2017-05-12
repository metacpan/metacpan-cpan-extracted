use strict;
use warnings;
use Test::Clustericious::Config;
use Test::Clustericious::Cluster;
use Test::More tests => 18;
use Capture::Tiny qw( capture_stdout );
use Yars::Command::yars_disk_scan;

my $data = create_directory_ok 'data';
my $state = create_directory_ok 'state';
create_config_helper_ok data_dir => sub { $data };
create_config_helper_ok state_dir => sub { $state };
my $cluster = Test::Clustericious::Cluster->new;
$cluster->create_cluster_ok(qw( Yars ));

is capture_stdout { is(Yars::Command::yars_disk_scan->main('-a'), 0, 'status = 0') }, '', 'empty yars, empty output';

my $t   = $cluster->t;
my $url = $cluster->url;

$t->put_ok("$url/file/robot.txt", {}, 'robots in disguise')
  ->status_is(201);

$t->put_ok("$url/file/scorecard.txt", {}, 'five to six')
  ->status_is(201);

is capture_stdout { is(Yars::Command::yars_disk_scan->main('-a'), 0, 'status = 0') }, '', 'trivial scan, both files are right';

# no muck up one of the files:
do {
  my $fn = "$data/29/0c/f0/c6/8c/8f/96/32/03/3a/1c/34/43/50/07/3f/robot.txt";
  ok -w $fn, "file is writable";
  open my $fh, '>>', $fn;
  print $fh "... more than meets the eye";
  close $fh;
};

like capture_stdout { is(Yars::Command::yars_disk_scan->main('-a'), 2, 'status = 2') }, qr{^290cf0c68c8f9632033a1c344350073f robot.txt$}m, 'one file is wrong';

like capture_stdout { is(Yars::Command::yars_disk_scan->main($data), 2, 'status = 2') }, qr{^290cf0c68c8f9632033a1c344350073f robot.txt$}m, 'one file is wrong';

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

state_file: <%= state_dir . "/state.txt" %>
