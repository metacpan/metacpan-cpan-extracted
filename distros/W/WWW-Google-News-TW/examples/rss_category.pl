#!/usr/bin/perl
# This is the program that can generate 
# seperate Google Taiwan News RSS (2.0)
# author: Cheng-Lung Sung
# version: 0.90
# create date: Mar 23 2005
# last update: Oct 28 2005
# license: Artistic (Perl)

use warnings;
use strict;

use lib '../blib/lib';
use WWW::Google::News::TW qw( get_news_for_category );
use CGI qw(:standard);
use Encode qw (from_to);
use XML::RSS;
#use Data::Dumper::Simple;
use Getopt::Long;

my $category = '';
GetOptions ('category=s' => \$category);
if ($category eq '') {
    $category = 'n';
}
my %categories = ('w' => '國際', 'n' => '台灣', 'b' => '財經', 't' => '科技',
    's' => '體育', 'e' => '娛樂', 'c' => '兩岸', 'y' => '社會');
my %ecats = ('國際' => 'International','台灣' => 'Taiwan','財經' => 'Business', '科技' => 'Sci/Tech',
    '體育' => 'Sport','娛樂' => 'Entertainment','兩岸' => 'Strait','社會' => 'Society');
my $rss = new XML::RSS (version => '2.0');
$rss->channel(title => "Google $ecats{$categories{$category}} News");
my $link = 'http://news.google.com.tw/?ned=tw&topic='.$category;
$rss->channel(description => "[$categories{$category}] 新聞 ", link => $link);
my $now = localtime;
$rss->channel(generator => 'clsung@tw.freebsd.org', pubDate => $now,
    language => 'utf-8', ttl => 30);

my $news = get_news_for_category($category);
#warn Dumper($news);
#exit;

for (@{$news}) {
    $rss->add_item(title => $_->{headline},
	description => $_->{summary}."...",
	link  => $_->{url},
	author => $_->{source},
	comments => $_->{related_url},
	pubDate => $_->{update_time}
    );
}

print $rss->as_string, "\n";

