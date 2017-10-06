#!/usr/bin/perl
use strict;
use warnings;

use Test::RequiresInternet ('a.4cdn.org' => 443, '8ch.net' => 443);
use Test::More tests => 17;

BEGIN { use_ok('WebService::Vichan', ':all') };

my @URLS = (API_4CHAN, API_8CHAN);

for my $url (@URLS) {
	note "Now testing $url";
	my $chan = WebService::Vichan->new($url);

	my @boards = $chan->boards;
	ok @boards > 0, 'has boards';

	my $board = $boards[0];
	my $boardcode = $board->board;

	my @threads = $chan->threads($board);
	my @threads_flat = $chan->threads_flat($board);
	ok @threads > 0, "board $boardcode has threads";

  SKIP: {
		skip 'race condition', 1 unless $ENV{RELEASE_TESTING};
		my $thread3a = $threads[0]->threads->[2];
		my $thread3b = $threads_flat[2];
		is $thread3a->no, $thread3b->no, 'same 3rd thread in threads and threads_flat';
	}

	my @catalog = $chan->catalog($board);
	my @catalog_flat = $chan->catalog_flat($board);
	ok @catalog > 0, "catalog of board $boardcode is not empty";

  SKIP: {
		skip 'race condition', 1 unless $ENV{RELEASE_TESTING};
		my $catalog3a = $catalog[0]->threads->[2];
		my $catalog3b = $catalog_flat[2];
		is $catalog3a->no, $catalog3b->no, 'same 3rd thread in catalog and catalog_flat';
	}

	my $catalog3 = $catalog_flat[2];
	my $catalog3no = $catalog3->no;
	ok defined $catalog3->com, 'catalog entry has content';

	my @posts = $chan->thread($board, $catalog3);
	ok @posts > 0, "thread $catalog3no has posts";

	is $catalog3->id, $posts[0]->id, 'catalog entry has same ID as first post';
}
