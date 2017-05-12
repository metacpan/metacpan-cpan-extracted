# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl XML-FeedPP-Plugin-AddMP3.t'

#########################

use Test::More tests => 10;
use XML::FeedPP;
use XML::FeedPP::Plugin::AddMP3;

my $base_dir = 't';
my $base_url = 'http://podcast.example.com/mp3/';
my $link_url = 'http://podcast.example.com/';
my $item  = undef;
my @items = ();
my $feed = XML::FeedPP::RSS->new();
$feed->link('http://www.example.com/');

# 1
my $file = './t/test.mp3';
ok(-f $file, 'Test file existence');


# 2-3
ok($feed->call(
	AddMP3 => './t/test.mp3',
	base_dir   => $base_dir
), "Add file with base_dir.");
@items = $feed->get_item;
$item  = pop(@items);
is($item->get('enclosure@url'), 'test.mp3', "Check base_dir.");

# 4-5
ok($feed->call(
	AddMP3 => './t/test.mp3',
	base_url   => $base_url
), "Add file with base_url.");
@items = $feed->get_item;
$item  = pop(@items);
is($item->get('enclosure@url'), "${base_url}t/test.mp3", "Check base_url.");

# 6-7
ok($feed->call(
	AddMP3 => './t/test.mp3',
	link_url   => $link_url
), "Add file with link_url.");
@items = $feed->get_item;
$item = pop(@items);
is($item->link, 'http://podcast.example.com/', "Check link_url.");

# 8-10
ok($feed->call(
	AddMP3 => './t/test.mp3',
	base_dir   => $base_dir,
	base_url   => $base_url,
	link_url   => $link_url
), "Add file with base_dir, base_url, link_url.");
@items = $feed->get_item;
$item = pop(@items);
is($item->get('enclosure@url'), "${base_url}test.mp3", "Check base_dir, base_url.");
is($item->link, 'http://podcast.example.com/', "Check link_url.");
