#!perl -T

use strict;
use warnings;

use blib 't/re-engine-Hooks-TestDist';

use Test::More tests => 4 * 3;

my $ops;
BEGIN { $ops = [ ] }

{
 use re::engine::Hooks::TestDist 'foo' => $ops;

 BEGIN { @$ops = () }
 @$ops = ();

 my $res = "lettuce" =~ /t{2,3}/;

 BEGIN {
  is "@$ops", 'c:EXACT c:CURLY c:END',  'match compilation';
 }
 is "@$ops", 'e:CURLY e:END', 'match execution';

 ok $res, 'regexp match result';
}

{
 use re::engine::Hooks::TestDist 'foo';

 BEGIN { @$ops = () }
 @$ops = ();

 my @captures = "babaorum" =~ /([aeiou])/g;

 BEGIN {
  is "@$ops", 'c:OPEN c:ANYOF c:CLOSE c:END', 'capture compilation';
 }
 my $expect = join ' ', ('e:OPEN e:ANYOF e:CLOSE e:END') x 4;
 is "@$ops", $expect, 'capture execution';

 is "@captures", 'a a o u', 'regexp capture result';
}

my $expected_comp_branch;
BEGIN {
 $expected_comp_branch
}

{
 use re::engine::Hooks::TestDist 'foo';

 BEGIN { @$ops = () }
 @$ops = ();

 my $res = "tomato" =~ /t(?:z|.)/g;

 BEGIN {
  is "@$ops", 'c:EXACT c:EXACT c:BRANCH c:BRANCH c:REG_ANY c:TAIL c:END',
              'branch compilation';
 }
 my $expect = join ' ', ('e:EXACT e:BRANCH') x2, 'e:REG_ANY e:END';
 is "@$ops", $expect, 'branch execution';

 ok $res, 'branch execution result';
}

{
 use re::engine::Hooks::TestDist 'foo';

 BEGIN { @$ops = () }
 @$ops = ();

 my $res = "potato" =~ /t(?:z|o)/g;

 BEGIN {
  is "@$ops", 'c:EXACT c:EXACT c:BRANCH c:BRANCH c:EXACT c:TAIL c:END c:TRIE',
              'trie compilation';
 }
 my $expect = join ' ', ('e:EXACT e:TRIE') x2, 'e:END';
 is "@$ops", $expect, 'trie execution';

 ok $res, 'trie execution result';
}
