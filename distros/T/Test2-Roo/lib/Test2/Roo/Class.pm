use 5.008001;
use strictures;

package Test2::Roo::Class;
# ABSTRACT: Base class for Test2::Roo test classes

our $VERSION = '1.005';

use Moo;
use MooX::Types::MooseLike::Base qw/Str/;
use Test2::API qw( context run_subtest );

#--------------------------------------------------------------------------#
# attributes
#--------------------------------------------------------------------------#

#pod =attr description
#pod
#pod A description for a subtest block wrapping all tests by the object.  It is a
#pod 'lazy' attribute.  Test classes may implement their own C<_build_description>
#pod method to create a description from object attributes.  Otherwise, the default
#pod is "testing with CLASS".
#pod
#pod =cut

has description => (
    is      => 'rw',
    isa     => Str,
    lazy    => 1,
    builder => 1,
);

sub _build_description {
    my $class = ref $_[0];
    return "testing with $class";
}

#--------------------------------------------------------------------------#
# class or object methods
#--------------------------------------------------------------------------#

#pod =method run_tests
#pod
#pod     # as a class method
#pod     $class->run_tests();
#pod     $class->run_tests($description);
#pod     $class->run_tests($init_args);
#pod     $class->run_tests($description $init_args);
#pod
#pod     # as an object method
#pod     $self->run_tests();
#pod     $self->run_tests($description);
#pod
#pod If called as a class method, this creates a test object using an optional hash
#pod reference of initialization arguments.
#pod
#pod When called as an object method, or after an object has been generated, this
#pod method sets an optional description and runs tests.  It will call the C<setup>
#pod method (triggering any method modifiers), will run all tests (triggering any
#pod method modifiers on C<each_test>) and will call the C<teardown> method
#pod (triggering any method modifiers).
#pod
#pod If a description is provided, it will override any initialized or generated
#pod C<description> attribute.
#pod
#pod The setup, tests and teardown will be executed in a L<Test2::Tools::Subtest/subtest_buffered> block.
#pod
#pod =cut

sub run_tests {
    my $self = shift;
    # get hashref from end of args
    # if any args are left, it must be description
    my ( $desc, $args );
    $args = pop if @_ && ref $_[-1] eq 'HASH';
    $desc = shift;

    # create an object if needed and possibly update description
    $self = $self->new( $args || {} )
      if !ref $self;
    $self->description($desc)
      if defined $desc;

    # execute tests wrapped in a subtest
    my $ctx = context();
    my $pass = run_subtest( $self->description, sub {
        $self->setup;
        $self->_do_tests;
        $self->teardown;
    }, { buffered => 1, inherit_trace => 1 } );
   $ctx->release;
   return $pass;
}

#--------------------------------------------------------------------------#
# private methods and stubs
#--------------------------------------------------------------------------#

#pod =method setup
#pod
#pod This is an empty method used to anchor method modifiers.  It should not
#pod be overridden by subclasses.
#pod
#pod =cut

sub setup { }

#pod =method each_test
#pod
#pod This method wraps the code references set by the C<test> function
#pod from L<Test2::Roo> or L<Test2::Roo::Role> in a L<Test2::Tools::Subtest/subtest_buffered> block.
#pod
#pod It may also be used to anchor modifiers that should run before or after
#pod each test block, though this can lead to brittle design as modifiers
#pod will globally affect every test block, including composed ones.
#pod
#pod =cut

sub each_test {
    my ( $self, $code ) = @_;
    $code->($self);
}

#pod =method teardown
#pod
#pod This is an empty method used to anchor method modifiers.  It should not
#pod be overridden by subclasses.
#pod
#pod =cut

sub teardown { }

# anchor for tests as method modifiers
sub _do_tests { }

1;


# vim: ts=4 sts=4 sw=4 et:

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Roo::Class - Base class for Test2::Roo test classes

=head1 VERSION

version 1.005

=head1 DESCRIPTION

This module is the base class for L<Test2::Roo> test classes.  It provides
methods to run tests and anchor modifiers.  Generally, you should not extend
this class yourself, but use L<Test2::Roo> to do so instead.

=head1 ATTRIBUTES

=head2 description

A description for a subtest block wrapping all tests by the object.  It is a
'lazy' attribute.  Test classes may implement their own C<_build_description>
method to create a description from object attributes.  Otherwise, the default
is "testing with CLASS".

=head1 METHODS

=head2 run_tests

    # as a class method
    $class->run_tests();
    $class->run_tests($description);
    $class->run_tests($init_args);
    $class->run_tests($description $init_args);

    # as an object method
    $self->run_tests();
    $self->run_tests($description);

If called as a class method, this creates a test object using an optional hash
reference of initialization arguments.

When called as an object method, or after an object has been generated, this
method sets an optional description and runs tests.  It will call the C<setup>
method (triggering any method modifiers), will run all tests (triggering any
method modifiers on C<each_test>) and will call the C<teardown> method
(triggering any method modifiers).

If a description is provided, it will override any initialized or generated
C<description> attribute.

The setup, tests and teardown will be executed in a L<Test2::Tools::Subtest/subtest_buffered> block.

=head2 setup

This is an empty method used to anchor method modifiers.  It should not
be overridden by subclasses.

=head2 each_test

This method wraps the code references set by the C<test> function
from L<Test2::Roo> or L<Test2::Roo::Role> in a L<Test2::Tools::Subtest/subtest_buffered> block.

It may also be used to anchor modifiers that should run before or after
each test block, though this can lead to brittle design as modifiers
will globally affect every test block, including composed ones.

=head2 teardown

This is an empty method used to anchor method modifiers.  It should not
be overridden by subclasses.

=for Pod::Coverage each_test setup teardown

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by David Golden, Diab Jerius (Smithsonian Astrophysical Observatory).

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
