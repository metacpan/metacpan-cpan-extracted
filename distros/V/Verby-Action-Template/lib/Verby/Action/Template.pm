#!/usr/bin/perl

package Verby::Action::Template;
use Moose;

with qw/Verby::Action/;

our $VERSION = "0.04";

use Template;
use Template::Constants qw( :debug );

has template_options => (
	isa => "HashRef",
	is  => "rw",
	auto_deref => 1,
	default    => sub { return {
		ABSOLUTE => 1,
		DEBUG    => DEBUG_UNDEF,
	}},
);

has template_object => (
	isa => "Object",
	is  => "rw",
	default => sub {
		my $self = shift;
		Template->new( $self->template_options ),
	},
);

sub do {
	my ( $self, $c ) = @_;

	my $output   = $c->output;
	my $template = $c->template;

	$c->logger->info("templating '$template' into $output");

	my $t = $self->template_object;

	$t->process($template, $self->template_vars($c), $output)
		|| $c->logger->logdie("couldn't process template: " . $t->error);
}

sub template_vars {
	my ( $self, $c ) = @_;
	return { c => $c };
}

sub verify {
	my ( $self, $c ) = @_;

	my $output = $c->output;

	(defined($output) and not ref($output))
		? -e $output
		: undef;
}

__PACKAGE__

__END__

=pod

=head1 NAME

Verby::Action::Template - Action to process Template Toolkit files

=head1 SYNOPSIS

	use Verby::Action::Template;

=head1 DESCRIPTION

This Action, given a set of template data, will process Template Toolkit files
and return their output.

=head1 METHODS 

=over 4

=item B<do>

Run the template.

=item B<template_vars>

Construct the tempalte variables.

=item B<verify>

Returns true if C<< $c->output >> is a plain string a file by that name exists.

=back

=head1 FIELDS

=over 4

=item B<template_options>

A hash reference containing the default options for the TT constructor. Has
DEBUG_UNDEF enabled, and ABSOLUTE set to true.

=item B<template_object>

A lazy field, whose default value is defined as
C<< Template->new( $self->template_options ) >>.

=back

=head1 BUGS

None that we are aware of. Of course, if you find a bug, let us know, and we will be sure to fix it. 

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
