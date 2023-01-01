use strict;
use warnings;
package Test::Routine;
# ABSTRACT: composable units of assertion
$Test::Routine::VERSION = '0.029';
#pod =head1 SYNOPSIS
#pod
#pod   # mytest.t
#pod   use Test::More;
#pod   use Test::Routine;
#pod   use Test::Routine::Util;
#pod
#pod   has fixture => (
#pod     is   => 'ro',
#pod     lazy => 1,
#pod     clearer => 'reset_fixture',
#pod     default => sub { ...expensive setup... },
#pod   );
#pod
#pod   test "we can use our fixture to do stuff" => sub {
#pod     my ($self) = @_;
#pod
#pod     $self->reset_fixture; # this test requires a fresh one
#pod
#pod     ok( $self->fixture->do_things, "do_things returns true");
#pod     ok( ! $self->fixture->no_op,   "no_op returns false");
#pod
#pod     for my $item ($self->fixture->contents) {
#pod       isa_ok($item, 'Fixture::Entry');
#pod     }
#pod   };
#pod
#pod   test "fixture was recycled" => sub {
#pod     my ($self) = @_;
#pod
#pod     my $fixture = $self->fixture; # we don't expect a fresh one
#pod
#pod     is( $self->fixture->things_done, 1, "we have done one thing already");
#pod   };
#pod
#pod   run_me;
#pod   done_testing;
#pod
#pod =head1 DESCRIPTION
#pod
#pod Test::Routine is a very simple framework for writing your tests as composable
#pod units of assertion.  In other words: roles.
#pod
#pod For a walkthrough of tests written with Test::Routine, see
#pod L<Test::Routine::Manual::Demo>.
#pod
#pod Test::Routine is similar to L<Test::Class> in some ways.  These similarities
#pod are largely superficial, but the idea of "tests bound together in reusable
#pod units" is a useful one to understand when coming to Test::Routine.  If you are
#pod already familiar with Test::Class, it is the differences rather than the
#pod similarities that will be more important to understand.  If you are not
#pod familiar with Test::Class, there is no need to understand it prior to using
#pod Test::Routine.
#pod
#pod On the other hand, an understanding of the basics of L<Moose> is absolutely
#pod essential.  Test::Routine composes tests from Moose classes, roles, and
#pod attributes.  Without an understanding of those, you will not be able to use
#pod Test::Routine.  The L<Moose::Manual> is an excellent resource for learning
#pod Moose, and has links to other online tutorials and documentation.
#pod
#pod =head2 The Concepts
#pod
#pod =head2 The Basics of Using Test::Routine
#pod
#pod There actually isn't much to Test::Routine I<other> than the basics.  It does
#pod not provide many complex features, instead delegating almost everything to the
#pod Moose object system.
#pod
#pod =head3 Writing Tests
#pod
#pod To write a set of tests (a test routine, which is a role), you add C<use
#pod Test::Routine;> to your package.  C<main> is an acceptable target for turning
#pod into a test routine, meaning that you may use Test::Routine in your F<*.t>
#pod files in your distribution.
#pod
#pod C<use>-ing Test::Routine will turn your package into a role that composes
#pod L<Test::Routine::Common>, and will give you the C<test> declarator for adding
#pod tests to your routine.  Test::Routine::Common adds the C<run_test> method that
#pod will be called to run each test.
#pod
#pod The C<test> declarator is very simple, and will generally be called like this:
#pod
#pod   test $NAME_OF_TEST => sub {
#pod     my ($self) = @_;
#pod
#pod     is($self->foo, 123, "we got the foo we expected");
#pod     ...
#pod     ...
#pod   };
#pod
#pod This defines a test with a given name, which will be invoked like a method on
#pod the test object (described below).  Tests are ordered by declaration within the
#pod file, but when multiple test routines are run in a single test, the ordering of
#pod the routines is B<undefined>.
#pod
#pod C<test> may also be given a different name for the installed method and the
#pod test description.  This isn't usually needed, but can make things clearer when
#pod referring to tests as methods:
#pod
#pod   test $NAME_OF_TEST_METHOD => { description => $TEST_DESCRIPTION } => sub {
#pod     ...
#pod   }
#pod
#pod Each test will be run by the C<run_test> method.  To add setup or teardown
#pod behavior, advice (method modifiers) may be attached to that method.  For
#pod example, to call an attribute clearer before each test, you could add:
#pod
#pod   before run_test => sub {
#pod     my ($self) = @_;
#pod
#pod     $self->clear_some_attribute;
#pod   };
#pod
#pod =head3 Running Tests
#pod
#pod To run tests, you will need to use L<Test::Routine::Util>, which will provide
#pod two functions for running tests: C<run_tests> and C<run_me>.  The former is
#pod given a set of packages to compose and run as tests.  The latter runs the
#pod caller, assuming it to be a test routine.
#pod
#pod C<run_tests> can be called in several ways:
#pod
#pod   run_tests( $desc, $object );
#pod
#pod   run_tests( $desc, \@packages, $arg );
#pod
#pod   run_tests( $desc, $package, $arg );  # equivalent to ($desc, [$pkg], $arg)
#pod
#pod In the first case, the object is assumed to be a fully formed, testable object.
#pod In other words, you have already created a class that composes test routines
#pod and have built an instance of it.
#pod
#pod In the other cases, C<run_tests> will produce an instance for you.  It divides
#pod the given packages into classes and roles.  If more than one class was given,
#pod an exception is thrown.  A new class is created subclassing the given class and
#pod applying the given roles.  If no class was in the list, Moose::Object is used.
#pod The new class's C<new> is called with the given C<$arg> (if any).
#pod
#pod The composition mechanism makes it easy to run a test routine without first
#pod writing a class to which to apply it.  This is what makes it possible to write
#pod your test routine in the C<main> package and run it directly from your F<*.t>
#pod file.  The following is a valid, trivial use of Test::Routine:
#pod
#pod   use Test::More;
#pod   use Test::Routine;
#pod   use Test::Routine::Util;
#pod
#pod   test demo_test => sub { pass("everything is okay") };
#pod
#pod   run_tests('our tests', 'main');
#pod   done_testing;
#pod
#pod In this circumstance, though, you'd probably use C<run_me>, which runs the
#pod tests in the caller.  You'd just replace the C<run_tests> line with
#pod C<< run_me; >>.  A description for the run may be supplied, if you like.
#pod
#pod Each call to C<run_me> or C<run_tests> generates a new instance, and you can
#pod call them as many times, with as many different arguments, as you like.  Since
#pod Test::Routine can't know how many times you'll call different test routines,
#pod you are responsible for calling C<L<done_testing|Test::More/done_testing>> when
#pod you're done testing.
#pod
#pod =head4 Running individual tests
#pod
#pod If you only want to run a subset of the tests, you can set the
#pod C<TEST_METHOD> environment variable to a regular expression that matches
#pod the names of the tests you want to run.
#pod
#pod For example, to run just the test named C<customer profile> in the
#pod C<MyTests> class.
#pod
#pod   use Test::More;
#pod   use Test::Routine::Util;
#pod
#pod   $ENV{TEST_METHOD} = 'customer profile';
#pod   run_tests('one test', 'MyTests');
#pod   done_testing;
#pod
#pod To run all tests with C<customer> in the name:
#pod
#pod   use Test::More;
#pod   use Test::Routine::Util;
#pod
#pod   $ENV{TEST_METHOD}= '.*customer.*';
#pod   run_tests('some tests', 'MyTests');
#pod   done_testing;
#pod
#pod If you specify an invalid regular expression, your tests will not be
#pod run:
#pod
#pod   use Test::More;
#pod   use Test::Routine::Util
#pod
#pod   $ENV{TEST_METHOD} = 'C++'
#pod   run_tests('invalid', 'MyTests');
#pod   done_testing;
#pod
#pod When you run it:
#pod
#pod       1..0
#pod       # No tests run!
#pod   not ok 1 - No tests run for subtest "invalid"
#pod
#pod =cut

