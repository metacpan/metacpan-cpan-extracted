#!/usr/bin/env perl

use strict;
use Test::More tests => 13;

use_ok('WWW::Scraper::ISBN::TWSanmin_Driver');

ok($WWW::Scraper::ISBN::TWSanmin_Driver::VERSION) if $WWW::Scraper::ISBN::TWSanmin_Driver::VERSION or 1;

use WWW::Scraper::ISBN;
my $scraper = WWW::Scraper::ISBN->new();
isa_ok($scraper,'WWW::Scraper::ISBN');

$scraper->drivers("TWSanmin");
my $isbn = "9864175351";
my $record = $scraper->search($isbn);

SKIP: {
	skip($record->error."\n", 10) unless($record->found);

	is($record->found, 1);
	is($record->found_in, 'TWSanmin');

	my $book = $record->book;
	is($book->{'isbn'}, '9864175351');
	is($book->{'title'}, '藍海策略：開創無人競爭的全新市場');
	is($book->{'author'}, '金偉燦');
	is($book->{'book_link'}, 'http://www.sanmin.com.tw/page-product.asp?pid=319242&pf_id=000434530');
	is($book->{'image_link'}, 'http://www.sanmin.com.tw/Assets/product_images/986417535.jpg');
	is($book->{'pubdate'}, '94/08/01');
	is($book->{'publisher'}, '天下文化書坊');
	is($book->{'price_list'}, '450');
}
