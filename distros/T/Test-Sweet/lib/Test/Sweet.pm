package Test::Sweet;
BEGIN {
  $Test::Sweet::VERSION = '0.03';
}
# ABSTRACT: Moose-based Test::Class replacement
our $VERSION;

use Moose ();
use Moose::Exporter;
use Moose::Util::MetaRole;

use Test::Sweet::Meta::Class;
use Test::Sweet::Meta::Method;

use Devel::Declare;
use Test::Sweet::Keyword::Test;

Moose::Exporter->setup_import_methods();

sub init_meta {
    my ($me, %options) = @_;
    my $for = $options{for_class};

    # work on both roles and classes
    my $meta;
    if ($for->can('meta')) {
        $meta = $for->meta;
    } else {
        # XXX: should Moose::Role be hard-coded here?
        $meta = Moose::Role->init_meta(for_class => $for);
    }

    setup_sugar_for($for);
    load_extra_modules_into($for) unless $options{no_extra_modules};

    Moose::Util::MetaRole::apply_metaroles(
        for             => $for,
        class_metaroles => { class => ['Test::Sweet::Meta::Class'] },
        role_metaroles  => { role  => ['Test::Sweet::Meta::Class'] },
    );

    if($meta->isa('Class::MOP::Class')){
        # don't apply the object metaroles to roles; only to classes
        Moose::Util::MetaRole::apply_base_class_roles(
            for   => $for,
            roles => ['Test::Sweet::Runnable'],
        );
    }
}

sub setup_sugar_for {
    my $pkg = shift;
    Test::Sweet::Keyword::Test->install_methodhandler(
        into => $pkg,
    );
}

sub load_extra_modules_into {
    my $pkg = shift;
    eval "package $pkg; use Test::More; use Test::Exception";
}

1;


=pod

=head1 NAME

Test::Sweet - Moose-based Test::Class replacement

=head1 VERSION

version 0.03

=head1 SYNOPSIS

Write test classes:

   use MooseX::Declare;
   class t::RecordBasic with t::lib::FakeDatabase {
       use Test::Sweet;

       test add_record {
           $self->database->insert( 42 => 'OH HAI' );
           ok $self->database->get_record('42'), 'can get record 42';
       }

       test delete_record {
           ok $self->database->exists('42'), 'still have record 42';
           lives_ok {
               $self->database->delete('42')
           } 'deleting 42 lives';
           ok !$self->database->exists('42'), 'record 42 is gone';
       }
   }

Run them:

   $ mx-run -Ilib t::RecordBasic

And get the valid TAP output:

   1..2
     ok 1 - can get record 42
     1..1
   ok 1 - subtest add_record
     ok 1 - still have record 42
     ok 2 - deleting 42 lives
     ok 3 - record 42 is gone
     1..3
   ok 2 - subtest delete_record

No more counting tests; this module does it for you and ensures that
you are protected against premature death.  (Well, your test suite,
anyway.)

You can also have command-line args for your tests; they are parsed
with L<MooseX::Getopt|MooseX::Getopt> (if you have it installed; try
"mx-run t::YourTest --help").

=head1 DESCRIPTION

C<Test::Sweet> lets you organize tests into Moose classes and Moose
roles.  You just need to create a normal class or role and say C<use
Test::Sweet> somewhere.  This adds the necessary methods to your
metaclass, makes your class do C<Test::Sweet::Runnable> (so that you
can run it with L<MooseX::Runnable|MooseX::Runnable>'s
L<mx-run|mx-run> command), and makes the C<test> keyword available for
your use.  (The imports are package-scoped, of course, but the C<test>
keyword is lexically scoped.)

Normal methods are defined normally.  Methods that run tests are
defined like methods, but with the C<test> keyword instead of C<sub>
or C<method>.  In the test methods, you can use any
L<Test::Builder|Test::Builder>-aware test methods.  You get all of
L<Test::More|Test::More> and L<Test::Exception|Test::Exception> by
default.

Tests can be called as methods any time the test suite is running,
including in BUILD and DEMOLISH.  Everything will Just Work.  The
method will get the arguments you pass, you will get the return value,
and this module will do what's necessary to ensure that Test::Builder
knows what is going on.  It's a Moose class and tests are just special
methods.  Method modifiers work too.  (But don't run tests directly in
the method modifier body yet; just call other C<test> methods.)

To run all tests in a class (hierarchy), just call the C<run> method.

