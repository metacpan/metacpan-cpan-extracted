use strict;
use warnings;
use if "$]" < 5.010, 'Test::Needs', 'MRO::Compat';
use Test::Needs 'Role::Tiny';
use Test::More;

use With::Roles;

{
  package ClassBase;
  use mro 'c3';
  sub found { __PACKAGE__ }
}

{
  package ClassA;
  use mro 'c3';
  our @ISA = qw(ClassBase);
}

{
  package ClassB;
  use mro 'c3';
  our @ISA = qw(ClassBase);
  sub found { __PACKAGE__ }
}

{
  package ClassC;
  use mro 'c3';
  our @ISA = qw(ClassA ClassB);
}

{
  package SomeRole;
  use Role::Tiny;
}

my $found = ClassC->found;
my $with_found = ClassC->with::roles('SomeRole')->found;

is $with_found, $found,
  'mro maintained after applying roles';

done_testing;
