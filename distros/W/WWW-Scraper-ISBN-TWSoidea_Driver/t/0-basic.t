#!/usr/bin/env perl

use strict;
use Test::More tests => 13;

use_ok('WWW::Scraper::ISBN::TWSoidea_Driver');

ok($WWW::Scraper::ISBN::TWSoidea_Driver::VERSION) if $WWW::Scraper::ISBN::TWSoidea_Driver::VERSION or 1;

use WWW::Scraper::ISBN;
my $scraper = WWW::Scraper::ISBN->new();
isa_ok($scraper,'WWW::Scraper::ISBN');

$scraper->drivers("TWSoidea");
my $isbn = "9864175351";
my $record = $scraper->search($isbn);

SKIP: {
	skip($record->error."\n", 10) unless($record->found);

	is($record->found, 1);
	is($record->found_in, 'TWSoidea');

	my $book = $record->book;
	is($book->{'isbn'}, '9864175351');
	is($book->{'title'}, '藍海策略-開創無人競爭的全新市場');
	is($book->{'author'}, '金偉燦');
	is($book->{'book_link'}, 'http://www.soidea.com.tw/soidea/model_books_temp3.cfm?book_no=2665000751437');
	is($book->{'image_link'}, 'http://www.soidea.com.tw/bimages/sZ031/2665000751437.jpg');
	is($book->{'pubdate'}, '2005/08/06');
	is($book->{'publisher'}, '天下文化');
	is($book->{'price_list'}, '450');
}
