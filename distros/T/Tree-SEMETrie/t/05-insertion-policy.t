#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 3;
use Test::Exception;
use Tree::SEMETrie;

my $trie = Tree::SEMETrie->new;

$trie->add('new key', 3, sub { $_[2] });
is $trie->find_value('new key'), 3, "Value is always stored for new key";

$trie->add('a', 1);
$trie->add('a', 2, sub { $_[0] });
is $trie->find_value('a'), 1, "Choice function preserved existing value";

$trie->add('a', 3, sub { $_[1] });
is $trie->find_value('a'), 3, "Choice function replaced existing value";
