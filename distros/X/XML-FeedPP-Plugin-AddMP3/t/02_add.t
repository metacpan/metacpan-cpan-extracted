# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl XML-FeedPP-Plugin-AddMP3.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 11;
use XML::FeedPP;
use XML::FeedPP::Plugin::AddMP3;

my $item  = undef;
my @items = ();
my $feed = XML::FeedPP::RSS->new();
$feed->link('http://www.example.com/');

# 1
my $file = './t/test.mp3';
ok(-f $file, 'Test file existence');

# 2-4
ok($feed->call(AddMP3 => './t/test.mp3'), "Add file.");
ok(@items = $feed->get_item, "Get items.");
is(scalar(@items), 1, "Count items.");

# 5-11
my $date = &XML::FeedPP::Util::get_w3cdtf((stat($file))[9]);
$item = pop(@items);
is($item->title,   'テストMP3ファイル',  "Check item->title");
is($item->author,  'テストアーティスト', "Check item->author");
is($item->link,    $feed->link,          "Check item->link");
is($item->pubDate, $date,                "Check item->pubDate");
is($item->get('enclosure@url'),    't/test.mp3',  'Check item->enclosure@url');
is($item->get('enclosure@length'), '62655',       'Check item->enclosure@length');
is($item->get('enclosure@type'),    'audio/mpeg', 'Check item->enclosure@type');
