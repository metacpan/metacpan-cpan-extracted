#!perl

use strict;
use warnings;

use Test::More tests => 4 * 2;

my $count;

use re::engine::Plugin comp => sub {
 my ($re) = @_;

 my $pat = $re->pattern;

 $re->callbacks(
  exec => sub {
   my ($re, $str) = @_;

   ++$count;

   return $str eq $pat;
  },
 );
};

$count = 0;

ok "foo"  =~ /foo/;
is $count, 1;
ok "fool" !~ /foo/;
is $count, 2;

my $rx = qr/bar/;

ok "bar"  =~ $rx;
is $count, 3;
ok "foo"  !~ $rx;
is $count, 4;
