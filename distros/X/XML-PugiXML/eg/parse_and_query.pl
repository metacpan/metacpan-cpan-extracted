#!/usr/bin/env perl
# Parse XML and query with XPath
use strict;
use warnings;
use XML::PugiXML;

binmode STDOUT, ':utf8';

my $doc = XML::PugiXML->new;
$doc->load_string(<<'XML') or die "Parse failed: $@";
<library>
  <book id="1" lang="en">
    <title>The Pragmatic Programmer</title>
    <author>David Thomas</author>
    <year>2019</year>
  </book>
  <book id="2" lang="ja">
    <title>&#x30D7;&#x30ED;&#x30B0;&#x30E9;&#x30DF;&#x30F3;&#x30B0;Perl</title>
    <author>Larry Wall</author>
    <year>2000</year>
  </book>
  <book id="3" lang="en">
    <title>Design Patterns</title>
    <author>Gang of Four</author>
    <year>1994</year>
  </book>
</library>
XML

# Single node query
my $first = $doc->select_node('//book[@id="1"]/title');
printf "First book: %s\n", $first->text;

# Multi-node query
my @books = $doc->select_nodes('//book');
printf "Total books: %d\n", scalar @books;

# Compiled XPath for repeated use
my $xpath = $doc->compile_xpath('//book[year > 1999]');
my $root  = $doc->root;
for my $book ($xpath->evaluate_nodes($root)) {
    printf "  Post-2000: %s (%s)\n", $book->child('title')->text,
                                      $book->child('year')->text;
}

# XPath functions via compiled queries
my $count_xpath = $doc->compile_xpath('count(//book)');
printf "count(//book) = %.0f\n", $count_xpath->evaluate_number($root);

my $title_xpath = $doc->compile_xpath('string(//book[@id="2"]/title)');
printf "Book 2 title: %s\n", $title_xpath->evaluate_string($root);
