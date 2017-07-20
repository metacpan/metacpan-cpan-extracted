#!perl

use strict;

while(<STDIN>)
{
  s/oo/bb/g;
  print;
}

1;
