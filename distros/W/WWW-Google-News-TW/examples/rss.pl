#!/usr/bin/perl
# This is the program that can generate Google Taiwan News RSS (0.91)
# author: Cheng-Lung Sung
# version: 0.90
# create date: Sep 9 2004
# last update: Sep 10 2004
# license: Artistic (Perl)

use warnings;
use strict;

use lib '../blib/lib';
use WWW::Google::News::TW qw( get_news );
use CGI qw(:standard);
use Encode qw (from_to);
use XML::RSS;
#use Data::Dumper::Simple;

my $news = get_news();
#warn Dumper($news);
#exit;

my $rss = new XML::RSS (version => '0.91');
$rss->channel(title => "Google Taiwan News");
$rss->channel(link  => 'http://news.google.com.tw/news?ned=ttw');
my @keys = ('焦點','國際','台灣','財經','科技','體育','娛樂','兩岸','社會');
$rss->channel(description => join(' ',@keys).' 各六篇');

for (@keys) {
    my $section = $_;
    for (@{$news->{$section}}) {
	$rss->add_item(title => "[$section] ".$_->{headline},
	    description => $_->{summary}."...",
	    link  => $_->{url}
	);
    }
    #Encode::from_to($_, 'utf8', 'big5');
#    print STDERR $_;
}

sub section_sort {
    my $aa = $a;
    my $bb = $b;
    Encode::from_to($aa, 'utf8', 'big5');
    Encode::from_to($bb, 'utf8', 'big5');
    print STDERR "$aa <> $bb (".($a cmp $b)."\n";
    if ($a eq '焦點') { return -1; }
    if ($b eq '焦點') { return 1; }
    return $a cmp $b;
}
print $rss->as_string, "\n";

