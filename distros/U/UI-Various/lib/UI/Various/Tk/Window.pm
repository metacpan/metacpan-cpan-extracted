package UI::Various::Tk::Window;

# Author, Copyright and License: see end of file

=head1 NAME

UI::Various::Tk::Window - concrete implementation of L<UI::Various::Window>

=head1 SYNOPSIS

    # This module should never be used directly!
    # It is used indirectly via the following:
    use UI::Various::Window;

=head1 ABSTRACT

This module is the specific implementation of L<UI::Various::Window> using
Perl/Tk.

=head1 DESCRIPTION

The documentation of this module is only intended for developers of the
package itself.

=cut

#########################################################################

use v5.14.0;
use strictures;
no indirect 'fatal';
no multidimensional;
use warnings 'once';

our $VERSION = '0.06';

use UI::Various::core;
use UI::Various::Window;
use UI::Various::Tk::base;

require Exporter;
our @ISA = qw(UI::Various::Window UI::Various::Tk::base);
our @EXPORT_OK = qw();

use Tk;

#########################################################################
#########################################################################

=head1 METHODS

=cut

#########################################################################

=head2 B<_prepare> - prepare UI element

    $ui_element->_prepare;

=head3 description:

Prepare the UI element for L<Tk>.  I<The method should only be called from
C<L<UI::Various::Tk::Main::mainloop|UI::Various::Tk::Main/mainloop>>!>

=head3 returns:

number of errors encountered

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub _prepare($@)
{
    debug(3, __PACKAGE__, '::_prepare');
    my ($self) = @_;
    local $_;

    my @attributes = ();
    # TODO: additional attributes added and translated in loop, when defined
    $self->_tk(	MainWindow->new(-title => $self->title,
				@attributes));

    # We don't use the inherited size (from parent == Main) here, as that
    # would always be the maximum application size!
    if (defined $self->{height}  and  defined $self->{width})
    {
	# Note that width/height attributes apparently are ignored, so we
	# must use the non-attribute Wm method "geometry":
	$self->_tk->geometry
	    (int($self->{width}  * $self->parent->{_char_width}) . 'x' .
	     int($self->{height} * $self->parent->{_char_height}));
    }

    my ($errors, $row) = (0, 0);
    while ($_ = $self->child)
    {
	$errors += $_->_prepare($row++, 0);
    }

    return $errors;
}

#########################################################################

=head2 B<destroy> - remove window from application

C<Tk>'s concrete implementation of
L<UI::Various::Window::destroy|UI::Various::Window/destroy - remove window
from application> directly destroy the window and removes its children.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub destroy($)
{
    debug(2, __PACKAGE__, '::destroy');
    my ($self) = @_;
    local $_ = $self->_tk;	# temporary reference hold till after cleanup
    $self->_cleanup;
    $_  and  $_->destroy;
    $self->_tk(undef);
    $self = undef;
}

1;

#########################################################################
#########################################################################

=head1 SEE ALSO

L<UI::Various>, L<UI::Various::Window>

=head1 LICENSE

Copyright (C) Thomas Dorner.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.  See LICENSE file for more details.

=head1 AUTHOR

Thomas Dorner E<lt>dorner@cpan.orgE<gt>

=cut
