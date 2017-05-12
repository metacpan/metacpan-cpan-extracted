# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl XML-FeedPP-Plugin-AddMP3.t'

#########################

use Test::More tests => 7;
use XML::FeedPP;
use XML::FeedPP::Plugin::AddMP3;

use Data::Dumper;
local $Data::Dumper::Indent = 1;
local $Data::Dumper::Sortkeys = 1;

my $base_dir = 't';
my $base_url = 'http://podcast.example.com/mp3/';
my $link_url = 'http://podcast.example.com/';
my $xmlns_url = 'http://www.itunes.com/DTDs/Podcast-1.0.dtd';
my @items = ();
my $item = undef;
my $feed = XML::FeedPP::RSS->new();
$feed->link('http://www.example.com/');

# 1
my $file = './t/test.mp3';
ok(-f $file, 'Test file existence');

# 2-7
ok($feed->call(
	AddMP3 => './t/test.mp3',
	base_dir   => $base_dir,
	base_url   => $base_url,
	link_url   => $link_url,
	use_itunes => 1
), "Add file with base_dir, base_url, link_url.");
@items = $feed->get_item;
$item = pop(@items);
is($feed->xmlns('xmlns:itunes'),  $xmlns_url,                 "feed->xmlns:itunes");
is($item->get('itunes:author'),   'テストアーティスト',       "itunes:author");
is($item->get('itunes:duration'), '00:30',                    "itunes:duration");
is($item->get('itunes:keywords'), 'テストアーティスト, 2007', "itunes:keywords");
is($item->get('itunes:subtitle'), 'テストアルバム, 1/5',      "itunes:subtitle");
