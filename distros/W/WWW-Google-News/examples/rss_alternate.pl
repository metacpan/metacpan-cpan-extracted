#!/usr/bin/perl -w

# This is an alternate implentation of an RSS feed, it was
# implemented by Darren Chamberlain in response to an item
# in the TODO list of 0.2. Unfortunatly a few moments before
# I received this I had already done rss.pl and uploaded
# 0.3 so i've included this as an alternate example and its
# probably better as he bothers to do things like escaping.
#

use strict;

use File::Basename qw(basename);
use WWW::Google::News qw(get_news);
use XML::RSS;

if (@ARGV) {
    my $o = basename $0;
    print "$o - Google News => RSS\n",
          "$o takes no options and prints to STDOUT.\n";
    exit 0;
  }

my ($news, $rss, $section, $item);

$news = get_news;
$rss = XML::RSS->new(version => "0.91");

$rss->channel(
    "title" => "Google News",
    "link"  => "http://news.google.com/news/gnmainlite.html",
);

$rss->image(
    "title" => "Google News",
    "url"   => "http://www.google.com/logos/Logo_25wht.gif",
    "link"  => "http://news.google.com/",
);

$rss->textinput(
    "title" => "Search Google News",
    "name"  => "q",
    "link"  => "http://news.google.com/news",
);

for $section (sort keys %$news) {
  for $item (@{ $news->{ $section } }) {
        $rss->add_item(
            "title" => $item->{'headline'},
            "link"  => escape($item->{'url'}),
        );
      }
}

print $rss->as_string;

sub escape {
    my $text = shift;
    $text =~ s/&(?!amp;)/&amp;/g;
    return $text;
}

