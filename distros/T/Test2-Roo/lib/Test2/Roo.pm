use 5.008001;
use strictures;

package Test2::Roo;
# ABSTRACT: Composable, reusable tests with roles and Moo

our $VERSION = '1.005';

use Test2::API qw( context run_subtest );
use Sub::Install;

sub import {
    my ( $class, @args ) = @_;
    my $caller = caller;
    for my $sub (qw/test top_test run_me/) {
        Sub::Install::install_sub( { into => $caller, code => $sub } );
    }
    strictures->import; # do this for Moo, since we load Moo in eval
    eval qq{
        package $caller;
        use Moo;
        extends 'Test2::Roo::Class'
    };
    die $@ if $@;
    if (@args) {
        eval qq{ package $caller; use Test2::V0 \@args };
    }
    else {
        eval qq{ package $caller; use Test2::V0 };
    }
    die $@ if $@;
}

sub test {
    my ( $name, $code ) = @_;
    my $caller  = caller;
    my $subtest = sub {
        my $self = shift;
        my $ctx = context();
        my $pass = run_subtest( $name, sub { $self->each_test($code) }, { buffered => 1, inherit_trace => 1 } );
        $ctx->release;
        return $pass;
    };
    eval qq{ package $caller; after _do_tests => \$subtest };
    die $@ if $@;
}

sub top_test {
    my ( $name, $code ) = @_;
    my $caller = caller;
    my $test = sub { shift->each_test($code) };
    eval qq{ package $caller; after _do_tests => \$test };
    die $@ if $@;
}

sub run_me {
    my $class = caller;
    $class->run_tests(@_);
}

1;


# vim: ts=4 sts=4 sw=4 et:

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Roo - Composable, reusable tests with roles and Moo

=head1 VERSION

version 1.005

=head1 SYNOPSIS

Define test behaviors and required fixtures in a role:

    # t/lib/ObjectCreation.pm

    package ObjectCreation;
    use Test2::Roo::Role;    # loads Moo::Role and Test2::V0

    requires 'class';       # we need this fixture

    test 'object creation' => sub {
        my $self = shift;
        require_ok( $self->class );
        my $obj  = new_ok( $self->class );
    };

    1;

Provide fixtures and run tests from the .t file:

    # t/test.t

    use Test2::Roo; # loads Moo and Test2::V0
    use lib 't/lib';

    # provide the fixture
    has class => (
        is      => 'ro',
        default => sub { "Digest::MD5" },
    );

    # specify behaviors to test
    with 'ObjectCreation';

    # give our subtests a pretty label
    sub _build_description { "Testing " . shift->class }

    # run the test with default fixture
    run_me;

    # run the test with different fixture
    run_me( { class => "Digest::SHA1" } );

    done_testing;

Result:

    $ prove -lv t
    t/test.t ..
            ok 1 - require Digest::MD5;
            ok 2 - The object isa Digest::MD5
            1..2
        ok 1 - object creation
        1..1
    ok 1 - Testing Digest::MD5
            ok 1 - require Digest::SHA1;
            ok 2 - The object isa Digest::SHA1
            1..2
        ok 1 - object creation
        1..1
    ok 2 - Testing Digest::SHA1
    1..2
    ok
    All tests successful.
    Files=1, Tests=2,  0 wallclock secs ( 0.02 usr  0.01 sys +  0.06 cusr  0.00 csys =  0.09 CPU)
    Result: PASS

=head1 DESCRIPTION

This module allows you to compose L<Test2::V0> tests from roles.  It is
inspired by the excellent L<Test::Routine> module, but uses L<Moo> instead of
L<Moose>.  This gives most of the benefits without the need for L<Moose> as a
test dependency.

Test files are Moo classes.  You can define any needed test fixtures as Moo
attributes.  You define tests as method modifiers -- similar in concept to
C<subtest> in L<Test2::V0>, but your test method will be passed the test
object for access to fixture attributes.  You may compose any L<Moo::Role> into
your test to define attributes, require particular methods, or define tests.

This means that you can isolate test I<behaviors> into roles which require
certain test I<fixtures> in order to run.  Your main test file will provide the
fixtures and compose the roles to run.  This makes it easy to reuse test
behaviors.

For example, if you are creating tests for Awesome::Module, you could create
the test behaviors as Awesome::Module::Test::Role and distribute it with
your module.  If another distribution subclasses Awesome::Module, it can
compose the Awesome::Module::Test::Role behavior for its own tests.

No more copying and pasting tests from a super class!  Superclasses define and
share their tests.  Subclasses provide their own fixtures and run the tests.

=head1 USAGE

Importing L<Test2::Roo> also loads L<Moo> (which gives you L<strictures> with
fatal warnings and other goodies) and makes the current package a subclass
of L<Test2::Roo::Class>.

Importing also loads L<Test2::V0>.  No test plan is used.  The C<done_testing>
function must be used at the end of every test file.  Any import arguments are
passed through to L<Test2::V0>'s C<import> method.

See also L<Test2::Roo::Role> for test role usage.

=head2 Creating fixtures

You can create fixtures with normal Moo syntax.  You can even make them lazy if
you want:

    has fixture => (
        is => 'lazy'
    );

    sub _build_fixture { ... }

This becomes really useful with L<Test2::Roo::Role>.  A role could define the
attribute and require the builder method to be provided by the main test class.

=head2 Composing test roles

You can use roles to define units of test behavior and then compose them into
your test class using the C<with> function.  Test roles may define attributes,
declare tests, require certain methods and anything else you can regularly do
with roles.

    use Test2::Roo;

    with 'MyTestRole1', 'MyTestRole2';

See L<Test2::Roo::Role> and the L<Test2::Roo::Cookbook> for details and
examples.

=head2 Setup and teardown

