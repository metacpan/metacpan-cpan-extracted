#!/usr/bin/perl

use warnings;
use strict;

use inc::testplan(1,
  + 3    # use_ok
  + 27
);

BEGIN {
  use_ok('dtRdr::Book') or die;
  use_ok('dtRdr::BookBag') or die;
}

{
  package MyBook;
  use base 'dtRdr::Book::Zombie';
  # TODO override DESTROY?
}

my $B = sub {
  my $id = shift;
  MyBook->new(id => $id);
};

can_ok('dtRdr::BookBag', 'new');
my $bag = dtRdr::BookBag->new(books => [
  map({$B->($_)} 1..4),
]);

$bag->add($B->(5));

for my $id (1..5) {
  my $b = $bag->find($id);
  ok($b, "found $id");
  is($b->id, $id, 'check');
}

{
  eval{$bag->add($B->(4))}; my $err = $@; ok($err);
  like($err, qr/id '4' already exists/);
}
{
  my $b = $bag->delete(4);
  ok($b, 'delete');
  is($b->id, 4, 'check');
  eval{$bag->delete(4)}; my $err = $@; ok($err);
  like($err, qr/id '4' not found/);
  is($bag->find(4), undef);
}
is_deeply([sort({$a <=> $b} map({$_->id} $bag->items))], [1..3, 5]);
is_deeply([sort({$a <=> $b} $bag->list)], [1..3, 5]);
for my $id (1..3, 5) {
  my $b = $bag->find($id);
  ok($b, "found $id");
  is($b->id, $id, 'check');
}

done;
# vim:ts=2:sw=2:et:sta
