#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 3;

use Text::Spintax;

{
   my $node = Text::Spintax->new->parse("this {is|was} a test");
   ok(defined $node);
   ok($node->render =~ /^this (is|was) a test$/);
   my %seen;
# technically, this will fail randomly once in a while, once in every 2^100 times you run it
   foreach (1 .. 100) {
      $seen{$node->render} = 1;
   }
   ok(scalar keys %seen == 2);
}

