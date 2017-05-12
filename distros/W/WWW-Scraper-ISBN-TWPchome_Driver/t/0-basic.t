#!/usr/bin/env perl

use strict;
use Test::More tests => 14;

use_ok('WWW::Scraper::ISBN::TWPchome_Driver');

ok($WWW::Scraper::ISBN::TWPchome_Driver::VERSION) if $WWW::Scraper::ISBN::TWPchome_Driver::VERSION or 1;

use WWW::Scraper::ISBN;
my $scraper = WWW::Scraper::ISBN->new();
isa_ok($scraper,'WWW::Scraper::ISBN');

$scraper->drivers("TWPchome");
my $isbn = "9864175351";
my $record = $scraper->search($isbn);

SKIP: {
	skip($record->error."\n", 11) unless($record->found);

	is($record->found, 1);
	is($record->found_in, 'TWPchome');

	my $book = $record->book;
	is($book->{'isbn'}, '986-417-535-1');
	is($book->{'title'}, '藍海策略 － 開創無人競爭的全新市場');
	is($book->{'author'}, '金偉燦、莫伯尼   合著');
	is($book->{'pages'}, '376');
	is($book->{'book_link'}, 'http://ec2.pchome.com.tw/case/000334/00033424.htm');
	is($book->{'image_link'}, 'http://ec2img.pchome.com.tw/case/000334/00033424/BIG.jpg');
	is($book->{'pubdate'}, '2005 年 08 月 05 日');
	is($book->{'publisher'}, '天下文化');
	is($book->{'price_list'}, '450');
}
