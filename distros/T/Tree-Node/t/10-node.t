#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 59;

use_ok("Tree::Node", 0.08);

# for(1..16) {
#   print STDERR "\x23 ",
#     sprintf("%4d %4d", $_, Tree::Node::_level_allocated($_)), "\n";
# }

my $size = 10;

my $x = Tree::Node->new($size);

ok(defined $x, "defined");
ok($x->isa("Tree::Node"), "isa");
ok($x->to_p_node != 0, "to_p");

ok(!defined $x->key);
ok(!defined $x->value);

ok($x->key_cmp("bo") == -1);

$x->set_key("poo");
$x->set_value("bar");

eval { $x->set_key("foo"); };
ok($@);
ok($x->key ne "foo");

$x->force_set_key("foo");
ok($x->key eq "foo");

ok($x->child_count == $size, "level == size");
ok($x->_allocated == Tree::Node::_allocated_by_child_count($size),
 "_allocated \& size");


my $y = Tree::Node->new(2);
$y->set_key("moo");

ok(defined $y, "defined");
ok($y->isa("Tree::Node"), "isa");

# Dump($x);
ok($x->key eq "foo", "key");
eval { $x->set_key("moo"); };
ok($x->key() ne "moo");


ok($x->key_cmp("monkey") == -1);
ok($x->key_cmp("foo") == 0);
ok($x->key_cmp("bar") == 1);
ok($x->key_cmp(undef) == 1);

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

$z = Tree::Node->new(6);
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

# use Devel::Peek;
{
  my @c = $x->get_children;
  is(@c, $size);
  my $sx = $x->_allocated;
# Dump($x);
  $x->add_children(undef);
# Dump($x);  # (*) This one prevents a crash: why?!?!
  ok($x->_allocated > $sx, "size increased");
  is($x->child_count, $size+1, "added child");
  $size = $x->child_count; # so later tests pass
  @c = $x->get_children;
  is(@c, $size);
} 

{
  my @c = $x->get_children;
  is(@c, $size);
# Dump($x);
  $x->add_children((undef) x 2);
# Dump($x);
  is($x->child_count, $size+2, "added child");
  $size = $x->child_count; # so later tests pass
  @c = $x->get_children;
  is(@c, $size);
}

{
  my @c = $x->get_children;
  is(@c, $size);
  my $sx = $x->_allocated;
  $x->set_child(0,$z);
# Dump($x);
  $x->add_children_left($y);
# Dump($x);  # (*) This one prevents a crash: why?!?!
  ok($x->_allocated > $sx, "size increased");
  is($x->child_count, $size+1, "added child");
  $size = $x->child_count; # so later tests pass
  @c = $x->get_children;
  is(@c, $size);
  ok($x->get_child(0) == $y);
  ok($x->get_child(1) == $z);
} 

{
  my @c = $x->get_children;
  is(@c, $size);
# Dump($x);
  $x->add_children_left($z,$y);
# Dump($x);
  is($x->child_count, $size+2, "added child");
  $size = $x->child_count; # so later tests pass
  @c = $x->get_children;
  is(@c, $size);
  ok($x->get_child(1) == $y);
  ok($x->get_child(0) == $z);
  ok($x->get_child(2) == $y);
  ok($x->get_child(3) == $z);
}
