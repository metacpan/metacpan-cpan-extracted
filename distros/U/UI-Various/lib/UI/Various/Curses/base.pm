package UI::Various::Curses::base;

# Author, Copyright and License: see end of file

=head1 NAME

UI::Various::Curses::base - abstract helper class for Curses's UI elements

=head1 SYNOPSIS

    # This module should only be used by the UI::Various::Curses UI
    # element classes!

=head1 ABSTRACT

This module provides some helper functions for the UI elements of the
L<Curses::UI> GUI.

=head1 DESCRIPTION

The documentation of this module is only intended for developers of the
package itself.

All functions of the module will be included as second "base class" (in
C<@ISA>).  Note that this is not a diamond pattern as this "base class" does
not import anything besides C<Exporter>, though it add a common private
attribute to all C<UI::Various::Curses> classes:

=head2 Attributes

=over

=cut

#########################################################################

use v5.14.0;
use strictures;
no indirect 'fatal';
no multidimensional;
use warnings 'once';

our $VERSION = '0.07';

use UI::Various::core;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw();

#########################################################################

=item B<_cui> [rw, optional]

a reference to the main L<Curses::UI> element used for the implementation of
the UI element

Note that usually this should only be used within C<UI::Various::Curses>.

=cut

sub _cui($;$)
{   return access('_cui', undef, @_);   }

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

=item B<_cid> [ro, auto]

a unique ID needed for accessing some L<Curses::UI> methods, most notably
C<delete>

Note that we can't simply use our own object (C<$self>) as L<Curses::UI>
uses the class-name if it encounters an object as ID.

=cut

{
    my $_next_id = 1;
    sub _cid($)
    {
	my ($self) = @_;
	defined $self->{_cid}  or  $self->{_cid} = 'UVC' . $_next_id++;
	return $self->{_cid};
    }
}

#########################################################################
#########################################################################

=back

=head1 METHODS

The module also provides the following common (internal) methods for all
UI::Various::Curses UI element classes:

=cut

#########################################################################

=head2 B<_cleanup> - cleanup UI element

    $ui_element->cleanup;

=head3 description:

This method prepares a UI element for destruction by removing all of the
references it is holding (including its parent reference).  An object will
therefore only survive if it is additionally still referenced outside of
C<L<UI::Various>>, e.g. a variable used to create it in the first place.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub _cleanup($)
{
    my ($self) = @_;

    # We recursively remove our references to L<Curses::UI> objects first in
    # order to ease the internal cleanup for L<Curses::UI> itself.  The
    # later is initiated by explicitly removing each element:
    if ($self->can('remove'))
    {
	local $_;
	while ($_ = $self->child)
	{   $_->_cleanup;   }
    }
    $self->{_cui}  and  delete $self->{_cui};

    local $_ = $self->parent;
    $_->{_cui}  and  $_->{_cui}->delete($self->_cid);
    $_->remove($self);
}

1;

#########################################################################
#########################################################################

=head1 SEE ALSO

L<UI::Various>

=head1 LICENSE

Copyright (C) Thomas Dorner.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.  See LICENSE file for more details.

=head1 AUTHOR

Thomas Dorner E<lt>dorner@cpan.orgE<gt>

=cut
