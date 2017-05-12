#!/usr/bin/perl

# vim:ts=2:sw=2:et:sta:syntax=perl

use strict;
use warnings;

use Test::More (
  'no_plan'
  );

BEGIN { use_ok('dtRdr::TOC');   }
BEGIN { use_ok('dtRdr::Book::ThoutBook_1_0_jar');  }
BEGIN { use_ok('dtRdr::Range'); }

{ # first just fake it
  my $book = bless({}, 'dtRdr::Book');
  my $toc = do {
    my $range = dtRdr::Range->create(node => $book, range => [0,10]);
    dtRdr::TOC->new($book, 'foo', $range, {});
  };
  ok($toc);
  isa_ok($toc, 'dtRdr::TOC');

  # have this just to throw at evals
  my $arange = dtRdr::Range->create(node => $book, range => [0,10]);

  # try to misbehave
  eval { $toc->create_child('foo', $arange, {}) };
  ok($@, 'disallow duplicate id');

  # a child
  my $child0 = do {
    my $range = dtRdr::Range->create(node => $book, range => [0,7]);
    $toc->create_child('bar', $range, {});
  };
  ok($child0);
  isa_ok($child0, 'dtRdr::TOC');
  {
    my @children = $toc->children;
    is(scalar(@children), 1, 'count children');
    is($children[0], $child0, 'verify child');
  }

  # try to misbehave
  eval { $toc->create_child('bar', $arange, {}) };
  ok($@, 'disallow duplicate id');
  eval { $child0->create_child('bar', $arange, {}) };
  ok($@, 'disallow duplicate id');

  # another child
  my $child1 = do {
    my $range = dtRdr::Range->create(node => $book, range => [0,1]);
    $toc->create_child('baz', $range, {});
  };
  ok($child1);
  isa_ok($child1, 'dtRdr::TOC');
  {
    my @children = $toc->children;
    is(scalar(@children), 2, 'count children');
    is($children[0], $child0, 'verify child');
    is($children[1], $child1, 'verify child');
  }

  # try to misbehave
  eval { $child1->create_child('foo', $arange, {}) };
  ok($@, 'disallow duplicate id');
  eval { $child1->create_child('bar', $arange, {}) };
  ok($@, 'disallow duplicate id');
  eval { $child1->create_child('baz', $arange, {}) };
  ok($@, 'disallow duplicate id');

  # a child's child
  my $child1_0 = do {
    my $range = dtRdr::Range->create(node => $book, range => [0,1]);
    $child1->create_child('bip', $range, {});
  };
  ok($child1_0);
  isa_ok($child1_0, 'dtRdr::TOC');
  {
    my @children = $toc->children;
    is(scalar(@children), 2, 'count children');
    is($children[0], $child0, 'verify child');
    is($children[1], $child1, 'verify child');
  }
  {
    my @children = $child1->children;
    is(scalar(@children), 1, 'count children');
    is($children[0], $child1_0, 'verify child');
  }
  { # check the ancestors
    my @ancestors = $child1_0->ancestors;
    is(scalar(@ancestors), 2, 'count ancestors');
    is($ancestors[0], $child1, 'verify parent');
    is($ancestors[0], $child1_0->parent, 'verify parent');
    is($ancestors[1], $toc, 'verify parent');
    is($ancestors[1], $child1_0->root, 'verify parent');
    is($ancestors[-1], $child1_0->root, 'verify root');
  }
  { # get_by_id() checks
    # TODO should actually test each-to-each lookups here
    foreach my $node ($toc, $child0, $child1, $child1_0) {
      my $id = $node->id;
      my $found = $node->get_by_id($id);
      ok($found, "found something for '$id'");
      is($found->id, $id);
    }
  }

  ok(! $toc->validate_ranges, 'ranges not valid yet');
  ######################################################################

  # XXX our range/location objects are maybe too strict, but this is a rare test case
  # warn $child0->range->a;
  # warn $child0->range->b;
  $child0->{range} = dtRdr::Range->create(node => $book, range => [1,3]);
  $child1->{range} = dtRdr::Range->create(node => $book, range => [4,9]);
  $child1_0->{range} = dtRdr::Range->create(node => $book, range => [5,9]);

  ok($toc->validate_ranges, 'ranges valid');
  ######################################################################

  $child1_0->{range} = dtRdr::Range->create(node => $book, range => [4,9]);

  ok($toc->validate_ranges, 'ranges valid');
  ######################################################################

  my $child1_0_0 = $child1_0->create_child('bop',
    dtRdr::Range->create(node => $book, range => [0,1]), {}
    );

  { # descendants
    my @descendants = $child1->descendants;
    is(scalar(@descendants), 2, 'descendant count');
    is($descendants[0], $child1_0, 'verify descendant');
    is($descendants[1], $child1_0_0, 'verify descendant');
  }

  { # older siblings
    my @sib = $child0->older_siblings;
    is(scalar(@sib), 0, 'no older siblings');
  }
  { # older siblings
    my @sib = $child1->older_siblings;
    is(scalar(@sib), 1, 'one older sibling');
  }
  my $child2 = $toc->create_child('doh', # running out of names here
    dtRdr::Range->create(node => $book, range => [9,10]), {}
    );
  { # older siblings
    my @sib = $child2->older_siblings;
    is(scalar(@sib), 2, 'two older siblings');
  }
}
