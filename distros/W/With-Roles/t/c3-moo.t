use strict;
use warnings;
use if "$]" < 5.010, 'Test::Needs', 'MRO::Compat';
use Test::Needs 'Moo';
use Test::More;

use With::Roles;

{
  package ClassBase;
  use Moo;
  use mro 'c3';
  sub found { __PACKAGE__ }
}

{
  package ClassA;
  use Moo;
  use mro 'c3';
  our @ISA = qw(ClassBase);
}

{
  package ClassB;
  use Moo;
  use mro 'c3';
  our @ISA = qw(ClassBase);
  sub found { __PACKAGE__ }
}

{
  package ClassC;
  use Moo;
  use mro 'c3';
  our @ISA = qw(ClassA ClassB);
}

{
  package SomeRole;
  use Moo::Role;
}

my $found = ClassC->found;
my $with_found = ClassC->with::roles('SomeRole')->found;

is $with_found, $found,
  'mro maintained after applying roles';

done_testing;