use Moose::Exporter;

use Moose::Role ();
use Moose::Util ();
use Scalar::Util qw(blessed);

use Test::Routine::Common;
use Test::Routine::Test;

Moose::Exporter->setup_import_methods(
  as_is       => [ qw(test) ],
  also        => 'Moose::Role',
);

sub init_meta {
  my ($class, %arg) = @_;

  my $meta = Moose::Role->init_meta(%arg);
  my $role = $arg{for_class};
  Moose::Util::apply_all_roles($role, 'Test::Routine::Common');

  return $meta;
}

my $i = 0;
sub test {
  my $caller = caller();
  my $name   = shift;
  my ($arg, $body);

  if (blessed($_[0]) && $_[0]->isa('Class::MOP::Method')) {
    $arg  = {};
    $body = shift;
  } else {
    $arg  = Params::Util::_HASH0($_[0]) ? { %{shift()} } : {};
    $body = shift;
  }

  # This could really have been done with a MooseX like InitArgs or Alias in
  # Test::Routine::Test, but since this is a test library, I'd actually like to
  # keep prerequisites fairly limited. -- rjbs, 2010-09-28
  if (exists $arg->{desc}) {
    Carp::croak "can't supply both 'desc' and 'description'"
      if exists $arg->{description};
    $arg->{description} = delete $arg->{desc};
  }

  $arg->{description} = $name unless defined $arg->{description};
  $name =~ s/(?:::|')/_/g;

  my $class = Moose::Meta::Class->initialize($caller);

  my %origin;
  @origin{qw(file line nth)} = ((caller(0))[1,2], $i++);

  my $method;
  if (blessed($body) && $body->isa('Class::MOP::Method')) {
    my $method_metaclass = Moose::Util::with_traits(
      blessed($body),
      'Test::Routine::Test::Role',
      ($caller->can('test_routine_test_traits')
        ? $caller->test_routine_test_traits
        : ()),
    );

    $method = $method_metaclass->meta->rebless_instance(
      $body,
      %$arg,
      name         => $name,
      package_name => $caller,
      _origin      => \%origin,
    );
  } else {
    my $test_class = 'Test::Routine::Test';

    if ($caller->can('test_routine_test_traits')) {
      my @traits = $caller->test_routine_test_traits;

      $test_class = Moose::Meta::Class->create_anon_class(
        superclasses => [ $test_class ],
        cache        => 1,
        roles        => \@traits,
      )->name;
    }

    $method = $test_class->wrap(
      %$arg,
      name => $name,
      body => $body,
      package_name => $caller,
      _origin      => \%origin,
    );
  }

  Carp::croak "can't have two tests with the same name ($name)"
    if $class->get_method($name);

  Carp::croak "there's already a subroutine named $name in $caller"
    if $caller->can($name);

  Carp::croak "can't name a test after a Moose::Object method ($name)"
    if Moose::Object->can($name);

  $class->add_method($name => $method);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Routine - composable units of assertion

=head1 VERSION

version 0.029

=head1 SYNOPSIS

  # mytest.t
  use Test::More;
  use Test::Routine;
  use Test::Routine::Util;

  has fixture => (
    is   => 'ro',
    lazy => 1,
    clearer => 'reset_fixture',
    default => sub { ...expensive setup... },
  );

  test "we can use our fixture to do stuff" => sub {
    my ($self) = @_;

    $self->reset_fixture; # this test requires a fresh one

    ok( $self->fixture->do_things, "do_things returns true");
    ok( ! $self->fixture->no_op,   "no_op returns false");

    for my $item ($self->fixture->contents) {
      isa_ok($item, 'Fixture::Entry');
    }
  };

  test "fixture was recycled" => sub {
    my ($self) = @_;

    my $fixture = $self->fixture; # we don't expect a fresh one

    is( $self->fixture->things_done, 1, "we have done one thing already");
  };

  run_me;
  done_testing;

=head1 DESCRIPTION

Test::Routine is a very simple framework for writing your tests as composable
units of assertion.  In other words: roles.

For a walkthrough of tests written with Test::Routine, see
L<Test::Routine::Manual::Demo>.

Test::Routine is similar to L<Test::Class> in some ways.  These similarities
are largely superficial, but the idea of "tests bound together in reusable
units" is a useful one to understand when coming to Test::Routine.  If you are
already familiar with Test::Class, it is the differences rather than the
similarities that will be more important to understand.  If you are not
familiar with Test::Class, there is no need to understand it prior to using
Test::Routine.

On the other hand, an understanding of the basics of L<Moose> is absolutely
essential.  Test::Routine composes tests from Moose classes, roles, and
attributes.  Without an understanding of those, you will not be able to use
Test::Routine.  The L<Moose::Manual> is an excellent resource for learning
Moose, and has links to other online tutorials and documentation.

=head2 The Concepts

=head2 The Basics of Using Test::Routine

There actually isn't much to Test::Routine I<other> than the basics.  It does
not provide many complex features, instead delegating almost everything to the
Moose object system.

=head3 Writing Tests

To write a set of tests (a test routine, which is a role), you add C<use
Test::Routine;> to your package.  C<main> is an acceptable target for turning
into a test routine, meaning that you may use Test::Routine in your F<*.t>
files in your distribution.

C<use>-ing Test::Routine will turn your package into a role that composes
L<Test::Routine::Common>, and will give you the C<test> declarator for adding
tests to your routine.  Test::Routine::Common adds the C<run_test> method that
will be called to run each test.

The C<test> declarator is very simple, and will generally be called like this:

  test $NAME_OF_TEST => sub {
    my ($self) = @_;

    is($self->foo, 123, "we got the foo we expected");
    ...
    ...
  };

This defines a test with a given name, which will be invoked like a method on
the test object (described below).  Tests are ordered by declaration within the
file, but when multiple test routines are run in a single test, the ordering of
the routines is B<undefined>.

C<test> may also be given a different name for the installed method and the
test description.  This isn't usually needed, but can make things clearer when
referring to tests as methods:

  test $NAME_OF_TEST_METHOD => { description => $TEST_DESCRIPTION } => sub {
    ...
  }

Each test will be run by the C<run_test> method.  To add setup or teardown
behavior, advice (method modifiers) may be attached to that method.  For
example, to call an attribute clearer before each test, you could add:

  before run_test => sub {
    my ($self) = @_;

    $self->clear_some_attribute;
  };

=head3 Running Tests

To run tests, you will need to use L<Test::Routine::Util>, which will provide
two functions for running tests: C<run_tests> and C<run_me>.  The former is
given a set of packages to compose and run as tests.  The latter runs the
caller, assuming it to be a test routine.

C<run_tests> can be called in several ways:

  run_tests( $desc, $object );

  run_tests( $desc, \@packages, $arg );

  run_tests( $desc, $package, $arg );  # equivalent to ($desc, [$pkg], $arg)

In the first case, the object is assumed to be a fully formed, testable object.
In other words, you have already created a class that composes test routines
and have built an instance of it.

In the other cases, C<run_tests> will produce an instance for you.  It divides
the given packages into classes and roles.  If more than one class was given,
an exception is thrown.  A new class is created subclassing the given class and
applying the given roles.  If no class was in the list, Moose::Object is used.
The new class's C<new> is called with the given C<$arg> (if any).

The composition mechanism makes it easy to run a test routine without first
writing a class to which to apply it.  This is what makes it possible to write
your test routine in the C<main> package and run it directly from your F<*.t>
file.  The following is a valid, trivial use of Test::Routine:

  use Test::More;
  use Test::Routine;
  use Test::Routine::Util;

  test demo_test => sub { pass("everything is okay") };

  run_tests('our tests', 'main');
  done_testing;

In this circumstance, though, you'd probably use C<run_me>, which runs the
tests in the caller.  You'd just replace the C<run_tests> line with
C<< run_me; >>.  A description for the run may be supplied, if you like.

Each call to C<run_me> or C<run_tests> generates a new instance, and you can
call them as many times, with as many different arguments, as you like.  Since
Test::Routine can't know how many times you'll call different test routines,
you are responsible for calling C<L<done_testing|Test::More/done_testing>> when
you're done testing.

=head4 Running individual tests

If you only want to run a subset of the tests, you can set the
C<TEST_METHOD> environment variable to a regular expression that matches
the names of the tests you want to run.

For example, to run just the test named C<customer profile> in the
C<MyTests> class.

  use Test::More;
  use Test::Routine::Util;

  $ENV{TEST_METHOD} = 'customer profile';
  run_tests('one test', 'MyTests');
  done_testing;

To run all tests with C<customer> in the name:

  use Test::More;
  use Test::Routine::Util;

  $ENV{TEST_METHOD}= '.*customer.*';
  run_tests('some tests', 'MyTests');
  done_testing;

If you specify an invalid regular expression, your tests will not be
run:

  use Test::More;
  use Test::Routine::Util

  $ENV{TEST_METHOD} = 'C++'
  run_tests('invalid', 'MyTests');
  done_testing;

When you run it:

      1..0
      # No tests run!
  not ok 1 - No tests run for subtest "invalid"

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl released
in the last two to three years.  (That is, if the most recently released
version is v5.40, then this module should work on both v5.40 and v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 AUTHOR

Ricardo Signes <cpan@semiotic.systems>

=head1 CONTRIBUTORS

=for stopwords Alex White Dagfinn Ilmari Mannsåker gregor herrmann Jesse Luehrs Ricardo Signes Yanick Champoux

=over 4

=item *

Alex White <VVu@geekfarm.org>

=item *

Dagfinn Ilmari Mannsåker <ilmari@ilmari.org>

=item *

gregor herrmann <gregoa@debian.org>

=item *

Jesse Luehrs <doy@tozt.net>

=item *

Ricardo Signes <rjbs@cpan.org>

=item *

Ricardo Signes <rjbs@semiotic.systems>

=item *

Yanick Champoux <yanick@babyl.dyndns.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
