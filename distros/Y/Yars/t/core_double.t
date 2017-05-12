use strict;
use warnings;
use Test::Clustericious::Log;
use Test::Clustericious::Config;
use Test::Clustericious::Cluster;
use Test::More tests => 105;
use Mojo::ByteStream qw( b );
use Mojo::Loader;
use JSON::MaybeXS qw( encode_json );
use Yars::Util qw( format_tx_error );

my $root = create_directory_ok 'data';
my $state = create_directory_ok 'state';
mkdir "$root/one";
mkdir "$root/two";
create_config_helper_ok data_dir => sub { $root . "/" . shift };
create_config_helper_ok state_file => sub { $state . "/" . shift };

my $cluster = Test::Clustericious::Cluster->new;
$cluster->create_cluster_ok(qw( Yars Yars ));
my $t = $cluster->t;
my @url = @{ $cluster->urls };

sub _normalize {
    my ($one) = @_;
    return [ sort { $a->{md5} cmp $b->{md5} } @$one ];
}

$t->get_ok("$url[0]/status")
  ->status_is(200);
$t->get_ok("$url[1]/status")
  ->status_is(200);

$t->ua->max_redirects(3);
$_->tools->_set_ua(sub { $cluster->create_ua }) for @{ $cluster->apps };

$t->get_ok("$url[0]/servers/status");
is_deeply($t->tx->res->json, {
        $url[0] => { "$root/one" => "up" },
        $url[1] => { "$root/two" => "up" },
    }
);

my $i = 0;
my @contents = map { "$_\n" } split /\n/, Mojo::Loader::data_section('main', 'data');
my @locations;
my @digests;
my @filenames;
my @sizes;
for my $content (@contents) {
    $i++;
    my $filename = "file_numero_$i";
    push @filenames, $filename;
    push @digests, b($content)->md5_sum;
    push @sizes, b($content)->size;
    my $tx = $t->ua->put("$url[1]/file/$filename", {}, $content);
    my $location = $tx->res->headers->location;
    ok $location, "Got location header";
    ok $tx->success, "put $filename to $url[1]/file/filename";
    push @locations, $location;
}

my $manifest;
my @filelist;
$i = 0;
for my $url (@locations) {
    my $content  = $contents[$i];
    my $filename = $filenames[$i];
    my $size     = $sizes[$i];
    my $md5      = $digests[ $i++ ];
    $manifest .= "$md5  $filename\n";
    push @filelist, { filename => $filename, md5 => "$md5" };
    next unless $url; # error will occur above
    {
        my $tx = $t->ua->get($url);
        my $res;
        ok $res = $tx->success, "got $url";
        is $res->body, $content, "content match";
    }
    {
        my $tx = $t->ua->head("$url[0]/file/$md5/$filename");
        ok $tx->success, "head $url[0]/file/$md5/$filename";
        is $tx->res->headers->content_length, $size;
    }
}

$manifest .= "11f488c161221e8a0d689202bc8ce5cd  dummy\n";

my $tx = $t->ua->post( "$url[0]/check/manifest?show_found=1", { "Content-Type" => "application/json" },
    encode_json( { manifest => $manifest } ) );
my $res = $tx->success;
ok $res, "posted to manifest";
is $res->code, 200, "got 200 for manifest";
ok eq_set( $res->json->{missing},
    [ { filename => "dummy", md5 => "11f488c161221e8a0d689202bc8ce5cd" } ] ),
  "none missing";
is_deeply (_normalize($res->json->{found}),_normalize(\@filelist),'found all');

for my $url (@locations) {
    my $content  = shift @contents;
    my $filename = shift @filenames;
    my $md5      = shift @digests;
    {
        my $tx = $t->ua->delete("$url[0]/file/$md5/$filename");
        ok $tx->success, "delete $url[0]/file/$md5/$filename";
        diag format_tx_error($tx->error) if $tx->error;
    }
    {
        my $tx = $t->ua->get("$url[0]/file/$md5/$filename");
        is $tx->res->code, 404, "Not found after deleting";
        $tx = $t->ua->get("$url[1]/file/$md5/$filename");
        is $tx->res->code, 404, "Not found after deleting";
    }
}

__DATA__

@@ etc/Yars.conf
---
url : <%= cluster->url %>

servers :
    - url : <%= cluster->urls->[0] %>
      disks :
        - root : <%= data_dir('one') %>
          buckets : [0,1,2,3,4,5,6,7]
    - url : <%= cluster->urls->[1] %>
      disks :
        - root : <%= data_dir('two') %>
          buckets : [8,9,A,B,C,D,E,F]

state_file: <%= state_file(cluster->index) %>

@@ data
this is one file
this is another file
this is a third file
these files are all different
no two are the same
and some of them have md5s that make them go to
the first server, while others go to the
second server.
Every file is one line long.
buh bye
