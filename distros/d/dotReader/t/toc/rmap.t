#!/usr/bin/perl

# vim:ts=2:sw=2:et:sta:syntax=perl

use strict;
use warnings;

use Test::More (
  'no_plan'
  );

BEGIN { use_ok('dtRdr::TOC'); };
BEGIN { use_ok('dtRdr::Range'); }



my $book = bless({}, 'dtRdr::Book');
sub R {
  dtRdr::Range->create(node => $book, range => [@_]);
}

my $toc = dtRdr::TOC->new($book, 'foo', R(0,10));
my $child0   = $toc->create_child('bar', R(1,4));
my $child0_0 = $child0->create_child('bar0', R(1,4));
my $child1   = $toc->create_child('baz', R(5,6));
my $child2   = $toc->create_child('bop', R(7,10));

{
  my @whee;
  $toc->rmap(sub {
    my $node = shift;
    ($node->id eq 'bar') or push(@whee, $node->id);
  });
  is_deeply(\@whee, [qw(foo bar0 baz bop)], 'non-pruning');
}
{
  my @whee;
  $toc->rmap(sub {
    my $node = shift;
    my ($ctrl) = @_;
    if($node->id eq 'bar') {
      $ctrl->{prune} = 1;
    }
    else {
      push(@whee, $node->id);
    }
  });
  is_deeply(\@whee, [qw(foo baz bop)], 'prune check 1');
}
{
  my @whee;
  $toc->rmap(sub {
    my $node = shift;
    my ($ctrl) = @_;
    ($node->id eq 'bar') and ($ctrl->{prune} = 1);
    push(@whee, $node->id);
  });
  is_deeply(\@whee, [qw(foo bar baz bop)], 'prune check 2');
}
