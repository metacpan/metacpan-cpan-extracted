use 5.014;

use Test::Auto;
use Test::More;

=name

routines

=cut

=abstract

Typeable Method and Function Signatures

=cut

=synopsis

  package main;

  use strict;
  use warnings;

  use routines;

  fun hello($name) {
    "hello, $name"
  }

  hello("world");

=cut

=description

This pragma is used to provide typeable method and function signtures to the
calling package, as well as C<before>, C<after>, C<around>, C<augment> and
C<override> method modifiers.

  package main;

  use strict;
  use warnings;

  use registry;
  use routines;

  fun hello(Str $name) {
    "hello, $name"
  }

  hello("world");

Additionally, when used in concert with the L<registry> pragma, this pragma will
check to determine whether a L<Type::Tiny> registry object is associated with
the calling package and if so will use it to reify type constraints and
resolve type expressions.

  package Example;

  use Moo;

  use registry;
  use routines;

  fun new($class) {
    bless {}, $class
  }

  method hello(Str $name) {
    "hello, $name"
  }

  around hello(Str $name) {
    $self->{name} = $name;

    $self->$orig($name);
  }

  1;

This functionality is based on L<Function::Parameters> and uses Perl's keyword
plugn API to provide new keywords. As mentioned previously, this pragma makes
the C<before>, C<after>, C<around>, C<augment>, and C<override> method
modifiers available to the calling package where that functionality is already
present in its generic subroutine callback form.

=cut

package main;

my $test = Test::Auto->new(__FILE__);

my $subtests = $test->subtests->standard;

$subtests->synopsis(sub {
  my ($tryable) = @_;

  ok my $result = $tryable->result, 'result ok';
  is $result, "hello, world", 'result content ok';

  $result;
});

