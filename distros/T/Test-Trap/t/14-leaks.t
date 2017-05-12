#!perl -T
# -*- mode: cperl ; compile-command: "cd .. ; ./Build ; prove -vb t/14-*.t" -*-

BEGIN {
  $_ = defined && /(.*)/ && $1 for @ENV{qw/ TMPDIR TEMP TMP /}; # taint vs tempfile
  use Test::More;
  eval "use Test::Refcount (); use Scalar::Util ()";
  plan skip_all => "Test::Refcount and Scalar::Util required to test refcount" if $@;
}

use Test::More tests => 3*5;
use Test::Refcount;

use strict;
use warnings;

use Test::Trap qw/ $tempfile   tempfile   :output(tempfile)   /;
use Test::Trap qw/ $systemsafe systemsafe :output(systemsafe) /;
use Test::Trap qw/ $perlio     perlio     :output(perlio) /;

our($trap);
sub trap(&);
for my $glob (qw(tempfile systemsafe perlio)) {
  no strict 'refs';
  local *trap = *$glob;
  () = trap { 0 };
  is_oneref($trap, "Basic check, with $glob: Our trap has one ref.");
  my $copy = $trap;
  my $prop = $trap->Prop;
  Scalar::Util::weaken($copy);
  Scalar::Util::weaken($prop);
  is_oneref($copy, "Sanity check, with $glob: Our trap has one ref now.");
  is_oneref($prop, "Sanity check, with $glob: Our trap's property collection has one ref now.");
  () = trap { 1 };
  ok(!defined($copy), "Timely destruction, with $glob: Our trap has been collected now.");
  ok(!defined($prop), "Timely destruction, with $glob: Our trap's property collection has been collected now.");
}
