#!/usr/bin/perl

use warnings;
use strict;

use Test::More no_plan =>;#<

use XML::Bits;

{
  my $n = XML::Bits->new(div=>);
  $n->create_child(div=> XML::Bits->new(""=>"x"));
  is("$n", "<div><div>x</div></div>");
}

# vim:ts=2:sw=2:et:sta
