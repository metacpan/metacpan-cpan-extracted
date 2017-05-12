#!/usr/bin/perl

my $num = 1;

sub ok {
  my $ok = shift;
  if ($ok) { print "ok $num\n"; }
  else { print "not ok $num\n"; }
  $num++;
}

print "1..1\n";

use DeltaX::Trace;

ok(1);
