#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 10;
use Tree::SEMETrie;

my $root = Tree::SEMETrie->new();

ok ! $root->has_childs, "Empty root has no children";
ok ! $root->has_value, "Empty root has no value";
ok ! defined($root->value), "Empty root value returns undef";
is_deeply [$root->childs], [], "Empty root childs returns an empty list";

is $root->value(2), 2, "Setting the root value returns the value";
is $root->value(), 2, "Root value can be retrieved safely";
ok $root->has_value, "Root with a set value has a value";

$root->value(0);
ok $root->has_value, "Root with a value of 0 still has a value";
$root->value('');
ok $root->has_value, "Root with a value of '' still has a value";
$root->value(undef);
ok $root->has_value, "Root with a value of undef still has a value";

