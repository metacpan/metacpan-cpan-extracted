package UI::Various::Tk::Dialog;

# Author, Copyright and License: see end of file

=head1 NAME

UI::Various::Tk::Dialog - concrete implementation of L<UI::Various::Dialog>

=head1 SYNOPSIS

    # This module should never be used directly!
    # It is used indirectly via the following:
    use UI::Various::Dialog;

=head1 ABSTRACT

This module is the specific implementation of L<UI::Various::Dialog> using
Perl/Tk.

=head1 DESCRIPTION

The documentation of this module is only intended for developers of the
package itself.

=cut

#########################################################################

use v5.14;
use strictures;
no indirect 'fatal';
no multidimensional;
use warnings 'once';

our $VERSION = '1.00';

use UI::Various::core;
use UI::Various::Dialog;
use UI::Various::Tk::base;

require Exporter;
our @ISA = qw(UI::Various::Dialog UI::Various::Tk::base);
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

    my @attributes = ($self->_attributes());
    my $first = $self->top->child(0);
    if ($first->isa('UI::Various::Window')  and  defined $first->_tk)
    {
	$self->_tk($first->_tk->Toplevel(-title => $self->title,
					 @attributes));
    }
    else
    {
	# Note that grab will not work with MainWindow!
	$self->_tk(MainWindow->new(-title => $self->title,
				   @attributes));
    }

    # We don't use the inherited size (from parent == Main) here, as that
    # would always be the maximum application size!
    if (defined $self->{height}  and  defined $self->{width})
    {
	# Note that width/height attributes apparently are ignored, so we
	# must use the non-attribute Wm method "geometry":
	$self->_tk->geometry
	    (int($self->{width}  * $self->parent->{_char_avg_width}) . 'x' .
	     int($self->{height} * $self->parent->{_char_height}));
    }

    # a general dialogue is simply a window with a local grab:
    $self->_tk->focus;
    $self->_tk->grab;

    my ($errors, $row) = (0, 0);
    while ($_ = $self->child)
    {
	$errors += $_->_prepare($row++, 0);
    }

    return $errors;
}

#########################################################################

=head2 B<destroy> - remove dialogue from application

C<Tk>'s concrete implementation of
L<UI::Various::Dialog::destroy|UI::Various::Dialog/destroy - remove dialogue
from application> directly destroy the dialogue and removes its children.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub destroy($)
{
    debug(2, __PACKAGE__, '::destroy');
    my ($self) = @_;
    local $_ = $self->_tk;	# temporary reference hold till after cleanup
    $_  and  $_->grabRelease;
    $self->_cleanup;
    $_  and  $_->destroy;
    $self->_tk(undef);
    $self = undef;
}

#########################################################################

=head2 B<_draw> - show dialogue

C<Tk>'s concrete implementation of
L<UI::Various::Dialog::draw|UI::Various::Dialog/draw - show dialogue>

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub _draw($)
{
    debug(2, __PACKAGE__, '::_draw');
    my ($self) = @_;

    if ($self->top->{_running}  and  not $self->_tk)
    {
	$self->_prepare;
    }
}

1;

#########################################################################
#########################################################################

=head1 SEE ALSO

L<UI::Various>, L<UI::Various::Dialog>

=head1 LICENSE

Copyright (C) Thomas Dorner.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.  See LICENSE file for more details.

=head1 AUTHOR

Thomas Dorner E<lt>dorner (at) cpan (dot) orgE<gt>

=cut
