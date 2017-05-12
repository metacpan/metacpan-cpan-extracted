use strict;
use warnings;
use Test::More 0.88;
use Test::Requires qw(Sub::Name);

{
  package Foo;
  use namespace::autoclean;
  use Sub::Name;
  *tiger = *tiger = subname tiger => sub { };
}

ok( Foo->can('tiger'), 'Foo can tiger - anon sub named with subname assigned to glob');
ok(!Foo->can('subname'), 'Foo cannot subname - sub imported from Sub::Name');

done_testing();
