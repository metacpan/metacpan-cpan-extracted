#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

BEGIN {
  plan skip_all => 'Perl 5.10.1 required' if $] < 5.010001;
  use_ok('Xorg::XLFD');
}

done_testing();
