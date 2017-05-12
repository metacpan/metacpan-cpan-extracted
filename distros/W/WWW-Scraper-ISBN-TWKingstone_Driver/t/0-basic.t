#!/usr/bin/env perl

use strict;
use Test::More tests => 13;

use_ok('WWW::Scraper::ISBN::TWKingstone_Driver');

ok($WWW::Scraper::ISBN::TWKingstone_Driver::VERSION) if $WWW::Scraper::ISBN::TWKingstone_Driver::VERSION or 1;

use WWW::Scraper::ISBN;
my $scraper = WWW::Scraper::ISBN->new();
isa_ok($scraper,'WWW::Scraper::ISBN');

$scraper->drivers("TWKingstone");
my $isbn = "9864175351";
my $record = $scraper->search($isbn);

SKIP: {
	skip($record->error."\n", 10) unless($record->found);

	is($record->found, 1);
	is($record->found_in, 'TWKingstone');

	my $book = $record->book;
	is($book->{'isbn'}, '9864175351');
	is($book->{'title'}, '藍海策略');
	is($book->{'author'}, '金偉燦 / 莫伯尼');
	is($book->{'book_link'}, 'http://www.kingstone.com.tw/book/book_page.asp?kmcode=2024960224052');
	is($book->{'image_link'}, 'http://www.kingstone.com.tw/Book/images/Product/20249/2024960224052/2024960224052b.jpg');
	is($book->{'pubdate'}, '2005.07.29');
	is($book->{'publisher'}, '天下文化');
	is($book->{'price_list'}, '450');
}
