use strict;
use warnings;
use Test::Script::Async;
use Test2::Bundle::Extended;

skip_all 'because it will always fail';
plan 6;

script_compiles 'corpus/bad.pl';
script_compiles 'corpus/bogus.pl';

script_runs('corpus/good.pl')
  ->exit_is(22)
  ->exit_isnt(0);

script_runs('corpus/bogus.pl')
  ->note;
