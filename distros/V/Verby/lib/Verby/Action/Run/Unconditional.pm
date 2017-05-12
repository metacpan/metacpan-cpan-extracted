#!/usr/bin/perl

package Verby::Action::Run::Unconditional;
use Moose::Role;

with qw/Verby::Action::Run/;

sub verify {
	my ( $self, $c ) = @_;
	$c->program_finished;
}

__PACKAGE__;

__END__

=pod

=head1 NAME

Verby::Action::Run::Unconditional - A default C<verify> method for
L<Verby::Action::Run> based actions.

=head1 SYNOPSIS

	pakcage MyAction;

	with qw/
		Verby::Action::Run
		Verby::Action::Run::Unconditional
	/;

	sub do {
		my ( $self, $c ) = @_;

		$c->create_poe_session( ... );
	}

	# no need to supply ->verify

=head1 DESCRIPTION

This convenience role makes it easy to write L<Verby::Action::Run> based
actions that return false from C<verify> until they have actually been run, at
which point they return true unconditionally.

=cut


