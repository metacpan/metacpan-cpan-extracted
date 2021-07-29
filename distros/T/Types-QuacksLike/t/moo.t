use strict;
use warnings;
use Test::More;
use Test::Needs qw(Moo);

use Types::QuacksLike -all;

BEGIN {
  package MyClass1;
  use Moo;
  has my_attr => (is => 'ro');
  sub my_method {}
}
BEGIN {
  package MyClass2;
  use Moo;
  has other_attr => (is => 'ro');
  sub other_method {}
}
BEGIN {
  package MyRole1;
  sub my_non_method {}
  use Moo::Role;
  has my_attr => (is => 'ro');
  sub my_method {}
}
BEGIN {
  package MyRole2;
  use Moo::Role;
  has my_other_attr => (is => 'ro');
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
