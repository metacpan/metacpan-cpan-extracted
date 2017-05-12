use strict;
use warnings;
use EV;
use Test::Clustericious::Log diag => 'FATAL', note => 'INFO..ERROR';
use Test::Clustericious::Config;
use Test::Clustericious::Cluster;
use AnyEvent;
use AnyEvent::Open3::Simple;
use Test::More tests => 13;

our $anyevent_test_timeout = AnyEvent->timer(
  after => 20,
  cb => sub { diag "TIMEOUT: giving up"; exit },
);

my $datadir = create_directory_ok 'data';
create_config_helper_ok data_dir => sub { $datadir };

my $cluster = Test::Clustericious::Cluster->new;
$cluster->create_cluster_ok('Yars');
my $t = $cluster->t;

create_config_ok Yars => { url => "$cluster->{url}" };

my $done = AnyEvent->condvar;

my $stdout = '';
my $stderr = '';

my $ipc = AnyEvent::Open3::Simple->new(
    on_stdout => sub { $stdout .= "$_[1]\n" },
    on_stderr => sub { $stderr .= "$_[1]\n" },
    on_exit   => sub { $done->send(@_[1,2]); },
    on_error  => sub { $done->croak(shift); }
);

$ipc->run($^X, '-MYars::Command::yars_exercise', '-e',
          'Yars::Command::yars_exercise::main(qw(-n 2 -f 10 -s 8192 -g 10))');

my($exit_value, $signal) = $done->recv;

note "[err]\n$stderr" if $stderr;
note "[out]\n$stdout" if $stdout;

is $exit_value, 0, "exit value";
is $signal, 0, "signal";

like $stdout, qr/PUT ok 20/, "PUT 20 files";
like $stdout, qr/GET ok 200/, "GET 200 files";
like $stdout, qr/DELETE 1 20/, "DELETE 20 files";

# See if cluster is empty of all the files we PUT, then DELETEed
$t->get_ok("$cluster->{url}/bucket/usage")
  ->status_is(200);

is_deeply $t->tx->res->json->{'used'}, { $datadir => [] };

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

State_file: <%= create_directory_ok("state") . "/state.txt" %>

