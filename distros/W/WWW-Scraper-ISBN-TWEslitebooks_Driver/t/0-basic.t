#!/usr/bin/env perl

use strict;
use Test::More tests => 15;

use_ok('WWW::Scraper::ISBN::TWEslitebooks_Driver');

ok($WWW::Scraper::ISBN::TWEslitebooks_Driver::VERSION) if $WWW::Scraper::ISBN::TWEslitebooks_Driver::VERSION or 1;

use WWW::Scraper::ISBN;
my $scraper = WWW::Scraper::ISBN->new();
isa_ok($scraper,'WWW::Scraper::ISBN');

$scraper->drivers("TWEslitebooks");
my $isbn = "9864175351";
my $record = $scraper->search($isbn);

SKIP: {
	skip($record->error."\n", 12) unless($record->found);

	is($record->found, 1);
	is($record->found_in, 'TWEslitebooks');

	my $book = $record->book;
	is($book->{'isbn'}, '9864175351');
	is($book->{'ean'}, '9789864175352');
	is($book->{'title'}, '藍海策略: 開創無人競爭的全新市場');
	like($book->{'author'}, qr/金偉燦/);
	is($book->{'pages'}, '355');
	is($book->{'book_link'}, 'http://www.eslitebooks.com/Program/Object/BookCN.aspx?PageNo=&PROD_ID=2611393953002');
	is($book->{'image_link'}, 'http://www.eslitebooks.com/EsliteBooks/book/picture/M/2910486972006.jpg');
	is($book->{'pubdate'}, '20050805');
	is($book->{'publisher'}, '天下遠見出版股份有限公司');
	is($book->{'price_list'}, '450');
}
