#!perl -T

use strict;
use warnings;

use Test::More tests => 3 * (2 * 1);

my $n = 1_000;

sub linear {
 my ($n, $force_use) = @_;

 my @lines;
 my $use = $force_use;
 for (1 .. $n) {
  my $stmt = $use ? 'use indirect;' : 'no indirect;';
  $use = !$use unless defined $force_use;
  push @lines, "{ $stmt }";
 }

 return '{ no indirect; ', @lines, '}';
}

for my $test ([ 1, 'always use' ], [ 0, 'always no' ], [ undef, 'mixed' ]) {
 my ($force_use, $desc) = @$test;
 my $code = join "\n", linear $n, $force_use;
 my ($err, @warns);
 {
  local $SIG{__WARN__} = sub { push @warns, "@_" };
  local $@;
  eval $code;
  $err = $@;
 }
 is $err,   '', "linear ($desc): no errror";
 is @warns, 0,  "linear ($desc): no warnings";
 diag $_ for @warns;
}
