package Xacobeo::UI::Statusbar;

=head1 NAME

Xacobeo::UI::Statusbar - Xacobeo's statusbar

=head1 SYNOPSIS

	use Xacobeo::UI::Statusbar;
	
	my $statusbar = Xacobeo::UI::Statusbar->new();
	$vbox->pack_start($statusbar, FALSE, TRUE, 0);
	
	$statusbar->display("Application started");

=head1 DESCRIPTION

A simple statusbar. This widget is a L<Gtk2::Statusbar>.

=head1 PROPERTIES

The following properties are defined:

=head2 context-id

The context id for the default messages.

=head1 METHODS

The following methods are available:

=head2 new

Creates a new instance. This is simply the parent's constructor.

=cut

use strict;
use warnings;

use Data::Dumper;

use Glib qw(TRUE FALSE);
use Gtk2;

use Xacobeo::GObject;

Xacobeo::GObject->register_package('Gtk2::Statusbar' =>
	properties => [
		Glib::ParamSpec->scalar(
			'context-id',
			"Context ID",
			"The context id for the default status messages",
			['readable', 'writable', 'construct-only'],
		),
	],
);


sub new {
	my $class = shift;

	my $self = $class->SUPER::new();

	my $id = $self->get_context_id('default');
	$self->context_id($id);

	return $self;
}


=head2 display

Display a new message.

Parameters:

=over

=item * $message

The message to display.

=back

=cut

sub display {
	my $self = shift;
	my ($message) = @_;

	my $id = $self->context_id;
	$self->pop($id);
	$self->push($id, $message);
}


=head2 displayf

Display a new message based on a C<sprintf> format.

Parameters:

=over

=item * $format

The format that will generate the message to display.

=item * @args

The arguments to be used by the pattern

=back

=cut

sub displayf {
	my $self = shift;
	my ($format, @args) = @_;
	
	$self->display(sprintf $format, @args);
}


# A true value
1;


=head1 AUTHORS

Emmanuel Rodriguez E<lt>potyl@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008,2009 by Emmanuel Rodriguez.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

