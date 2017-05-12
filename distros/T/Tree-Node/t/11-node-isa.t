#!/usr/bin/perl

package Inherited;

use Tree::Node 0.06, ':p_node';

our @ISA = qw(Tree::Node);
{
  no warnings 'redefine';

  sub p_key_cmp($$) {
    my ($p, $key) = @_;
    ($key cmp p_get_key($p));
  };

  sub key_cmp($$) {
    my ($self, $key) = @_;
    p_key_cmp($self->to_p_node, $key); 
  }
}

package main;

use strict;
use warnings;

use Test::More tests => 30;

# use_ok("Tree::Node");

# for(1..16) {
#   print STDERR "\x23 ",
#     sprintf("%4d %4d", $_, Tree::Node::_level_allocated($_)), "\n";
# }

my $size = 10;

my $x = Inherited->new($size);
$x->set_key("foo");
$x->set_value("bar");

ok(defined $x, "defined");
ok($x->isa("Tree::Node"), "isa");

ok($x->child_count == $size, "level == size");
# ok($x->_allocated == Tree::Node::_allocated_by_child_count($size),
#  "_allocated \& size");

my $y = Inherited->new(2);
$y->set_key("moo");

ok(defined $y, "defined");
ok($y->isa("Tree::Node"), "isa");

ok($x->key eq "foo", "key");
eval { $x->set_key("moo"); };
ok($x->key() ne "moo");

# Note: order of inherited should be reversed

ok($x->key_cmp("monkey") == 1);
ok($x->key_cmp("foo") == 0);
ok($x->key_cmp("bar") == -1);

$x->set_value(1);
ok($x->value == 1);
$x->set_value(2);
ok($x->value == 2);

# print STDERR "\n\x23 allocated $size = ", $x->_allocated, "\n";

ok($y->child_count == 2, "level == 2");

ok(!defined $y->get_child(0), "!defined y->get_child(0)");

$y->set_child(0, $x);
ok(defined $x, "x defined after set_child");

my $z = $y->get_child(0);
ok($z == $x);

ok(defined $z, "z=get_child(0) defined");
ok($z->isa("Tree::Node"), "isa");
ok($z->child_count == $size, "z->child_count == size");

ok(defined $x);
ok($x->child_count);

{
  local $TODO = "tie hash to set_child/get_child";
  ok(($y->get_child(1)||0) == $x);
}

$z = Inherited->new(6);
ok($z->isa("Tree::Node"));
$z->set_key("zzz");
for (0..5) { $z->set_child($_, $x); }
ok($z->child_count == 6);
$y->set_child(0, $z);
ok($y->get_child(0) == $z);
ok($y->get_child(0) != $x);

undef $@ ;
eval { $z->get_child(-1); };
ok($@, "get_child out of bounds");
ok(!defined $z->get_child_or_undef(-1), "get_child_or_undef");

undef $@ ;
eval { $z->get_child(6); };
ok($@, "get_child out of bounds");
ok(!defined $z->get_child_or_undef(6), "get_child_or_undef");


