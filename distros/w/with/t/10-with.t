#!perl -T

package main;

use strict;
use warnings;

use Test::More 'no_plan';

use lib 't/lib';
use with::TestClass;

my $tc;
BEGIN { $tc = 'with::TestClass' }

sub foo { is($_[0], __PACKAGE__, __PACKAGE__ . '::foo was called'); }
sub baz { is($_[0], __PACKAGE__, __PACKAGE__ . '::baz was called'); }

my %cbs;
# "use with \with::TestClass->new(id => 2, %cbs)" forces the evaluation of %cbs
# at compile time for constant folding, so we must define it in a BEGIN block.
BEGIN { %cbs = (is => \&Test::More::is); }

my $o1 = new with::TestClass id => 1, %cbs;


foo 'main', 0;
{
 use with \$o1;
 foo $tc, 1;
 bar($tc, 1);
 {
  foo $tc, 1;
  use with \with::TestClass->new(id => 2, %cbs);

  foo
    $tc,
    "2";
  bar $tc, 2;
  main::foo 'main', 2;
  my $ref = \&foo;
  $ref->('main', 2);
 
  no with;
  foo 'main', 0; 
 }



 foo $tc, q{1};bar $tc,
                   '1';



 baz 'main', 1;

}
foo 'main', 0;
eval { bar 'main', 0 };
ok($@, 'wrong call croaks');
