#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 4;
use Test::SynchHaveWant qw(have want synch);

is_deeply have(
    {
        foo => 1,
        bar => [ 3, 4 ],
    }
  ),
  want(),
  'The first value of want should be correct';

is have(0), want(), '... and we should be able to handle false values';
my $blessed = want();
isa_ok $blessed, 'Foobar', '... and it should be able to handle blessed values';
is_deeply have(
    bless(
        [
            this    => 'that',
            glarble => 'fetch',
        ] => 'Foobar'
    )
  ),
  $blessed,
  '... and return its data correctly';

synch();

__DATA__
[
  {
    'bar' => [
      3,
      4
    ],
    'foo' => 1
  },
  0,
  bless( [
    'this',
    'that',
    'glarble',
    'fetch'
  ], 'Foobar' )
]
