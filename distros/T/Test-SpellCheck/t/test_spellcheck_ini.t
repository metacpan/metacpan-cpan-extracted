use Test2::V0 -no_srand => 1;
use Test::SpellCheck::INI;

my $config = Test::SpellCheck::INI->read_string(<<~'INI');
  x = 1
  [foo]
  y = 2
  y = 3
  z = 4
  [bar]
  baz = 5
  INI

is
  $config,
  [
    [undef, x => 1],
    ['foo', y => [2,3], z => 4],
    ['bar', baz => 5],
  ],
;

done_testing;
