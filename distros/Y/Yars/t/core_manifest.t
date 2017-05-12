use strict;
use warnings;
use Test::Clustericious::Config;
use Test::Clustericious::Cluster;
use Test::More tests => 31;
use Mojo::ByteStream qw( b );
use Digest::file qw/digest_file_hex/;
use JSON::MaybeXS qw( encode_json );

my $root = create_directory_ok 'data';
create_config_helper_ok data_dir => sub { $root };

my $cluster = Test::Clustericious::Cluster->new;
$cluster->create_cluster_ok(qw( Yars ));
my $t = $cluster->t;
my $url = $cluster->url;

my $count = 10;

my @filenames = map "filename_$_", 0..$count-1;
my @contents  = map "$_"x10, 0..$count-1;
my @md5s      = map b($_)->md5_sum, @contents;

my @missing_filenames = map "filename_$_", $count..$count+5;
my @missing_contents  = map "$_"x10, $count..$count+5;
my @missing_md5s      = map b($_)->md5_sum, @missing_contents;


for (0..$count-1) {
    $t->put_ok("$url/file/$filenames[$_]", { }, $contents[$_])->status_is(201);
}

my $manifest = join "\n", map "$md5s[$_]  some/stuff/$filenames[$_]", 0..$count-1;
$manifest .= "\n";
$manifest .= join "\n", map "$missing_md5s[$_]  not/there/$missing_filenames[$_]", 0..5;

$t->post_ok(
    "$url/check/manifest?show_found=1",
    { "Content-Type" => "application/json" },
    encode_json( { manifest => $manifest } )
)->status_is(200)
 ->json_is('', {
    missing => [ map +{ filename => $missing_filenames[$_], md5 => $missing_md5s[$_] }, 0..5 ],
    found   => [ map +{ filename => $filenames[$_], md5 => $md5s[$_] }, 0..$count-1 ],
} );

# Make a file corrupt and check for it.
my $corrupt_filename = splice @filenames, 2, 1;
my $corrupt_md5 = splice @md5s, 2, 1;
my $corrupt_path = join '/', $root, grep defined, ( $corrupt_md5 =~ /(..)/g ), $corrupt_filename;
ok -e $corrupt_path, "$corrupt_path exists";
open my $fp, ">>$corrupt_path" or die $!;
print $fp "extra";
close $fp;
$corrupt_md5 = digest_file_hex($corrupt_path,'MD5');

$t->post_ok(
    "$url/check/manifest?show_found=1&show_corrupt=1",
    { "Content-Type" => "application/json" },
    encode_json( { manifest => $manifest } )
)->status_is(200)
 ->json_is('', {
    missing => [ map +{ filename => $missing_filenames[$_], md5 => $missing_md5s[$_] }, 0..5 ],
    found   => [ map +{ filename => $filenames[$_], md5 => $md5s[$_] }, 0..$count-2 ],
    corrupt => [ { filename => $corrupt_filename, md5 => $corrupt_md5 } ],
} );

__DATA__

@@ etc/Yars.conf
---
% use Test::Clustericious::Config;
url : <%= cluster->url %>

servers :
    - url : <%= cluster->urls->[0] %>
      disks :
        - root : <%= data_dir %>
          buckets : [0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F]

state_file: <%= create_directory_ok('state') . "/state" %>
