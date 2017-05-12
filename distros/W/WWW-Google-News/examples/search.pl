#!/usr/bin/perl

use lib "/home/scott/dev/WWW_Google_News";

use WWW::Google::News;

my $news = WWW::Google::News->new();
$news->topic("Frank Zappa");
$news->sort("date");
$news->start_date("2006-06-20");
$news->end_date("2006-06-20");
$news->max(2);
my $results = $news->search();
foreach (@{$results}) {
	print "Source: " . $_->{source} . "\n";
  print "Date: " . $_->{date} . "\n";
  print "URL: " . $_->{url} . "\n";
  print "Summary: " . $_->{summary} . "\n";
  print "Headline: " . $_->{headline} . "\n";
  print "\n";
}

