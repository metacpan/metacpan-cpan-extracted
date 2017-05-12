#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 15;
use Test::Exception;
use Tree::SEMETrie;

my @keys = qw{
	b
	aaaaa
	abaaa
	abaab
	aaaa
	abba
	ab
};

sub make_test_trie {
	my $trie = Tree::SEMETrie->new();
	$trie->add($_, 1) for @keys;
	return $trie;
}


#set up keys that will have both internal branching and compression
#show that order doesn't matter

is
	scalar(grep { Tree::SEMETrie->new->add($_) } @keys),
	scalar(@keys),
	'Size of key irrelevant for isnertion';

do {
	my $trie = Tree::SEMETrie->new();
	$trie->add($_) for @keys;
	my $trie_rev = Tree::SEMETrie->new();
	$trie_rev->add($_) for reverse @keys;

	is_deeply $trie, $trie_rev, 'Insertion order of unique keys irrelevant';
};

do {
	my $trie = make_test_trie();

	is
		scalar(grep { $trie->find($_)->has_value } @keys),
		scalar(@keys),
		'All stored keys can be found';

	ok $trie->find('aaaaa')->has_value, 'Retrieved external single-edged key';
	ok $trie->find('aaaa')->has_value,  'Retrieved internal single-edged key';
	ok ! $trie->find('aaa')->has_value, 'Retrieved partial single-edged key';
	ok $trie->find('abaab')->has_value, 'Retrieved external mutli-edged key';
	ok $trie->find('ab')->has_value,    'Retrieved internal mutli-edged key';
	ok ! $trie->find('abb')->has_value, 'Retrieved partial multi-edged key';
};

ok make_test_trie()->remove('aaaa'),  'Removed internal single-edged key';
ok make_test_trie()->remove('aaaaa'), 'Removed external single-edged key';
ok ! make_test_trie()->remove('aaa'), 'Failed to remove partial single-edged key';
ok make_test_trie()->remove('ab'),    'Removed internal multi-edged key';
ok make_test_trie()->remove('abaab'), 'Removed external multi-edged key';
ok ! make_test_trie()->remove('abb'), 'Failed to remove partial multi-edged key';
