#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More tests => 9;
BEGIN { use_ok('WWW::Search::Torrentz::Result') };

my $result = WWW::Search::Torrentz::Result->new(
	title => 'Title',
	verified => 4,
	age => 'age',
	size => 'size',
	seeders => 50,
	leechers => 50,
	infohash => '514131e668a8134bca9668ef2e19e690924adf86',
);

is $result->title, 'Title', 'title';
is $result->verified, 4, 'verified';
is $result->age, 'age', 'age';
is $result->size, 'size', 'size';
is $result->seeders, 50, 'seeders';
is $result->leechers, 50, 'leechers';
is $result->infohash, '514131e668a8134bca9668ef2e19e690924adf86', 'infohash';
is $result->magnet, 'magnet:?xt=urn:btih:514131e668a8134bca9668ef2e19e690924adf86&dn=Title', 'magnet';
