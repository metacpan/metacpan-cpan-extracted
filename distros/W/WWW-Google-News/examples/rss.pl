#!/usr/bin/perl


# This is a very simple example of how to use the scraper to
# provide an RSS feed. This is currently used by dipsy, #london.pm's bot.

use warnings;
use strict;

use XML::RSS;
use WWW::Google::News qw( get_news );
use CGI qw(:standard);


my $news = get_news();
my $topic = param('topic');

my $rss = XML::RSS->new(version => '0.91');
$rss->channel(title => "Google News");
$rss->channel(link  => '');


for (@{$news->{$topic}}) {
  $rss->add_item(title => $_->{headline},
                 link  => ''
                 #link  => $_->{url}
                );
}

#print "Content-type:text/plain\n\n";
print $rss->as_string, "\n";

