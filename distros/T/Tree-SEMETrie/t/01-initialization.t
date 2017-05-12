#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 2;
use Tree::SEMETrie;

my $class_trie = Tree::SEMETrie->new();
isa_ok $class_trie, 'Tree::SEMETrie',    "Class construction successful";
my $instance_trie = $class_trie->new();
isa_ok $instance_trie, 'Tree::SEMETrie', "Instance construction successful";

