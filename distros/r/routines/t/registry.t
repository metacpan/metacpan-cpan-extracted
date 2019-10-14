use 5.014;

use Test::Auto;
use Test::More;

=name

registry

=cut

=abstract

Register Type Libraries with Namespaces

=cut

=synopsis

  package main;

  use strict;
  use warnings;
  use registry;

  $registry;

  # $registry->('main')
  # 'main' Type::Registry object

  # or ...
  # return registry object based on caller
  # registry::access('main')

  # and ...
  # resolve type expressions based on caller
  # registry::lookup('ClassName')

=cut

=description

This pragma is used to associate the calling package with L<Type::Tiny> type
libraries. A C<$registry> variable is made available to the caller to be used
to access registry objects. The variable is a callback (i.e. coderef) which
should be called with a single argument, the namespace whose registry object
you want, otherwise the argument defaults to C<main>.

  package main;

  use strict;
  use warnings;

  use registry 'Types::Standard';
  use registry 'Types::Common::Numeric';
  use registry 'Types::Common::String';

  $registry;

  # resolve type expression using exported variable
  # my $constraint = $registry->('main')->lookup('StrLength[10]')

  # resolve type expression using registry function
  # my $constraint = registry::lookup('StrLength[10]', 'main')

You can configure the calling package to be associated with multiple distinct
type libraries. The exported C<$registry> object can be used to reify type
constraints and resolve type expressions.

=cut

package main;

my $test = Test::Auto->new(__FILE__);

my $subtests = $test->subtests->standard;

$subtests->synopsis(sub {
  my ($tryable) = @_;

  ok my $result = $tryable->result, '$registry exported';
  ok ref($result) eq 'CODE', '$registry isa coderef';

  my $registry;

  subtest 'callback: no args', sub {
    $registry = $result->();
    ok $registry, 'callback returns value';
    ok $registry->isa('Type::Registry'), 'value isa Type::Registry';
  };

  subtest 'callback: for main', sub {
    $registry = $result->('main');
    ok $registry, 'callback returns value';
    ok $registry->isa('Type::Registry'), 'value isa Type::Registry';
  };

  subtest 'callback: for foobar', sub {
    $registry = $result->('foobar');
    ok !$registry, 'callback returns falsey';
  };

  $result;
});

subtest 'testing registrations', sub {
  my @types_standard = qw(
    Any
    ArrayRef
    Bool
    ClassName
    CodeRef
    FileHandle
    GlobRef
    HashRef
    Int
    Item
    Num
    Object
    RegexpRef
    RoleName
    Str
    Undef
    Value
  );

  my @types_common_numeric = qw(
    PositiveNum
    PositiveOrZeroNum
    PositiveInt
    PositiveOrZeroInt
    NegativeNum
    NegativeOrZeroNum
    NegativeInt
    NegativeOrZeroInt
    SingleDigit
  );

  my @types_common_string = qw(
    SimpleStr
    NonEmptySimpleStr
    NumericCode
    LowerCaseSimpleStr
    UpperCaseSimpleStr
    Password
    StrongPassword
    NonEmptyStr
    LowerCaseStr
    UpperCaseStr
  );

  subtest 'testing explicit registration', sub {
    my $result = do {
      package Test::Registry::Explicit;

      use strict;
      use warnings;

      use registry 'Types::Standard';

      $registry;
    };

    ok ref($result) eq 'CODE', '$registry isa coderef';

    my $registry = $result->('Test::Registry::Explicit');

    ok $registry, 'callback returns value';
    ok $registry->isa('Type::Registry'), 'value isa Type::Registry';

    ok $registry->lookup($_), "registry confirms $_" for @types_standard;
    ok !eval{$registry->lookup($_)}, "registry denies $_" for @types_common_numeric;
    ok !eval{$registry->lookup($_)}, "registry denies $_" for @types_common_string;
  };

  subtest 'testing multiple registration', sub {
    my $result = do {
      package Test::Registry::Multiple;

      use strict;
      use warnings;

      use registry 'Types::Standard';
      use registry 'Types::Common::Numeric';
      use registry 'Types::Common::String';

      $registry;
    };

    ok ref($result) eq 'CODE', '$registry isa coderef';

    my $registry = $result->('Test::Registry::Multiple');

    ok $registry, 'callback returns value';
    ok $registry->isa('Type::Registry'), 'value isa Type::Registry';

    ok $registry->lookup($_), "registry confirms $_" for @types_standard;
    ok $registry->lookup($_), "registry confirms $_" for @types_common_numeric;
    ok $registry->lookup($_), "registry confirms $_" for @types_common_string;
  };

  subtest 'testing implicit registration', sub {
    my $result = do {
      package Test::Registry::Implicit;

      use strict;
      use warnings;
      use registry;

      $registry;
    };

    ok ref($result) eq 'CODE', '$registry isa coderef';

    my $registry = $result->('Test::Registry::Implicit');

    ok $registry, 'callback returns value';
    ok $registry->isa('Type::Registry'), 'value isa Type::Registry';

    ok $registry->lookup($_), "registry confirms $_" for @types_standard;
    ok !eval{$registry->lookup($_)}, "registry denies $_" for @types_common_numeric;
    ok !eval{$registry->lookup($_)}, "registry denies $_" for @types_common_string;
  };

  subtest 'testing functions', sub {
    my $class;
    my $registry;

    {
      package Test::Registry::Functions;

      use strict;
      use warnings;

      use registry 'Types::Standard';
    }

    $class = 'main';
    $registry = registry::access($class);
    ok $registry, 'registry::access returns registry';
    ok $registry->isa('Type::Registry'), 'registry isa Type::Registry';
    ok registry::lookup($_, $class), "registry confirms $_" for @types_standard;
    ok !eval{registry::lookup($_, $class)}, "registry denies $_" for @types_common_numeric;
    ok !eval{registry::lookup($_, $class)}, "registry denies $_" for @types_common_string;

    $class = 'Test::Registry::Functions';
    $registry = registry::access($class);
    ok $registry, 'registry::access returns registry';
    ok $registry->isa('Type::Registry'), 'registry isa Type::Registry';
    ok registry::lookup($_, $class), "registry confirms $_" for @types_standard;
    ok !eval{registry::lookup($_, $class)}, "registry denies $_" for @types_common_numeric;
    ok !eval{registry::lookup($_, $class)}, "registry denies $_" for @types_common_string;

    {
      package main;

      $registry = registry::access();
      ok $registry, 'registry::access returns registry';
      ok $registry->isa('Type::Registry'), 'registry isa Type::Registry';
      ok registry::lookup($_), "registry confirms $_" for @types_standard;
      ok !eval{registry::lookup($_)}, "registry denies $_" for @types_common_numeric;
      ok !eval{registry::lookup($_)}, "registry denies $_" for @types_common_string;
    }
  };
};

ok 1 and done_testing;
