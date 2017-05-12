#!/usr/bin/perl

package Verby::Step;
use Moose::Role;

our $VERSION = "0.05";

requires "do";

requires "depends";

requires "is_satisfied";

sub provides_cxt {
	return undef;
}

sub resources {
	return ( steps => 1 );
}

__PACKAGE__

__END__

=pod

=head1 NAME

Verby::Step - A base class representing a single thing to be executed by
L<Verby::Dispatcher>.

=head1 SYNOPSIS

	package MyStep;
	use Moose;

	with qw/Verby::Step/;

Or perhaps more easily using:

	use Verby::Step::Closure qw/step/;
	my $step = step "Some::Action",
		sub { warn "before" },
		sub { warn "after" };

=head1 DESCRIPTION

A step in the L<Verby> system is like an instance of an action.

A step is much like a makefile target. It can depend on other steps, and when
appropriate will be told to be executed.

The difference between a L<Verby::Step> and a L<Verby::Action> is that an
action is usually just reusable code to implement the verification and
execution

A step manages the invocation of an action, typically by massaging the context
before delegating, and re-exporting meaningful data to the parent context when
finished. It also tells the system when to execute, by specifying dependencies.

The distinction is that an action is something you do, and a step is something
you do before and after others.

=head1 METHODS

This role provides the C<provides_cxt> and C<resources> methods, with sane
default values, and requires C<depends>, C<is_satisfied> and C<do>. See
L<Verby::Step::Simple> and L<Verby::Step::Closure> for more reusable behavior.

=over 4

=item B<depends>

Subclass this to return a list of other steps to depend on.

=item B<is_satisfied>

This method should return a true value if the step does not need to be
executed.

Typically a delegation to L<Verby::Action/verify>. They are named differently,
because C<is_satisfied> implies state. The L<Verby::Dispatcher> will sometimes
make assumptions, without asking the step to check that it is satisfied.

=item B<provides_cxt>

=item B<do>

This is basically a delegation to the corresponding L<Verby::Action> method.

The only interesting thing to do here is to fudge the context up a bit. For
example, if your action assumes the C<path> key to be in the context, but you
chose C<the_path_to_the_thing> to be in your config, this is the place to do:

	sub do {
		my ($self, $c) = @_;

		# prepare for the action
		$c->path($c->the_path_to_the_thing);

		$self->action->do($c);

		# pass data from the action to the next steps
		$c->export("some_key_the_action_set");
	}

L<Verby::Step::Closure> provides a convenient way to get this behavior for
free.

=item B<resources>

Returns the list of required resources to allocate with the dispatcher's
resource pool, if provided.

This defaults to the resource C<steps> with the value C<1>, generally intended
to control the maximum number of concurrent jobs.

=back

=head1 BUGS

None that we are aware of. Of course, if you find a bug, let us know, and we
will be sure to fix it. 

=head1 CODE COVERAGE

We use B<Devel::Cover> to test the code coverage of the tests, please refer to
COVERAGE section of the L<Verby> module for more information.

=head1 SEE ALSO

=head1 AUTHOR

Yuval Kogman, E<lt>nothingmuch@woobling.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005-2008 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
