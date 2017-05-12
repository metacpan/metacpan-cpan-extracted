use strict;
use warnings;
BEGIN { $ENV{MOJO_NO_IPV6} = 1; $ENV{MOJO_NO_TLS} = 1; $ENV{YARS_CONNECT_TIMEOUT} = $ENV{MOJO_CONNECT_TIMEOUT} = 1 }
use 5.010;
use Test::Clustericious::Log diag => 'NONE';
use Test::Clustericious::Config;
use Test::Clustericious::Cluster;
use Test::More;
use Mojo::ByteStream qw( b );
use Mojo::Loader;
use JSON::MaybeXS qw( decode_json );
use IO::Socket::INET;
use Yars::Util qw( format_tx_error );

plan skip_all => 'cannot turn off Mojo IPv6'
  if IO::Socket::INET->isa('IO::Socket::IP');

plan tests => 373;

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

my $cluster = Test::Clustericious::Cluster->new;
$cluster->create_cluster_ok(qw( Yars Yars ));
my $t = $cluster->t;
my @urls = @{ $cluster->urls };

my $ua = $cluster->t->ua;
$ua->max_redirects(3);
$_->tools->_set_ua(sub { my $ua = $cluster->create_ua; $ua }) for @{ $cluster->apps };

is url($ua->get($urls[0].'/status')->res->json->{server_url}), url($urls[0]), "started first server at $urls[0]";
is url($ua->get($urls[1].'/status')->res->json->{server_url}), url($urls[1]), "started second server at $urls[1]";

my $i = 0;
my @contents = do {
  @{ decode_json(Mojo::Loader::data_section('main', 'test_data.json')) };
};
my @locations;
my %assigned; # server => { disk => count }
for my $content (@contents) {
    for (b($content)->md5_sum) {
        /^[0-3]/i  and $assigned{"http://localhost:9051"}{"$root/one"}{count}++;
        /^[4-7]/i  and $assigned{"http://localhost:9051"}{"$root/two"}{count}++;
        /^[89AB]/i and $assigned{"http://localhost:9052"}{"$root/three"}{count}++;
        /^[CDEF]/i and $assigned{"http://localhost:9052"}{"$root/four"}{count}++;
    }
    $i++;
    my $filename = "file_numero_$i";
    my $tx = $ua->put("$urls[0]/file/$filename", {}, $content);
    my $location = $tx->res->headers->location;
    ok $location, "Got location header";
    ok $tx->success, "put $filename to $urls[0]/file/$filename";
    push @locations, $location;
    if ($i==20) {
        $cluster->stop_ok(1);
    }
}

$i = 0;
for my $url (@locations) {
    my $want = shift @contents;
    next unless $url;
    next if $i++ < 20; # skip ones that went to host that died
    my $tx = $ua->get($url);
    my $res;
    ok $res = $tx->success, "got $url";
    my $body = $res ? $res->body : '';
    is $body, $want, "content match for file $i at $url";
}

# Now start it back up.
$cluster->start_ok(1);

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
["tail -100 /usr/share/dict/words\n","Zygosaccharomyces\n","zygose\n","zygoses\n","zygosis\n","zygosities\n","zygosity\n","zygosperm\n","zygosphenal\n","zygosphene\n","zygosphere\n","zygosporange\n","zygosporangium\n","zygospore\n","zygosporic\n","zygosporophore\n","zygostyle\n","zygotactic\n","zygotaxis\n","zygote\n","zygotene\n","zygotenes\n","zygotes\n","zygotic\n","zygotically\n","zygotoblast\n","zygotoid\n","zygotomere\n","-zygous\n","zygous\n","zygozoospore\n","zym-\n","zymase\n","zymases\n","-zyme\n","zyme\n","zymes\n","zymic\n","zymin\n","zymite\n","zymo-\n","zymochemistry\n","zymogen\n","zymogene\n","zymogenes\n","zymogenesis\n","zymogenic\n","zymogenous\n","zymogens\n","zymogram\n","zymograms\n","zymoid\n","zymologic\n","zymological\n","zymologies\n","zymologist\n","zymology\n","zymolyis\n","zymolysis\n","zymolytic\n","zymome\n","zymometer\n","zymomin\n","zymophore\n","zymophoric\n","zymophosphate\n","zymophyte\n","zymoplastic\n","zymosan\n","zymosans\n","zymoscope\n","zymoses\n","zymosimeter\n","zymosis\n","zymosterol\n","zymosthenic\n","zymotechnic\n","zymotechnical\n","zymotechnics\n","zymotechny\n","zymotic\n","zymotically\n","zymotize\n","zymotoxic\n","zymurgies\n","zymurgy\n","Zyrenian\n","Zyrian\n","Zyryan\n","Zysk\n","zythem\n","Zythia\n","zythum\n","Zyzomys\n","Zyzzogeton\n","zyzzyva\n","zyzzyvas\n","ZZ\n","Zz\n","zZt\n","ZZZ\n"]
