use strict;
use warnings;
use Test::More tests => 2;
use XML::Feed::Deduper;
use File::Temp;
use FindBin;
use URI;

my $tmp = File::Temp->new(UNLINK => 1);

my $deduper = XML::Feed::Deduper->new(
    path => $tmp->filename,
    compare_body => 1,
);

{
    my $feed = XML::Feed->parse( URI->new("file://$FindBin::Bin/samples/01.rss") )
    or die XML::Feed->errstr;
    my @entries = $deduper->dedup($feed->entries);
    is(join(' ', map { $_->link } @entries), 'http://example.com/entry/1');
}

{
    my $feed = XML::Feed->parse( URI->new("file://$FindBin::Bin/samples/02.rss") )
    or die XML::Feed->errstr;
    my @entries = $deduper->dedup($feed->entries);
    is(join(' ', map { $_->link } @entries), 'http://example.com/entry/1 http://example.com/entry/2');
}

