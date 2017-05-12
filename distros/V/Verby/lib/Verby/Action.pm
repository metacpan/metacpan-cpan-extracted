#!/usr/bin/perl

package Verby::Action;
use Moose::Role;

our $VERSION = "0.05";

use Carp qw/longmess/;

requires "do";

requires "verify";

sub confirm {
	my ( $self, $c, @args ) = @_;

	$self->verify($c, @args) or
		$c->logger->log_and_die(level => "error", message => 
			"verification of $self failed: "
			. ($c->error || "error unknown"));
}

__PACKAGE__

__END__

=pod

=head1 NAME

Verby::Action - The base role for an action in Verby.

=head1 SYNOPSIS

	package MyAction;
	use Moose;

	with qw/Verby::Action/;

	sub do { ... }

	sub verify { ... }

=head1 DESCRIPTION

A Verby::Action is an object encapsulating reusable code. Steps usually
delegate to actions, for the actual grunt work.

=head1 METHODS

=over 4

=item B<new>

Instantiate an action. Actions should be able to live indefinitely, and should
not carry internal state with them. All the parameters for C<do> or C<verify>
are provided within the context.

The action instance data should only be used to configure action "flavours",
controlling behavior that should not be parameter sensitive (configuration
data).

=item B<do $cxt>

The thing that the action really does. For example

	package Verby::Action::Download;

	sub do {
		my ($self, $c) = @_;
		system("wget", "-O", $c->file, $c->url);
	}

Will use wget to download C<< $c->url >> to C<< $c->file >>.

This is a bad example though, you ought to subclass L<Verby::Action::Run> if
you want to run a command.

=item B<verify $cxt>

Perform a boolean check - whether or not the action is completed, for a given
set of arguments.

For example, if C<do> downloads C<< $c->file >> from C<< $c->url >>, then the
verify method would look like:

	sub verify {
		my ($self, $c) = @_;
		-f $c->file;
	}

or it could even make a HEAD request and make sure that C<< $c->file >> is up
to date.

=item B<confirm $cxt>

Typically called at the end of an action's do:

	sub do {
		my ($self, $c) = @_;
		...
		$self->confirm($c);
	}

It will call C<< $c->logger->log_and_die >> unless C<verify> returns a true value.

If C<< $c->error >> contains a string then it'll be printed as well.

=back

=head1 ASYNCHRONOUS ACTIONS

Since L<Verby> is an abstraction layer over L<POE> and every step get's it's
own L<POE::Session>, an actions C<do> method can create child sessions, and the
parent session will wait till they are completed, as per default POE behavior.

=back

Note that this documentation assumes delegation of step methods to action
methods.

L<Verby::Dispatcher> actually has nothing to do with L<Verby::Action>, it's
just that typically a L<Verby::Step> is just a thin wrapper for
L<Verby::Action>, so the methods roughly correspond.

See L<Verby::Step::Closure> for a trivial way to generate steps given a
L<Verby::Action> subclass.

=head1 BUGS

None that we are aware of. Of course, if you find a bug, let us know, and we
will be sure to fix it. 

=head1 CODE COVERAGE

We use B<Devel::Cover> to test the code coverage of the tests, please refer to COVERAGE section of the L<Verby> module for more information.

=head1 SEE ALSO

=head1 AUTHOR

Yuval Kogman, E<lt>nothingmuch@woobling.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005-2008 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
