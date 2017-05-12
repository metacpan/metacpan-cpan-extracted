#!/usr/bin/env perl
use warnings;
use strict;
use callee;
use Test::More tests => 1;
my $out = '';
sub {
    my $c = shift;
    $out .= "$c,";
    callee->($c) if $c--;
  }
  ->(10);
is($out, '10,9,8,7,6,5,4,3,2,1,0,', 'countdown');
