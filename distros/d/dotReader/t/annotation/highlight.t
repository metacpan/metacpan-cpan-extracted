#!/usr/bin/perl

# vim:ts=2:sw=2:et:sta:syntax=perl

use strict;
use warnings;

use inc::testplan(1,
  0
  + 1  # use_ok
  + 4 * 2 # create/check
  + 3 * 2 # serialize
);

BEGIN {use_ok('dtRdr::Highlight');}

use dtRdr::Book;
my $book = dtRdr::Book->new();
$book->set_id('thisbook');

my $hl;
{
  my $toc = dtRdr::TOC->new(
    $book, 'a',
    dtRdr::Range->create(node => $book, range => [0,100])
  );
  $hl = dtRdr::Highlight->create(node => $toc, range => [20, 50], id => 'foo');
  isa_ok($hl, 'dtRdr::Highlight');
  is($hl->a, 20);
  is($hl->b, 50);
  ok($hl->id, 'has an ID (\''. $hl->id .'\')');
}

{ # check renode / fake-ification
  my $toc = dtRdr::TOC->new(
    $book, 'a',
    dtRdr::Range->create(node => $book, range => [0,100])
  );
  my $hln = $hl->renode($toc, range => [10,40]);
  isa_ok($hln, 'dtRdr::Highlight');
  is($hln->a, 10);
  is($hln->b, 40);
  ok($hln->id, 'has an ID (\''. $hln->id .'\')');
  is($hln->id, $hl->id, 'same id');
  ok($hln->is_fake, 'is labeled as fake');

  eval {$hln->serialize};
  ok($@, 'no serializing fake annotations');
}

{
  my $href = $hl->serialize;
  ok($href, 'answer');
  is(ref($href) || '', 'HASH', 'yay');
  if(0) {
    require YAML;
    warn YAML::Dump($href);
  }
  my $expect = {
    book     => 'thisbook',
    id       => 'foo',
    node     => 'a',
    start    => '20',
    end      => '50',
    type     => 'dtRdr::Highlight',
    title    => undef,
    context  => undef,
    selected => undef,
    # NOTE these will stay unset as long as we're doing that in the IO
    mod_time    => undef,
    create_time => undef,
    revision    => undef,
    # TODO public
  };
  is_deeply($href, $expect, 'deep expect');
}

# TODO invalid ranges are unchecked on add_highlight() -- though it
# would be hard to make them outside of a test environment -- and they
# probably choke in insert_nbh()
