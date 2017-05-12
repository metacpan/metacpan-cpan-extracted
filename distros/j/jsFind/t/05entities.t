#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;
use blib;
use jsFind;

BEGIN { use_ok('jsFind'); }

my $t = new jsFind B => 4;

my $i = 0;
foreach my $k (qw{
		&acirc; &ecirc; &egrave; &iuml; &ucirc; &foobar; lt_< gt_>
		èevapèiæ ¾aba ¹kola
	}) {
	$t->B_search(Key => $k,
     		Data => { "path to $k" => {
				t => "entity $k",
				f => $i },
			},
		Insert => 1,
		Append => 1,
	);
	$i++;
}

if (open(T,"| sort > entities.txt")) {
	print T $t->to_string;
	diag "entities saved in entities.txt";
	close(T);
}

my $tree_size = 0;
open(T, "entities.txt") || die "can't open entities.txt: $!";
while(<T>) {
	$tree_size++;
}

cmp_ok($tree_size, '==', $i, "insert $tree_size/$i");

ok($t->to_jsfind(
	dir => './html/entities',
	data_codepage => 'ISO-8859-2'
), "save to index");

ok($t->to_jsfind(
	dir => './html/entities-utf8',
	data_codepage => 'ISO-8859-2',
	index_codepage => 'UTF-8'
), "save to utf-8 index");

#ok_fail(


