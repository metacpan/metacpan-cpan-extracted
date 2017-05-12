use strict;
use warnings;
use 5.010;
use Test::Clustericious::Log;
use Test::Clustericious::Config;
use Test::Clustericious::Cluster;
use Test::More tests => 916;
use Mojo::ByteStream qw( b );
use Mojo::Loader;
use File::Find::Rule;
use JSON::MaybeXS qw( decode_json );

my $root = create_directory_ok 'data';
create_config_helper_ok data_dir => sub {
  my $path = "$root/" . shift;
  mkdir $path unless -d $path;
  $path;
};

create_config_helper_ok state_file => sub {
  my $index = shift;
  state $dir;
  $dir //= create_directory_ok 'state';
  "$dir/$index";
};

sub url
{
  my @urls = map { Mojo::URL->new($_) } @_;
  $_->path("/") for @urls;
  map { $_->to_string } @urls;
}

$ENV{MOJO_MAX_MEMORY_SIZE} = 1;
my $cluster = Test::Clustericious::Cluster->new;
$cluster->create_cluster_ok(qw( Yars Yars ));
my @urls = @{ $cluster->urls };

my $ua = $cluster->t->ua;
$ua->max_redirects(3);
$_->tools->_set_ua(sub { $cluster->create_ua }) for @{ $cluster->apps };
is url($ua->get($urls[0].'/status')->res->json->{server_url}), url($urls[0]), "started first server at $urls[0]";
is url($ua->get($urls[1].'/status')->res->json->{server_url}), url($urls[1]), "started second server at $urls[1]";

my $i = 0;
my @contents = do {
  map { $_ x 5000 } @{ decode_json(Mojo::Loader::data_section('main', 'test_data.json')) };
};
my @locations;
my @md5s;
my @filenames;
for my $content (@contents) {
    $i++;
    my $filename = "file_numero_$i";
    push @filenames, $filename;
    push @md5s, b($content)->md5_sum;
    my $tx = $ua->put("$urls[1]/file/$filename", { "Content-MD5" => $md5s[-1] }, $content);
    my $location = $tx->res->headers->location;
    ok $location, "Got location header";
    ok $tx->success, "put $filename to $urls[1]/file/$filename";
    push @locations, $location;
    if ($i==20) {
        # Make a disk unwriteable.
        File::Find::Rule->new->exec(sub {
             chmod 0555, $_ })->in("$root/three");
        #ok ( (chmod 0555, "$root/three"), "chmod 0555, $root/three");
    }
    if ($i==60) {
        # Make both disks on one host unwriteable.
        File::Find::Rule->new->exec(sub { chmod 0555, $_ })->in("$root/four");
        #ok ( (chmod 0555, "$root/four"), "chmod 0555, $root/four");
        #ok ( (chmod 0555, "$root/four/tmp"), "chmod 0555, $root/four/tmp");
    }
}

for my $url (@locations) {
    my $want = shift @contents;
    my $md5  = shift @md5s;
    my $filename = shift @filenames;
    ok $url, "We have a location for $filename";
    next unless $url;
    for my $attempt ($url, "$urls[0]/file/$md5/$filename", "$urls[1]/file/$md5/$filename") {
        my $tx = $ua->get($attempt);
        my $res;
        ok $res = $tx->success, "got $attempt";
        my $body = $res ? $res->body : '';
        is $body, $want, "content match for $filename at $attempt";
    }

}

__DATA__

@@ etc/Yars.conf
---
url : <%= cluster->url %>

%# common configuration :
servers :
    - url : <%= cluster->urls->[0] %>
      disks :
        - root : <%= data_dir('one') %>
          buckets : [0,1,2,3]
        - root : <%= data_dir('two') %>
          buckets : [4,5,6,7]
    - url : <%= cluster->urls->[1] %>
      disks :
        - root : <%= data_dir('three') %>
          buckets : [8,9,A,B]
        - root : <%= data_dir('four') %>
          buckets : [C,D,E,F]

state_file: <%= state_file(cluster->index) %>

@@ test_data.json
["head -100 /usr/share/dict/words\n","1080\n","10-point\n","10th\n","11-point\n","12-point\n","16-point\n","18-point\n","1st\n","2\n","20-point\n","2,4,5-t\n","2,4-d\n","2D\n","2nd\n","30-30\n","3-D\n","3-d\n","3D\n","3M\n","3rd\n","48-point\n","4-D\n","4GL\n","4H\n","4th\n","5-point\n","5-T\n","5th\n","6-point\n","6th\n","7-point\n","7th\n","8-point\n","8th\n","9-point\n","9th\n","-a\n","A\n","A.\n","a\n","a'\n","a-\n","a.\n","A-1\n","A1\n","a1\n","A4\n","A5\n","AA\n","aa\n","A.A.A.\n","AAA\n","aaa\n","AAAA\n","AAAAAA\n","AAAL\n","AAAS\n","Aaberg\n","Aachen\n","AAE\n","AAEE\n","AAF\n","AAG\n","aah\n","aahed\n","aahing\n","aahs\n","AAII\n","aal\n","Aalborg\n","Aalesund\n","aalii\n","aaliis\n","aals\n","Aalst\n","Aalto\n","AAM\n","aam\n","AAMSI\n","Aandahl\n","A-and-R\n","Aani\n","AAO\n","AAP\n","AAPSS\n","Aaqbiye\n","Aar\n","Aara\n","Aarau\n","AARC\n","aardvark\n","aardvarks\n","aardwolf\n","aardwolves\n","Aaren\n","Aargau\n","aargh\n","Aarhus\n","Aarika\n","Aaron\n"]

