#!/usr/bin/perl

# vim:ts=2:sw=2:et:sta:syntax=perl

use strict;
use warnings;

use lib 'inc';
use dtRdrTestUtil qw(slurp_data);

use Test::More (
  'no_plan'
  );

BEGIN { use_ok('dtRdr::Book') };
BEGIN { use_ok('dtRdr::Plugins::Book') };

ok(dtRdr::Plugins::Book->init());

my @methods = slurp_data('methods_not_implemented.txt');

my %method_map = map({$_ => dtRdr::Book->can($_)} @methods);
foreach my $package (dtRdr::Plugins::Book->plugins) {
  foreach my $method (@methods) {
    my $ref = $package->can($method);
    ok($ref, $method);
    ok($ref ne $method_map{$method}, "$package has its own $method");
  }
}
