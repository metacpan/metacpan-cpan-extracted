use strict;
use warnings;
use Test::More;
use Test::Needs qw(Role::Tiny);

use Types::QuacksLike -all;

BEGIN {
  package MyClass1;
  sub my_method {}
}
BEGIN {
  package MyClass2;
  sub other_method {}
}
BEGIN {
  package MyRole1;
  sub my_non_method {}
  use Role::Tiny;
  sub my_method {}
}
BEGIN {
  package MyRole2;
  use Role::Tiny;
  sub my_other_method {}
}

my $o1 = bless {}, 'MyClass1';
my $o2 = bless {}, 'MyClass2';

my $tr1 = QuacksLike['MyRole1'];
my $tr2 = QuacksLike['MyRole2'];

ok $tr1->check($o1);
ok !$tr1->check($o2);

ok !$tr2->check($o1);
ok !$tr2->check($o2);

done_testing;
