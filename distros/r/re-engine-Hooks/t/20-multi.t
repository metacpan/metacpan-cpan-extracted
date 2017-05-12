#!perl -T

use strict;
use warnings;

use blib 't/re-engine-Hooks-TestDist';

use Test::More tests => 4 * 2;

my ($foo_ops, $bar_ops, $expect);
BEGIN {
 $foo_ops = [ ];
 $bar_ops = [ ];
 $expect  = 'c:EXACT c:CURLY c:END';
}

{
 use re::engine::Hooks::TestDist 'foo' => $foo_ops;
 use re::engine::Hooks::TestDist 'bar' => $bar_ops;

 BEGIN {
  @$foo_ops = ();
  @$bar_ops = ();
 }

 "carrot" =~ /r{2,3}/;

 BEGIN {
  is "@$foo_ops", $expect, 'match compilation by foo and bar : the foo case';
  is "@$bar_ops", $expect, 'match compilation by foo and bar : the bar case';
 }
}

{
 use re::engine::Hooks::TestDist 'foo';

 BEGIN {
  @$foo_ops = ();
  @$bar_ops = ();
 }

 "cabbage" =~ /b{2,3}/;

 BEGIN {
  is "@$foo_ops", $expect, 'match compilation by foo only : the foo case';
  is "@$bar_ops", '',      'match compilation by foo only : the bar case';
 }
}

{
 use re::engine::Hooks::TestDist 'bar';

 BEGIN {
  @$foo_ops = ();
  @$bar_ops = ();
 }

 "pepperoni" =~ /p{2,3}/;

 BEGIN {
  is "@$foo_ops", '',      'match compilation by foo only : the foo case';
  is "@$bar_ops", $expect, 'match compilation by foo only : the bar case';
 }

 {
  use re::engine::Hooks::TestDist 'foo';

  BEGIN {
   @$foo_ops = ();
   @$bar_ops = ();
  }

  'eggplant' =~ /g{2,3}/;

  BEGIN {
   is "@$foo_ops", $expect, 'match compilation by bar and foo : the foo case';
   is "@$bar_ops", $expect, 'match compilation by bar and foo : the bar case';
  }
 }
}