You can add method modifiers around the C<setup> and C<teardown> methods and
these will be run before tests begin and after tests finish (respectively).

    before  setup     => sub { ... };

    after   teardown  => sub { ... };

You can also add method modifiers around C<each_test>, which will be
run before and after B<every> individual test.  You could use these to
prepare or reset a fixture.

    has fixture => ( is => 'lazy, clearer => 1, predicate => 1 );

    after  each_test => sub { shift->clear_fixture };

Roles may also modify C<setup>, C<teardown>, and C<each_test>, so the order
that modifiers will be called will depend on when roles are composed.  Be
careful with C<each_test>, though, because the global effect may make
composition more fragile.

You can call test functions in modifiers. For example, you could
confirm that something has been set up or cleaned up.

    before each_test => sub { ok( ! shift->has_fixture ) };

=head2 Running tests

The simplest way to use L<Test2::Roo> with a single F<.t> file is to let the
C<main> package be the test class and call C<run_me> in it:

    # t/test.t
    use Test2::Roo; # loads Moo and Test2::V0

    has class => (
        is      => 'ro',
        default => sub { "Digest::MD5" },
    );

    test 'load class' => sub {
        my $self = shift;
        require_ok( $self->class );
    }

    run_me;
    done_testing;

Calling C<< run_me(@args) >> is equivalent to calling
C<< __PACKAGE__->run_tests(@args) >> and runs tests for the current package.

You may specify an optional description or hash reference of constructor
arguments to customize the test object:

    run_me( "load MD5" );
    run_me( { class => "Digest::MD5" } );
    run_me( "load MD5", { class => "Digest::MD5" } );

See L<Test2::Roo::Class> for more about the C<run_tests> method.

Alternatively, you can create a separate package (in the test file or in a
separate F<.pm> file) and run tests explicitly on that class.

    # t/test.t
    package MyTest;
    use Test2::Roo;

    use lib 't/lib';

    has class => (
        is       => 'ro',
        required => 1,
    );

    with 'MyTestRole';

    package main;
    use strictures;
    use Test2::V0;

    for my $c ( qw/Digest::MD5 Digest::SHA/ ) {
        MyTest->run_tests("Testing $c", { class => $c } );
    }

    done_testing;

=for Pod::Coverage add_methods_here

=head1 EXPORTED FUNCTIONS

Loading L<Test2::Roo> exports subroutines into the calling package to declare
and run tests.

=head2 test

    test $label => sub { ... };

The C<test> function adds a subtest.  The code reference will be called with
the test object as its only argument.

Tests are run in the order declared, so the order of tests from roles will
depend on when they are composed relative to other test declarations.

=head2 top_test

    top_test $label => sub { ... };

The C<top_test> function adds a "top level" test.  Works exactly like L</test>
except it will not start a subtest.  This is especially useful in very simple
testing situations where the extra subtest level is just noise.

So for example the following test

    # t/test.t
    use Test2::Roo;

    has class => (
        is       => 'ro',
        required => 1,
    );

    top_test basic => sub {
        my $self = shift;

        require_ok($self->class);
        isa_ok($self->class->new, $self->class);
    };

    for my $c ( qw/Digest::MD5 Digest::SHA/ ) {
        run_me("Testing $c", { class => $c } );
    }

    done_testing;

produces the following TAP

    t/test.t ..
        ok 1 - require Digest::MD5;
        ok 2 - The object isa Digest::MD5
        1..2
    ok 1 - Testing Digest::MD5
        ok 1 - require Digest::SHA1;
        ok 2 - The object isa Digest::SHA1
        1..2
    ok 2 - Testing Digest::SHA1
    1..2
    ok
    All tests successful.
    Files=1, Tests=2,  0 wallclock secs ( 0.02 usr  0.01 sys +  0.06 cusr  0.00 csys =  0.09 CPU)
    Result: PASS

=head2 run_me

    run_me;
    run_me( $description );
    run_me( $init_args   );
    run_me( $description, $init_args );

The C<run_me> function calls the C<run_tests> method on the current package
and passes all arguments to that method.  It takes a description and/or
a hash reference of constructor arguments.

=head1 DIFFERENCES FROM TEST::ROUTINE

While this module was inspired by L<Test::Routine>, it is not a drop-in
replacement.  Here is an overview of major differences:

=over 4

=item *

L<Test2::Roo> uses L<Moo>; L<Test::Routine> uses L<Moose>

=item *

Loading L<Test2::Roo> makes the importing package a class; in L<Test::Routine> it becomes a role

=item *

Loading L<Test2::Roo> loads L<Test2::V0>; L<Test::Routine> does not

=item *

In L<Test2::Roo>, C<run_test> is a method; in L<Test::Routine> it is a function and takes arguments in a different order

=item *

In L<Test2::Roo>, all role composition must be explicit using C<with>; in L<Test::Routine>, the C<run_tests> command can also compose roles

=item *

In L<Test2::Roo>, test blocks become method modifiers hooked on an empty method; in L<Test::Routine>, they become methods run via introspection

=item *

In L<Test2::Roo>, setup and teardown are done by modifying C<setup> and C<teardown> methods; in L<Test::Routine> they are done by modifying C<run_test>

=back

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://rt.cpan.org/Public/Dist/Display.html?Name=Test2-Roo>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://gitlab.com/djerius/Test2-Roo>

  https://gitlab.com/djerius/Test2-Roo.git

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 CONTRIBUTORS

=for stopwords Arthur Axel 'fREW' Schmidt Diab Jerius

=over 4

=item *

Arthur Axel 'fREW' Schmidt <frioux@gmail.com>

=item *

Diab Jerius <djerius@cfa.harvard.edu>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by David Golden, Diab Jerius (Smithsonian Astrophysical Observatory).

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
