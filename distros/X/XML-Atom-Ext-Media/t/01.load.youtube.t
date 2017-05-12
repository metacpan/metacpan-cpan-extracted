#!/usr/bin/perl -w

use strict;
use Test::More 0.92;
use XML::Atom::Feed;
use XML::Atom::Ext::Media;

my $feed = XML::Atom::Feed->new('t/feeds/atom_youtube.xml');

{
    my @entries = $feed->entries;
    my @media = $entries[0]->group;

    isa_ok($media[0], "XML::Atom::Ext::Media::Group");

    {
        my $media = $media[0];
        is($media->title, "First Slackline JumpOn");
        my ($content) = $media->content;
        isa_ok($content, "XML::Atom::Ext::Media::Content");

        my @thumbs = $media->thumbnails;
        is(scalar(@thumbs), 4);
        {
            my $thumb = $thumbs[0];
            is($thumb->url, 'http://i.ytimg.com/vi/7c5hyVc_jPk/2.jpg');
            is($thumb->height, "90");
            is($thumb->width, "120");
        }
    }
    
}
{
    my ($entry) = $feed->entries;
    my ($media) = $entry->media_groups;
    is($media->title, "First Slackline JumpOn");
    is($media->thumbnail->url, "http://i.ytimg.com/vi/7c5hyVc_jPk/2.jpg");
    my $content = $media->default_content;
    is($content->type, "application/x-shockwave-flash");
}

done_testing();
