use strict;

use Test::More tests => 7;
use XML::FOAF;
use File::Basename qw( dirname );
use File::Spec;
use URI;
use LWP::UserAgent;

use constant BASE => 'http://stupidfool.org/perl/foaf/';

my $dir = File::Spec->rel2abs(dirname($0));
my $test_file = File::Spec->catfile($dir, 'samples', 'bare.foaf');
die "$test_file does not exist" unless -e $test_file;
my $foaf;

ok($foaf = XML::FOAF->new(URI->new('file:/' . $test_file)));
ok($foaf->foaf_url('file:/' . $test_file));

ok(XML::FOAF->new($test_file, 'http://foo.com'));

open my $fh, $test_file or die $!;
ok(XML::FOAF->new($fh, 'http://foo.com'));

seek $fh, 0, 0;
my $data = do { local $/; <$fh> };
ok(XML::FOAF->new(\$data, 'http://foo.com'));

my $ua = LWP::UserAgent->new;
my $req = HTTP::Request->new(GET => BASE . 'base.html');
my $res = $ua->request($req);
my $foaf_url = XML::FOAF->find_foaf_in_html(\$res->content, BASE . 'base.html');
ok($foaf_url);
is($foaf_url, BASE . 'foaf.rdf');
