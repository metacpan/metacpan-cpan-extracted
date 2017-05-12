#!/usr/bin/env perl

use strict;
use Test::More tests => 14;

use_ok('WWW::Scraper::ISBN::TWTenlong_Driver');

ok($WWW::Scraper::ISBN::TWTenlong_Driver::VERSION) if $WWW::Scraper::ISBN::TWTenlong_Driver::VERSION or 1;

use WWW::Scraper::ISBN;
my $scraper = WWW::Scraper::ISBN->new();
isa_ok($scraper,'WWW::Scraper::ISBN');

$scraper->drivers("TWTenlong");
my $isbn = "9867794605";
my $record = $scraper->search($isbn);

SKIP: {
	skip($record->error."\n", 11) unless($record->found);

	is($record->found, 1);
	is($record->found_in, 'TWTenlong');

	my $book = $record->book;
	is($book->{'isbn'}, '9867794605');
	is($book->{'title'}, '深入淺出 Java 程式設計 (Head First Java, 2/e)');
	is($book->{'author'}, '楊尊一');
	is($book->{'pages'}, '688');
	is($book->{'book_link'}, 'http://www.tenlong.com.tw/BookSearch/Search.php?isbn=9867794605&sid=28153');
	is($book->{'image_link'}, 'http://www.tenlong.com.tw/BookSearch/cover/89/9867794605.gif');
	is($book->{'pubdate'}, '2005-10-25');
	is($book->{'publisher'}, 'O\'REILLY');
	is($book->{'price_list'}, '880');
}
