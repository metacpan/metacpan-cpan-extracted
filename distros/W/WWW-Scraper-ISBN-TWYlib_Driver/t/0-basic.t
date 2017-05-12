#!/usr/bin/env perl

use strict;
use Test::More tests => 13;

use_ok('WWW::Scraper::ISBN::TWYlib_Driver');

ok($WWW::Scraper::ISBN::TWYlib_Driver::VERSION) if $WWW::Scraper::ISBN::TWYlib_Driver::VERSION or 1;

use WWW::Scraper::ISBN;
my $scraper = WWW::Scraper::ISBN->new();
isa_ok($scraper,'WWW::Scraper::ISBN');

$scraper->drivers("TWYlib");
my $isbn = "9573202522";
my $record = $scraper->search($isbn);

SKIP: {
	skip($record->error."\n", 10) unless($record->found);

	is($record->found, 1);
	is($record->found_in, 'TWYlib');

	my $book = $record->book;
	is($book->{'isbn'}, '9573202522');
	is($book->{'ean'}, '9789573202523');
	is($book->{'title'}, '¥|¤Q¦Û­z');
	is($book->{'author'}, '­J  ¾A');
	is($book->{'book_link'}, 'http://www.ylib.com/search/ShowBook.asp?BookNo=C1001');
	is($book->{'image_link'}, 'http://www.ylib.com/BookImg/C1/C1001.jpg');
	is($book->{'pubdate'}, '75/06/30');
	is($book->{'price_list'}, '120');
}