subtest 'testing configurations', sub {

  subtest 'testing basic configuration', sub {
    my $result = do {
      package Test::Routine::Basic;

      use strict;
      use warnings;
      use routines;

      fun hello($name) {
        "hello, $name"
      }

      "Test::Routine::Basic"
    };

    ok $result->can('hello'), "$result has hello";
    is Test::Routine::Basic::hello('world'), 'hello, world', 'str value ok';
    ok eval{Test::Routine::Basic::hello({})}, 'hashref value ok';
  };

  subtest 'testing fallback configuration', sub {
    my $result = do {
      package Test::Routine::Expression;

      use strict;
      use warnings;
      use routines;

      use Types::Standard 'Str';

      fun hello((Str) $name) {
        "hello, $name"
      }

      "Test::Routine::Expression"
    };

    ok $result->can('hello'), "$result has hello";
    is Test::Routine::Expression::hello('world'), 'hello, world', 'str value ok';
    ok !eval{Test::Routine::Expression::hello({})}, 'hashref value not ok';
  };

  subtest 'testing registry configuration', sub {
    my $result = do {
      package Test::Routine::Registry;

      use strict;
      use warnings;
      use registry;
      use routines;

      fun hello(Str $name) {
        "hello, $name"
      }

      "Test::Routine::Registry"
    };

    ok $result->can('hello'), "$result has hello";
    is Test::Routine::Registry::hello('world'), 'hello, world', 'str value ok';
    ok !eval{Test::Routine::Registry::hello({})}, 'hashref value not ok';
  };

  subtest 'testing registry (multi) configuration', sub {
    my $result = do {
      package Test::Routine::Registry::Multi;

      use strict;
      use warnings;
      use registry;
      use registry 'Types::Common::String';
      use routines;

      fun hello(NonEmptyStr $name) {
        "hello, $name"
      }

      "Test::Routine::Registry::Multi"
    };

    ok $result->can('hello'), "$result has hello";
    is Test::Routine::Registry::Multi::hello('world'), 'hello, world', 'str value ok';
    ok !eval{Test::Routine::Registry::Multi::hello({})}, 'hashref value not ok';
  };

  subtest 'testing before keyword usage', sub {
    plan SKIP_ALL => 'before keyword requires Moo(se)'
      unless eval { require Moo };

    my $result = do {
      package Test::Routine::Before;

      use Moo;
      use routines;

      fun new($class) {
        bless {}
      }

      method greet($name) {
        "hello, $name"
      }

      before greet($name) {
        $self->{name} = $name;
      }

      "Test::Routine::Before"
    };

    ok $result->can('new'), "$result has new";
    ok $result->can('greet'), "$result has greet";

    my $object = $result->new;

    ok $object->isa($result), "object isa $result";
    ok !$object->{name}, "object hasn't set name attr";

    my $value = $object->greet('world');

    is $value, 'hello, world', 'greet method return value ok';
    is $object->{name}, 'world', 'object set name attr';
  };

  subtest 'testing before keyword usage with registry', sub {
    plan SKIP_ALL => 'before keyword requires Moo(se)'
      unless eval { require Moo };

    my $result = do {
      package Test::Routine::Registry::Before;

      use Moo;
      use registry;
      use routines;

      fun new($class) {
        bless {}
      }

      method greet(Str $name) {
        "hello, $name"
      }

      before greet(Str $name) {
        $self->{name} = $name;
      }

      "Test::Routine::Registry::Before"
    };

    ok $result->can('new'), "$result has new";
    ok $result->can('greet'), "$result has greet";

    my $object = $result->new;

    ok $object->isa($result), "object isa $result";
    ok !$object->{name}, "object hasn't set name attr";

    my $value = $object->greet('world');

    is $value, 'hello, world', 'greet method return value ok';
    is $object->{name}, 'world', 'object set name attr';
  };

  subtest 'testing after keyword usage', sub {
    plan SKIP_ALL => 'after keyword requires Moo(se)'
      unless eval { require Moo };

    my $result = do {
      package Test::Routine::After;

      use Moo;
      use routines;

      fun new($class) {
        bless {}
      }

      method greet($name) {
        "hello, $name"
      }

      after greet($name) {
        $self->{name} = $name;
      }

      "Test::Routine::After"
    };

    ok $result->can('new'), "$result has new";
    ok $result->can('greet'), "$result has greet";

    my $object = $result->new;

    ok $object->isa($result), "object isa $result";
    ok !$object->{name}, "object hasn't set name attr";

    my $value = $object->greet('world');

    is $value, 'hello, world', 'greet method return value ok';
    is $object->{name}, 'world', 'object set name attr';
  };

  subtest 'testing after keyword usage with registry', sub {
    plan SKIP_ALL => 'after keyword requires Moo(se)'
      unless eval { require Moo };

    my $result = do {
      package Test::Routine::Registry::After;

      use Moo;
      use registry;
      use routines;

      fun new($class) {
        bless {}
      }

      method greet(Str $name) {
        "hello, $name"
      }

      after greet(Str $name) {
        $self->{name} = $name;
      }

      "Test::Routine::Registry::After"
    };

    ok $result->can('new'), "$result has new";
    ok $result->can('greet'), "$result has greet";

    my $object = $result->new;

    ok $object->isa($result), "object isa $result";
    ok !$object->{name}, "object hasn't set name attr";

    my $value = $object->greet('world');

    is $value, 'hello, world', 'greet method return value ok';
    is $object->{name}, 'world', 'object set name attr';
  };

  subtest 'testing around keyword usage', sub {
    plan SKIP_ALL => 'around keyword requires Moo(se)'
      unless eval { require Moo };

    my $result = do {
      package Test::Routine::Around;

      use Moo;
      use routines;

      fun new($class) {
        bless {}
      }

      method greet($name) {
        "hello, $name"
      }

      around greet($name) {
        $self->{name} = $name;

        return $self->$orig($name);
      }

      "Test::Routine::Around"
    };

    ok $result->can('new'), "$result has new";
    ok $result->can('greet'), "$result has greet";

    my $object = $result->new;

    ok $object->isa($result), "object isa $result";
    ok !$object->{name}, "object hasn't set name attr";

    my $value = $object->greet('world');

    is $value, 'hello, world', 'greet method return value ok';
    is $object->{name}, 'world', 'object set name attr';
  };

  subtest 'testing around keyword usage with registry', sub {
    plan SKIP_ALL => 'around keyword requires Moo(se)'
      unless eval { require Moo };

    my $result = do {
      package Test::Routine::Registry::Around;

      use Moo;
      use registry;
      use routines;

      fun new($class) {
        bless {}
      }

      method greet(Str $name) {
        "hello, $name"
      }

      around greet(Str $name) {
        $self->{name} = $name;

        return $self->$orig($name);
      }

      "Test::Routine::Registry::Around"
    };

    ok $result->can('new'), "$result has new";
    ok $result->can('greet'), "$result has greet";

    my $object = $result->new;

    ok $object->isa($result), "object isa $result";
    ok !$object->{name}, "object hasn't set name attr";

    my $value = $object->greet('world');

    is $value, 'hello, world', 'greet method return value ok';
    is $object->{name}, 'world', 'object set name attr';
  };

};

ok 1 and done_testing;
