#!/usr/bin/perl

use warnings;
use strict;

use Test::More no_plan =>;#<

use Tree::Base;

{
  my $root = Tree::Base->new();
  ok($root, 'new') or die;
  isa_ok($root, 'Tree::Base') or die;

  my $c1 = $root->create_child(n => 1);
  ok($c1, 'create_child');
  isa_ok($c1, 'Tree::Base');
  my $c2 = $root->create_child(n => 2);
  my $c3 = $root->create_child(n => 3);
  is($c1->parent, $root);
  is($root->parent, undef);
  is($root->root, $root);
  ok(! $c1->is_root);
  is($c1->root, $root);
  is($c2->root, $root);
  is($c3->root, $root);

  my $c31 = $c3->create_child(n => 31);
  is($c31->root, $root);
  is(join("|", map({$_->{n}} $root->children)), '1|2|3');
  is(join("|", $root->rmap(sub {$_->{n}||'r'})), 'r|1|2|3|31');

  my $c4 = $root->create_child(n => 4);
  is(join("|", $root->rmap(sub {$_->{n}||'r'})), 'r|1|2|3|31|4');

  is($root->child(3), $c4);
  is($root->child(-1), $c4);
  is($root->child(-2), $c3);
  eval { $root->child(4) };
  like($@, qr/no child at index 4/);

  is_deeply([$c2->older_siblings], [$c1]);
  is_deeply([$c3->older_siblings], [$c1, $c2]);
  is_deeply([$c2->younger_siblings], [$c3, $c4]);
  is_deeply([$c3->descendants], [$c31]);
  is_deeply([$c31->ancestors], [$c3, $root]);
  is($c3->next_sibling, $c4);
  is($c3->prev_sibling, $c2);
}

{
  my @did;
  {
    package Tree::Trial;
    use base 'Tree::Base';
    sub DESTROY {
      my $self = shift;
      push(@did, "$self");
      $self->SUPER::DESTROY;
    }
  }

  my @check;
  {
    my $tree = Tree::Trial->new;
    my $c1 = $tree->create_child;
    my $c2 = $c1->create_child;
    my $root = Tree::Trial->new;
    $root->add_child($tree);
    is($tree->root, $root);
    is($tree->parent, $root);
    is($c1->root, $root);
    is($c2->root, $root);
    @check = map({"$_"} $root, $tree, $c1, $c2);
  }
  is(join("|", @did), join("|", @check));
}

# vim:ts=2:sw=2:et:sta
