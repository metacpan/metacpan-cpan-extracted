use strict;
use warnings;
use Test::Clustericious::Log;
use Test::Clustericious::Cluster;
use Test::Clustericious::Config;
use Test::More tests => 75;
use Mojo::ByteStream qw( b );
use JSON::MaybeXS qw( encode_json );

my $test_files = 20;
my $root = create_directory_ok 'data';
create_config_helper_ok data_dir => sub { $root . '/' . shift };

my $cluster = Test::Clustericious::Cluster->new;
$cluster->create_cluster_ok(qw( Yars ));
my $t = $cluster->t;
my $url = $cluster->url;

sub _mark_down {
  my $t = shift;
  my $which = shift;
  $t->post_ok("$url/disk/status", { "Content-Type" => "application/json" }, encode_json( { root => "$root/$which", "state" => "down" }))
    ->status_is(200)
    ->content_like(qr/ok/);
}

$t->get_ok("$url/servers/status")
  ->status_is(200)
  ->json_is('', {
    $url => { map {( "$root/$_" => "up" )} qw/one two three four five/ }
  });

_mark_down($t,"two");
_mark_down($t,"three");
mkdir "$root/four";

eval {
  chmod(0555, "$root/four") || die "chmod failed: $!";
  if(open(my $fh, '>', "$root/four/test.txt"))
  {
    close $fh;
    unlink "$root/four/test.txt";
    die "apparently can write to a 0555 dir on this platform";
  }
};
my $chmod_error = $@;

$t->get_ok("$url/servers/status")
  ->status_is(200);

SKIP: {
  skip $chmod_error, 1 if $chmod_error;
  $t->json_is('', {
      $url => {
        (map {( "$root/$_" => "up" )} qw/one five/),
        (map {( "$root/$_" => "down" )} qw/two three four/)
      }
    });
}

_mark_down($t,"five");


my ($one,$two) = (0,0);
for my $i (1..$test_files) {
  my $content = "content $i";
  $t->put_ok("$url/file/filename_$i", {}, $content)
    ->status_is(201);
  for (b($content)->md5_sum) {
    /^[0-3]/i and $one++;
    /^[4-7]/i and $two++;
  }
}

TODO: {
  local $TODO = "run yars_fast_balance";
  my $json = $t->get_ok("$url/disk/usage?count=1")->status_is(200)->tx->res->json;
  is $json->{"$root/one"}{count}, $test_files;
  is $json->{"$root/$_"}{count}, 0 for qw/two three four five/;

  my $remaining = int($test_files - $two);
  $json = $t->get_ok("$url/disk/usage?count=1")->status_is(200)->tx->res->json;
  is $json->{"$root/one"}{count}, $remaining;
  is $json->{"$root/two"}{count}, $two;
  is $json->{"$root/$_"}{count}, 0 for qw/three four five/;

  # Ensure an invalid host causes an exception, not a request loop
  $t->post_ok("$url/disk/status", { "Content-Type" => "application/json" }, encode_json( { server => "http://101.010.0.0", root => "foo/bar", "state" => "up" }))
    ->status_is(400);
}

__DATA__

@@ etc/Yars.conf
---
% use Test::Clustericious::Config;
url : <%= cluster->url %>

servers :
    - url : <%= cluster->urls->[0] %>
      disks :
        - root : <%= data_dir('one') %>
          buckets : [0,1,2,3]
        - root : <%= data_dir('two') %>
          buckets : [4,5,6,7]
        - root : <%= data_dir('three') %>
          buckets : [8,9,'A','B']
        - root : <%= data_dir('four') %>
          buckets : ['C','D']
        - root : <%= data_dir('five') %>
          buckets : ['E','F']

state_file: <%= create_directory_ok('state') . "/state"; %>
