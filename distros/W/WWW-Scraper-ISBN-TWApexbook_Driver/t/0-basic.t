#!/usr/bin/env perl

use strict;
use Test::More tests => 12;

use_ok('WWW::Scraper::ISBN::TWApexbook_Driver');

ok($WWW::Scraper::ISBN::TWApexbook_Driver::VERSION) if $WWW::Scraper::ISBN::TWApexbook_Driver::VERSION or 1;

use WWW::Scraper::ISBN;
my $scraper = WWW::Scraper::ISBN->new();
isa_ok($scraper,'WWW::Scraper::ISBN');

$scraper->drivers("TWApexbook");
my $isbn = "0071244409";
my $record = $scraper->search($isbn);

SKIP: {
	skip($record->error."\n", 9) unless($record->found);

	is($record->found, 1);
	is($record->found_in, 'TWApexbook');

	my $book = $record->book;
	is($book->{'isbn'}, '0071244409');
	is($book->{'title'}, 'SERVICE MANAGEMENT: OPERATIONS, STRATEGY, INFORMATION TECHNOLOGY 5/E 2006 - 0071244409');
	is($book->{'author'}, 'FITZSIMMONS');
	is($book->{'book_link'}, 'http://www.apexbook.com.tw/index.php?php_mode=search&isbn=0071244409');
	is($book->{'image_link'}, 'http://www.apexbook.com.tw/bookcovers/Covers/0071244409.jpg');
	is($book->{'pubdate'}, '2006¦~');
	is($book->{'price_sell'}, '920');
}
