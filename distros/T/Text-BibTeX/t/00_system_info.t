#!perl

use strict;
use warnings;
use Test::More tests => 1;

open my $f, '<', "btparse/src/bt_config.h";
while (<$f>) {
  diag $_ if /#define/;
}
close $f;
ok(1);
