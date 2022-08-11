package X::Tiny;

use strict;
use warnings;

our $VERSION = '0.22';

=encoding utf-8

=head1 NAME

X::Tiny - Base class for a bare-bones exception factory

=head1 SYNOPSIS

    package My::Module::X;

    use parent qw( X::Tiny );

    #----------------------------------------------------------------------

    package My::Module::X::Base;

    use parent qw( X::Tiny::Base );

    #----------------------------------------------------------------------

    package My::Module::X::IO;

    use parent qw( My::Module::X::Base );

    #----------------------------------------------------------------------

    package My::Module::X::Blah;

    use parent qw( My::Module::X::Base );

    sub _new {
        my ($class, @args) = @_;

        my $self = $class->SUPER::_new('Blah blah', @args);

        return bless $self, $class;
    }

    #----------------------------------------------------------------------

    package main;

    local $@;   #always!
    eval {
        die My::Module::X->create('IO', 'The message', key1 => val1, … );
    };

    if ( my $err = $@ ) {
        print $err->get('key1');
    }

    die My::Module::X->create('Blah', key1 => val1, … );

=head1 DESCRIPTION

This stripped-down exception framework provides a baseline
of functionality for distributions that want to expose exception
hierarchies with minimal fuss. It’s a pattern that I implemented in some
other distributions I created and didn’t want to copy/paste around.

=head1 BENEFITS OF EXCEPTIONS

Exceptions are better for error reporting in Perl than the
C-style “return in failure” pattern. In brief,
you should use exceptions because they are a logical, natural way to report
failures: if you’re given a set of instructions, and something goes wrong
in one of those instructions, it makes sense to stop and go back to see what
to do in response to the problem.

Perl’s built-ins unwisely make the caller responsible for error checking—as
a result of which much Perl code fails to check for failures from those
built-ins, which makes for far more difficult debugging when some code down
the line just mysteriously produces an unexpected result.
The more sensible pattern is for an exception to be thrown at the spot where
the error occurred.

Perl’s default exceptions are just scalars. A more useful pattern is to throw
exception objects whose type and attributes can facilitate meaningful
error checking; for example, you may not care if a call to C<unlink()> fails
with C<ENOENT>, so you can just ignore that failure. Or, you might care, but
you might prefer just to C<warn()> rather than to stop what you’re doing.

X::Tiny is one of many CPAN modules that facilitates this pattern. What
separates X::Tiny from other such modules is its light weight: the only
“heavy” dependency is L<overload>, which is (in my experience) a reasonable
trade-off for the helpfulness of having stack traces on uncaught exceptions.
(The stack trace is custom logic, much lighter than L<Carp>.)

=head1 FEATURES

=over

=item * Super-lightweight: No exceptions are loaded until they’re needed.

=item * Simple, flexible API

=item * String overload with stack trace

=item * Minimal code necessary

=back

=head1 USAGE

You’ll first create a factory class that subclasses C<X::Tiny>.
(In the SYNOPSIS’s example, this module is C<My::Module::X>.) All of your
exceptions B<must> exist under that factory class’s namespace.

You’ll then create a base exception class for your distribution.
In the SYNOPSIS’s example, this module is C<My::Module::X::Base>.
Your distribution’s other exceptions should all subclass this one.

=head1 METHODS

There’s only one method in the factory class:

=head2 I<CLASS>->create( TYPE, ARG1, ARG2, .. )

To create an exception, call the C<create()> method of your factory class.
This will load the exception class if it’s not already in memory.
The TYPE you pass in is equivalent to the exception class’s module name but
with the factory class’s name chopped off the left part. So, if you call:

    My::Module::X->create('BadInput', 'foo', 'bar')

… this will instantiate and return an instance of C<My::Module::X::BadInput>,
with the arguments C<foo> and C<bar>.

=head1 EXCEPTION OBJECTS

See L<X::Tiny::Base> for more information about the features that that
module exposes to subclasses.

=head1 DESIGN CONSIDERATIONS

Admittedly, the lazy-loading behavior here embodies a generally-unwise
practice of doing failure-prone work (i.e., loading a module at runtime)
in the process of reporting a failure.
In my own experience, though, that’s a reasonable tradeoff for the
expressiveness of typed exceptions.

Do be sure that any failure-prone work you do as part of exception
instantiation has its own failure-checking mechanism. There really are not
meant to be “sub-failures” here!

=cut

use strict;
use warnings;

use Module::Runtime ();

sub create {
    my ( $class, $type, @args ) = @_;

    my $x_package = "${class}::$type";

    if (!$x_package->can('new')) {
        Module::Runtime::require_module($x_package);
    }

    return $x_package->new(@args);
}

1;

#----------------------------------------------------------------------

=head1 REPOSITORY

L<https://github.com/FGasper/p5-X-Tiny>

=head1 AUTHOR

Felipe Gasper (FELIPE)

=head1 COPYRIGHT

Copyright 2017-2019 by L<Gasper Software Consulting|http://gaspersoftware.com>

=head1 LICENSE

This distribution is released under the same license as Perl.
