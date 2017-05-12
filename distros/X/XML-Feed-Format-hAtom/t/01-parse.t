# $Id: 01-parse.t 1921 2006-02-28 02:50:52Z btrott $

use strict;
use Test::More tests => 50;
use XML::Feed;
use URI;

my %Feeds = (
    't/samples/hatom-implicit.html' => 'hAtom',
    't/samples/hatom-explicit.html' => 'hAtom',
);

## First, test all of the various ways of calling parse.
my $feed;
my $file = 't/samples/hatom-explicit.html';
$feed = XML::Feed->parse($file);
isa_ok($feed, 'XML::Feed::Format::hAtom');
is($feed->title, 'First Weblog');
open my $fh, $file or die "Can't open $file: $!";
$feed = XML::Feed->parse($fh);
isa_ok($feed, 'XML::Feed::Format::hAtom');
is($feed->title, 'First Weblog');
seek $fh, 0, 0;
my $xml = do { local $/; <$fh> };
$feed = XML::Feed->parse(\$xml);
isa_ok($feed, 'XML::Feed::Format::hAtom');
is($feed->title, 'First Weblog');
$feed = XML::Feed->parse(URI->new("file:$file"));
isa_ok($feed, 'XML::Feed::Format::hAtom');
is($feed->title, 'First Weblog');

## Then try calling all of the unified API methods.
for my $file (sort keys %Feeds) {
    my $feed = XML::Feed->parse($file) or die XML::Feed->errstr;
    my($subclass) = $Feeds{$file} =~ /^(\w+)/;
    isa_ok($feed, 'XML::Feed::Format::' . $subclass);
    is($feed->format, $Feeds{$file}, "Feed is the correct format");
    is($feed->language, 'en-us', "Got the correct feed language from $file");
    is($feed->title, 'First Weblog', "Got the correct feed title from $file");
    is($feed->link, 'http://localhost/weblog/', "Got the correct feed link from $file");
    is($feed->tagline, 'This is a test weblog.', "Got the correct feed tagline from $file");
    is($feed->description, 'This is a test weblog.', "Got the correct feed description $file");
    my $dt = $feed->modified;
    isa_ok($dt, 'DateTime');
    $dt->set_time_zone('UTC');
    is($dt->iso8601, '2004-05-30T07:39:57', "Got the correct feed date from $file");
    is($feed->author, 'Melody', "Got the correct feed author from $file");

    my @entries = $feed->entries;
    is(scalar @entries, 2, "Got the correct number of entries from $file");
    my $entry = $entries[0];
    is($entry->title, 'Entry Two', "Got the correct entry title from $file");
    is($entry->link, 'http://localhost/weblog/2004/05/entry_two.html', "Got the correct entry link from $file");
    $dt = $entry->issued;
    isa_ok($dt, 'DateTime');
    $dt->set_time_zone('UTC');
    is($dt->iso8601, '2004-05-30T07:39:25', "Got the correct entry issued date from $file");
    like($entry->content->body, qr/<p>Hello!<\/p>/, "Got the correct entry content from $file");
    is($entry->summary->body, 'Hello!...', "Got the correct entry summary from file");
    is(($entry->category)[0], 'Travel', "Got the correct entry category from file");
    is($entry->category, 'Travel', "Got the correct entry category from file again");
    is($entry->author, 'Melody', "Got the correct entry author from file");
    ok($entry->id, "Got the entry id from file");
}