Tests are ordered as follows.  All test method from the superclasses
are run first, then your tests are run in the order they appear in the
file (this is guaranteed, not a side-effect of anything), then any
tests you composed in from roles are run.  If anything in the
hierarchy overrides a test method from somewhere else in the
hierarchy, the overriding method will be run when the original method
would be.

Here's an example:

  class A { use Test::Sweet; test first { pass 'first' } };
  class B extends A { use Test::Sweet; test second { pass 'second' } };

When you call C<< A->run >>, "first" will be run.

When you call C<< B->run >>, "first" will run, then "second" will run.

If you change B to look like:

  class B extends A {
      test second { pass 'second' }
      test first  { pass 'blah'   }
  }

When you run C<< B->run >>, first will be called first but will print
"blah", and second will be called second.  (If you remove the "extends
A", they will run in the order they appear in B, of course; second
then first.)

=head2 METATEST CLASSES AND TRAITS

With this, you can inherit tests from classes or roles, but you can't
inherit parts of tests.  For example, you may want many tests that
will not kill the test suite if they die, but they will fail a subtest
in that case.  With Test traits, you can implement this behavior
reusably; as a CPAN module, as a role in your application, or as a
role defined inside the test.

The first thing you need to do is to create a meta-test trait.  This
is a role that is applied to the metatest class, which is what
actually runs each test.  This class has "run" method which runs the
code you typed into the test file.  Metatest traits modify this method
(but can have other methods and attributes).

Here is the role that implements the metatest trait that will add a
subtest that passes if the body lives, or fails if the body dies:

   role Test::Sweet::Meta::Test::Trait::TestLives {
       use Test::More;

       around run(@args){
           my $lived = 0;
           eval {
               $self->$orig(@args);
               $lived = 1;
           };
           ok $lived, 'test lived ok';
       }
   }

(Note that the C<Test::Sweet::Meta::Test::Trait::> namespace is the
default place for these traits.  You can use any namespace you like,
however; you just need to prefix the name of the trait with a C<+>
when you use something other than this default.)

Now you can use this to modify tests:

    class t::Whatever {
        use Test::Sweet;

        test perhaps_it_lives (TestLives) {
            ok 1, 'got here';
            rand > 0.5 and die 'OH NOES';
        }
    }

You can also use these roles to provide per-test setup and teardown
(per-test-class setup and teardown is just BUILD and DEMOLISH).
Here's an example test that logs a message when a test starts and when
it finishes:

    role Log with MooseX::LogDispatch {
        method BUILD    { $self->logger->info('Test starting') }
        method DEMOLISH { $self->logger->info('Test ending')   }
    }

Now tests that use this metatest trait:

    test foo (+Log) {
        ...
    }

will print a log message when the test starts and when it ends.  (You
can actually do this with C<around run> too.)

The test metainstance is always available inside your test as
C<$test>:

    test foo (+Log) {
        $test->logger->info('Inside the test.');
    }

(You also get C<$self> inside tests, if you didn't notice that
already.  C<$self> is the test class instance, C<$test> is the
metatest object, and C<< $self->meta >> is the test metaclass.  So
much meta...)

Finally, the examples above only used one trait per test, but you can
apply as many as you want:

    test foo (+Foo, Bar, Baz, +Quux, OH::Hai) {
        ...
    }

=head1 REPOSITORY

L<http://github.com/jrockway/test-sweet>

Patches (or pull requests) are very welcome.  You should also discuss
this module on the moose irc channel at L<irc://irc.perl.org/#moose>;
nothing is set in stone yet, and your feedback is requested.

=head1 TODO

Convince C<prove> to run the <.pm> files directly.

Write code to organize classes into test suites; and run the test
suites easily.  (Classes and tests should be tagged, so you can run
C<run-test-suite t::Suite --no-slow-tests> or something.)

More testing.  There are undoubtedly corner cases that are
undiscovered and unhandled.

Document the full meta-protocol.  For now, look at the C<t::Traits>
test.

Syntax sugar for creating traits and attributes on those traits.

=head1 SEE ALSO

L<http://github.com/jrockway/test-sweet-dbic> shows what sort of
reusability you can get with C<Test::Sweet>... with 5 minutes of
hacking.

Read this module's test suite (in the C<t/> directory) for example of
how to make C<prove> understand C<Test::Sweet> classes.

=head1 AUTHOR

Jonathan Rockway C<< <jrockway@cpan.org> >>

=head1 COPYRIGHT

Copyright (c) 2009 Jonathan Rockway.

This module is free software, you may redistribute it under the same
terms as Perl itself.

=head1 AUTHOR

Jonathan Rockway <jrockway@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Rockway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

