#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 14;
BEGIN { use_ok('WebService::Strike::Torrent') }

my %data = (
	leeches => 13,
	size => 615514112,
	torrent_hash => 'B425907E5755031BDA4A8D1B6DCCACA97DA14C04',
	file_count => 1,
	sub_category => '',
	torrent_category => 'Applications',
	file_info => {
		file_names => [ 'archlinux-2015.01.01-dual.iso' ],
		file_lengths => [ 615514112 ],
	},
	upload_date => 1420502400,
	seeds => 645,
	uploader_username => 'The_Doctor-',
	torrent_title => 'Arch Linux 2015.01.01 (x86/x64)'
);

my $t = WebService::Strike::Torrent->new(\%data);

is $t->hash, 'B425907E5755031BDA4A8D1B6DCCACA97DA14C04', 'hash';
is $t->title, 'Arch Linux 2015.01.01 (x86/x64)', 'title';
is $t->category, 'Applications', 'category';
is $t->sub_category, '', 'sub_category';
is $t->seeds, 645, 'seeds';
is $t->leeches, 13, 'leeches';
is $t->count, 1, 'count';
is $t->size, 615514112, 'size';
is $t->date, 1420502400,'date';
is $t->uploader, 'The_Doctor-', 'uploader';
is $t->names->[0], 'archlinux-2015.01.01-dual.iso', 'names';
is $t->lengths->[0], 615514112, 'lengths';
is $t->magnet, 'magnet:?xt=urn:btih:B425907E5755031BDA4A8D1B6DCCACA97DA14C04&dn=Arch%20Linux%202015.01.01%20%28x86%2Fx64%29', 'magnet';
