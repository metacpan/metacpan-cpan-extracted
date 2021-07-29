use strict;
use warnings;
use Test::More;

use Types::QuacksLike -all;

BEGIN {
  package MyClassParent1;
  sub parent1_method {}
}
BEGIN {
  package MyClassChild1;
  our @ISA = qw(MyClassParent1);
  sub child1_method {}
}
BEGIN {
  package MyClassChild2;
  our @ISA = qw(MyClassParent1);
  sub child2_method {}
}
BEGIN {
  package MyClassChild3;
  our @ISA = qw(MyClassParent1);
  sub child1_method {}
}

my $p1 = bless {}, 'MyClassParent1';
my $c1 = bless {}, 'MyClassChild1';
my $c2 = bless {}, 'MyClassChild2';
my $c3 = bless {}, 'MyClassChild3';

my $tp1 = QuacksLike['MyClassParent1'];
my $tc1 = QuacksLike['MyClassChild1'];
my $tc2 = QuacksLike['MyClassChild2'];
my $tc3 = QuacksLike['MyClassChild3'];

ok $tp1->check($p1);
ok $tp1->check($c1);
ok $tp1->check($c2);
ok $tp1->check($c3);

ok !$tc1->check($p1);
ok $tc1->check($c1);
ok !$tc1->check($c2);
ok $tc1->check($c3);

ok !$tc2->check($p1);
ok !$tc2->check($c1);
ok $tc2->check($c2);
ok !$tc2->check($c3);

ok !$tc3->check($p1);
ok $tc3->check($c1);
ok !$tc3->check($c2);
ok $tc3->check($c3);

done_testing;
